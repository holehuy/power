<#
    Module dùng chung cho cả 5 Worker (đổi tên từ IpamWorkerCommon.psm1 — nội dung chưa bao giờ
    thực sự riêng cho IPAM): khoá thực thi, retry, tính ngày, tham số ngoài, IP/CIDR helper, ghi
    log. Mọi Worker PHẢI dùng các hàm ở đây thay vì tự cài lại logic tương đương — các quy tắc
    này (đặc biệt Get-ElapsedDaysWithSkipCorrection) là "bản chuẩn" theo thiết kế 6.8-2; cài lại
    riêng ở từng Worker sẽ có nguy cơ lệch công thức giữa các Worker.
#>

Set-StrictMode -Version Latest

# --- Chống chạy đa instance của CHÍNH Worker đó (8.4) ---------------------------------------

function Enter-WorkerLock {
    <#
    .SYNOPSIS
        Lấy lock file cho 1 Worker. Tự động giải phóng lock rác nếu process giữ lock đã chết
        hoặc lock đã hết hạn theo timestamp (ngăn từ chối khởi động vĩnh viễn sau crash — 8.4).
    #>
    param(
        [Parameter(Mandatory)] [string]$WorkerName,
        [string]$LockDirectory = "$PSScriptRoot\..\..\logs\locks",
        [int]$MaxAgeMinutes = 60
    )

    if (-not (Test-Path $LockDirectory)) { New-Item -ItemType Directory -Path $LockDirectory -Force | Out-Null }
    $lockPath = Join-Path $LockDirectory "$WorkerName.lock"

    if (Test-Path $lockPath) {
        $existing = Get-Content $lockPath | ConvertFrom-Json
        $isAlive = Get-Process -Id $existing.ProcessId -ErrorAction SilentlyContinue
        $isExpired = ((Get-Date) - [datetime]$existing.AcquiredAt).TotalMinutes -gt $MaxAgeMinutes
        if ($isAlive -and -not $isExpired) {
            throw "Worker '$WorkerName' đã đang chạy (PID $($existing.ProcessId)). Bỏ qua chu kỳ này (8.4: cho phép thiếu cycle, không thực thi kép)."
        }
        Write-Warning "Phát hiện lock rác của '$WorkerName' (PID $($existing.ProcessId), alive=$([bool]$isAlive), expired=$isExpired) — tự động giải phóng."
    }

    @{ ProcessId = $PID; AcquiredAt = (Get-Date).ToString('o') } | ConvertTo-Json | Set-Content $lockPath
    return $lockPath
}

function Exit-WorkerLock {
    param([Parameter(Mandatory)] [string]$LockPath)
    if (Test-Path $LockPath) { Remove-Item $LockPath -Force }
}

# --- Loại trừ giữa các Worker theo từng entry IPAM (8.4) -------------------------------------

function Enter-IpEntryMutex {
    <#
    .SYNOPSIS
        Named mutex theo địa chỉ IP làm key, để Worker tự động xóa và script phản ánh ARP
        không cập nhật đồng thời cùng một entry IPAM. Timeout ngắn (mặc định 10s) — vượt timeout
        thì SKIP entry đó (an toàn hơn global lock vì không làm nghẽn toàn bộ chu kỳ, 8.4).
    #>
    param(
        [Parameter(Mandatory)] [string]$IpAddress,
        [int]$TimeoutSeconds = 10
    )
    $mutex = New-Object System.Threading.Mutex($false, "Global\IpamEntry_$($IpAddress -replace '\.', '_')")
    if (-not $mutex.WaitOne([TimeSpan]::FromSeconds($TimeoutSeconds))) {
        $mutex.Dispose()
        return $null
    }
    return $mutex
}

function Exit-IpEntryMutex {
    param([System.Threading.Mutex]$Mutex)
    if ($null -ne $Mutex) { $Mutex.ReleaseMutex(); $Mutex.Dispose() }
}

# --- Retry / backoff cho lỗi tạm thời (Graph API, v.v. — 8.4) --------------------------------

function Invoke-WithExponentialBackoff {
    <#
    .SYNOPSIS
        Retry tối đa 3 lần, chờ ban đầu 2 giây, hệ số nhân 2 (2/4/8 giây).
        Đối tượng retry: 429/408/5xx/connection timeout. Ưu tiên header Retry-After nếu có (429).
        KHÔNG tăng RetryCount của SharePoint — đây là retry trong-process, khác với retry-qua-chu-kỳ (7.1).
    #>
    param(
        [Parameter(Mandatory)] [scriptblock]$ScriptBlock,
        [int]$MaxAttempts = 3,
        [int]$InitialDelaySeconds = 2
    )
    $attempt = 0
    $delay = $InitialDelaySeconds
    while ($true) {
        try {
            return & $ScriptBlock
        }
        catch {
            $attempt++
            $isRetryable = $_.Exception.Message -match '429|408|5\d\d|timed out|timeout'
            if (-not $isRetryable -or $attempt -ge $MaxAttempts) { throw }
            Write-Warning "Lỗi tạm thời (lần $attempt/$MaxAttempts): $($_.Exception.Message). Chờ $delay giây rồi retry."
            Start-Sleep -Seconds $delay
            $delay *= 2
        }
    }
}

# --- Tính số ngày đã trôi qua có hiệu chỉnh SkippedDays (bản chuẩn 6.8-2) --------------------

function Get-ElapsedDaysWithSkipCorrection {
    <#
    .SYNOPSIS
        Số ngày đã trôi qua = (ngày hiện tại JST − ngày mốc JST) − SkippedDays của segment tương ứng.
        Dùng chung cho MỌI phán định xóa: AutoDetected 30 ngày, Requested 90/180/365 ngày,
        và hết hạn Cooldown (7.4). KHÔNG áp dụng hiệu chỉnh SkippedDays lặp lại ở bất kỳ nơi gọi nào khác.
    .PARAMETER SkippedDays
        Lấy từ Segments.SkippedDays tại thời điểm snapshot đầu ca quét (7.4) — không query lại giữa chừng.
    #>
    param(
        [Parameter(Mandatory)] [datetime]$FromTimestampUtc,
        [datetime]$AsOfUtc = (Get-Date).ToUniversalTime(),
        [int]$SkippedDays = 0
    )
    $jstOffset = [TimeSpan]::FromHours(9)
    $fromJstDate = ($FromTimestampUtc + $jstOffset).Date
    $asOfJstDate = ($AsOfUtc + $jstOffset).Date
    $rawDays = ($asOfJstDate - $fromJstDate).Days
    return [Math]::Max(0, $rawDays - $SkippedDays)
}

# --- Tham số ngoài (externalize ngưỡng ngày — 8.4) -------------------------------------------

function Get-ExternalThreshold {
    <#
    .SYNOPSIS
        Đọc ngưỡng ngày từ src/config/thresholds.json thay vì hard-code trong Worker.
        Guard: từ chối khởi động nếu giá trị < 7 ngày (bảo vệ, đồng thời cho phép rút ngắn khi test nghiệm thu).
    #>
    param(
        [Parameter(Mandatory)] [string]$ThresholdName,
        [string]$ConfigPath = "$PSScriptRoot\..\config\thresholds.json"
    )
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $value = $config.$ThresholdName
    if ($null -eq $value) { throw "Không tìm thấy threshold '$ThresholdName' trong $ConfigPath" }
    if ($value -lt 7) { throw "Threshold '$ThresholdName' = $value ngày < 7 ngày guard tối thiểu (8.4). Từ chối khởi động." }
    return $value
}

# --- IP / CIDR / dải tĩnh (dùng chung reflect-to-ipam ARP 7.3 + auto-deletion-worker 7.4-3) ---

function ConvertTo-UInt32IpAddress {
    <#
    .SYNOPSIS
        Chuyển 1 địa chỉ IPv4 dạng chuỗi sang uint32 (big-endian) để so sánh/tính bitmask.
    #>
    param([Parameter(Mandatory)] [string]$IpAddress)
    $bytes = [System.Net.IPAddress]::Parse($IpAddress).GetAddressBytes()
    if ($bytes.Length -ne 4) { throw "Chỉ hỗ trợ IPv4: $IpAddress" }
    if ([System.BitConverter]::IsLittleEndian) { [Array]::Reverse($bytes) }
    return [BitConverter]::ToUInt32($bytes, 0)
}

function Test-IpAddressInCidr {
    param(
        [Parameter(Mandatory)] [string]$IpAddress,
        [Parameter(Mandatory)] [string]$Cidr
    )
    $cidrParts = $Cidr -split '/', 2
    if ($cidrParts.Count -ne 2) { throw "CIDR không hợp lệ (thiếu prefix length): $Cidr" }
    $prefixLength = [int]$cidrParts[1]
    if ($prefixLength -eq 0) { return $true }
    $mask = [uint32]([uint32]::MaxValue -shl (32 - $prefixLength))
    $ipValue = ConvertTo-UInt32IpAddress -IpAddress $IpAddress
    $networkValue = ConvertTo-UInt32IpAddress -IpAddress $cidrParts[0]
    return ($ipValue -band $mask) -eq ($networkValue -band $mask)
}

function Test-IpAddressInRange {
    param(
        [Parameter(Mandatory)] [string]$IpAddress,
        [Parameter(Mandatory)] [string]$RangeStart,
        [Parameter(Mandatory)] [string]$RangeEnd
    )
    $ipValue = ConvertTo-UInt32IpAddress -IpAddress $IpAddress
    $startValue = ConvertTo-UInt32IpAddress -IpAddress $RangeStart
    $endValue = ConvertTo-UInt32IpAddress -IpAddress $RangeEnd
    return ($ipValue -ge $startValue) -and ($ipValue -le $endValue)
}

function ConvertFrom-StaticIpRangeRaw {
    <#
    .SYNOPSIS
        Parse Segments.StaticIpRangeRaw (6.3: "bản chính, JSON, hỗ trợ nhiều dải rời rạc").

    QA (đã thêm vào docs/open-questions.md): schema JSON chính xác của cột này CHƯA được đặc tả
    tường minh trong thiết kế gốc — chỉ nói "hỗ trợ nhiều dải rời rạc". Giả định ở đây: mảng các
    object {start,end}, vd '[{"start":"10.11.20.10","end":"10.11.20.200"}]'. Xác nhận với đội
    build segment-sync-worker (nơi SINH ra cột này ở Get-FixedIpRange, 7.2) trước khi build/test
    tích hợp thật với dữ liệu Segments thật.
    #>
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return @() }
    return @($Raw | ConvertFrom-Json)
}

function Test-IpAddressInStaticRange {
    <#
    .SYNOPSIS
        1 IP có nằm trong dải IP CỐ ĐỊNH của 1 segment hay không — đúng quy tắc phân loại ở đầu
        7.3: segment DhcpScopeExists=true dùng StaticIpRangeRaw (bản chính) làm căn cứ, false
        dùng TOÀN BỘ CIDR. KHÔNG dùng CIDR cho segment có scope (CIDR còn bao gồm cả dynamic pool
        mà ARP/xóa tự động phải bỏ qua).
    #>
    param(
        [Parameter(Mandatory)] [string]$IpAddress,
        [Parameter(Mandatory)] [object]$Segment
    )
    if ($Segment.DhcpScopeExists) {
        foreach ($range in (ConvertFrom-StaticIpRangeRaw -Raw $Segment.StaticIpRangeRaw)) {
            if (Test-IpAddressInRange -IpAddress $IpAddress -RangeStart $range.start -RangeEnd $range.end) {
                return $true
            }
        }
        return $false
    }
    return Test-IpAddressInCidr -IpAddress $IpAddress -Cidr $Segment.CIDR
}

# --- Logging (Event Log + file log — 8.3/8.4) ------------------------------------------------

# Thứ tự mức độ, dùng để so sánh khi lọc theo LogLevel cấu hình (thấp -> cao).
$script:LogLevelOrder = @{ Debug = 0; Information = 1; Warning = 2; Error = 3 }

# Cấu hình qua biến môi trường IPAM_WORKER_LOG_LEVEL (cùng quy ước với IPAM_SMTP_RELAY_FQDN ở
# NotificationClient.psm1 — đặt ở Task Scheduler action hoặc máy, không hard-code trong Worker).
# Mặc định 'Information' nếu không cấu hình hoặc giá trị không hợp lệ.
$script:CurrentLogLevel = if ($env:IPAM_WORKER_LOG_LEVEL -and $script:LogLevelOrder.ContainsKey($env:IPAM_WORKER_LOG_LEVEL)) {
    $env:IPAM_WORKER_LOG_LEVEL
}
else {
    'Information'
}

function Set-WorkerLogLevel {
    <#
    .SYNOPSIS
        Đặt LogLevel hiện tại trong process (override biến môi trường) — dùng cho test, hoặc khi
        1 lần chạy cụ thể cần tạm bật Debug mà không đổi cấu hình toàn máy.
    #>
    param([Parameter(Mandatory)] [ValidateSet('Debug', 'Information', 'Warning', 'Error')] [string]$Level)
    $script:CurrentLogLevel = $Level
}

function Get-WorkerLogLevel {
    return $script:CurrentLogLevel
}

function Write-WorkerLog {
    <#
    .SYNOPSIS
        Ghi đồng thời vào Windows Event Log "IPAM-Worker" và file log. Cấm silent error (8.4):
        mọi exception bắt buộc phải qua hàm này trước khi bị nuốt.
    .DESCRIPTION
        Lọc theo LogLevel cấu hình (Set-WorkerLogLevel / $env:IPAM_WORKER_LOG_LEVEL): message có
        Level thấp hơn ngưỡng hiện tại sẽ KHÔNG được ghi. NGOẠI LỆ: Level=Error luôn được ghi bất
        kể ngưỡng cấu hình — để không vi phạm nguyên tắc "cấm silent error" (8.4) dù ngưỡng bị
        cấu hình sai/quá cao.

        Debug KHÔNG ghi vào Windows Event Log (EntryType của Event Log không có mức Debug, và
        Event Log giới hạn 512MB/overwrite — dành cho tín hiệu vận hành, không phải trace chi
        tiết). Debug chỉ ghi vào file log.
    #>
    param(
        [Parameter(Mandatory)] [string]$Message,
        [ValidateSet('Debug', 'Information', 'Warning', 'Error')] [string]$Level = 'Information',
        [int]$EventId = 1000,
        [string]$LogDirectory = "$PSScriptRoot\..\..\logs"
    )
    if ($Level -ne 'Error' -and $script:LogLevelOrder[$Level] -lt $script:LogLevelOrder[$script:CurrentLogLevel]) {
        return
    }
    if ($Level -ne 'Debug') {
        $entryType = switch ($Level) { 'Warning' { 'Warning' } 'Error' { 'Error' } default { 'Information' } }
        try {
            Write-EventLog -LogName 'IPAM-Worker' -Source 'IPAM-Worker' -EventId $EventId -EntryType $entryType -Message $Message
        }
        catch {
            Write-Warning "Không ghi được Event Log (đã cài? xem infra/scripts/bootstrap-vm.ps1): $_"
        }
    }
    if (-not (Test-Path $LogDirectory)) { New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null }
    $logFile = Join-Path $LogDirectory "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
    "$(Get-Date -Format 'o') [$Level] $Message" | Add-Content -Path $logFile
}

# --- Message template chung (thay {{Token}}) — dùng bởi cả log theo code dưới đây LẪN
# NotificationClient.psm1 (Send-TemplatedAlert), đặt ở Common.psm1 để không cài lại 2 nơi. -------

function Expand-MessageTemplate {
    <#
    .SYNOPSIS
        Thay {{Token}} trong $Text bằng giá trị tương ứng trong $Parameters.
    .DESCRIPTION
        Token thiếu param bắt buộc -> throw (cấm silent error, 8.4) — không được để log/mail có
        literal "{{Token}}" còn sót lại do quên truyền param.
    #>
    param(
        [Parameter(Mandatory)] [string]$Text,
        [hashtable]$Parameters = @{}
    )
    $tokenNames = @(([regex]::Matches($Text, '\{\{(\w+)\}\}') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique))
    $result = $Text
    foreach ($tokenName in $tokenNames) {
        if (-not $Parameters.ContainsKey($tokenName)) {
            throw "Template thiếu param bắt buộc '$tokenName' (token {{$tokenName}} không được thay thế)."
        }
        $result = $result.Replace("{{$tokenName}}", [string]$Parameters[$tokenName])
    }
    return $result
}

# --- Log message theo code (src/config/log-{info,warning,error}-messages.json) — 8.3/8.4 ------
#
# Quy ước Code: "<PREFIX>-<Worker-ID>-<XXXX>" — PREFIX cố định theo level (INFO/WARN/ERR/DEBUG),
# Worker-ID là tên viết tắt worker (vd ALLOC, SYNC, DEL, MON, ARP), XXXX là số thứ tự tự chọn
# (không ràng buộc liên tục, chỉ cần không trùng trong cùng Worker+PREFIX). Level KHÔNG lưu
# trong JSON — quyết định bởi việc gọi Write-InfoLog/-WarningLog/-ErrorLog/-DebugLog nào, để
# không thể có chuyện code với level khai báo sai lệch nhau trong catalog.
#
# 4 catalog TÁCH RIÊNG theo level (không dùng chung 1 file log-messages.json nữa) — PREFIX của
# Code quyết định file nào được đọc, tra theo bảng LogCatalogFileByPrefix dưới đây.
$script:LogCatalogFileByPrefix = @{
    INFO  = 'log-info-messages.json'
    WARN  = 'log-warning-messages.json'
    ERR   = 'log-error-messages.json'
    DEBUG = 'log-debug-messages.json'
}
#
# EventId ghi vào Windows Event Log — 1 Worker DÙNG CHUNG 1 EventId mặc định duy nhất cho MỌI
# log không chỉ định tay (không phân biệt theo Level/Seq nữa — đơn giản hoá theo yêu cầu thực tế,
# không cần độ chi tiết cao hơn). Định danh CHÍNH XÁC theo từng message luôn là chuỗi Code, nhúng
# sẵn ở đầu Message ("[INFO-ALLOC-0001] ..."), không phải EventId — EventId chỉ để lọc thô theo
# Worker trong Event Viewer. Riêng ARP: thiết kế gốc 7.3 đã quy định sẵn 3 EventId cụ thể
# (1001=thành công／1002=thất bại một phần／1003=thất bại toàn bộ) cho 3 kết quả execution xác
# định — dùng qua -EventId tay cho đúng 3 trường hợp đó; ARP=1000 dưới đây chỉ là mặc định cho
# các log KHÁC của ARP không thuộc 3 trường hợp thiết kế đã quy định.
$script:WorkerIdEventIdBase = @{
    ARP        = 1000  # arp-worker (reflect-to-ipam) — 1001/1002/1003 dùng tay theo thiết kế 7.3
    ALLOC      = 2000  # allocation-worker
    SYNC       = 3000  # segment-sync-worker
    DEL        = 4000  # auto-deletion-worker
    MON        = 5000  # src/monitoring (đọc-only, KHÔNG thuộc 4 Worker chính thức bảng 4.2 — xem GUIDE.md)
    SHAREPOINT = 1800  # src/common/SharePointClient.psm1 — hạ tầng dùng chung, không thuộc 1 Worker cụ thể
    NOTIF      = 1900  # src/common/NotificationClient.psm1 — hạ tầng dùng chung, không thuộc 1 Worker cụ thể
}

$script:LogCodePattern = '^(?<Prefix>INFO|WARN|ERR|DEBUG)-(?<WorkerId>[A-Z0-9]+)-(?<Seq>\d{4})$'
$script:CurrentWorkerId = $null

function Get-LogMessageTemplate {
    <#
    .SYNOPSIS
        Tra message template (chuỗi thô, còn {{Token}}) theo Code trong 1 file catalog JSON —
        src/config/log-info-messages.json / log-warning-messages.json / log-error-messages.json
        tuỳ Level (xem LogCatalogFileByPrefix, do Write-CodedLogInternal tự chọn đúng file theo
        prefix của Code — hàm này không tự đoán, -CatalogPath bắt buộc truyền tường minh).
        Dùng ConvertFrom-Json thường (KHÔNG -AsHashtable — tham số đó không có trên Windows
        PowerShell 5.1, runtime thật của Worker trên VM; xem README "Requirements").
    #>
    param(
        [Parameter(Mandatory)] [string]$Code,
        [Parameter(Mandatory)] [string]$CatalogPath
    )
    $catalog = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json
    if ($catalog.PSObject.Properties.Name -notcontains $Code) {
        throw "Không tìm thấy log message code '$Code' trong $CatalogPath"
    }
    return $catalog.$Code
}

function Set-CurrentWorkerId {
    <#
    .SYNOPSIS
        Đăng ký Worker-ID hiện tại cho process (gọi 1 lần ở đầu mỗi Worker script, ngay sau
        Import-Module Common.psm1) — để Write-InfoLog/-WarningLog/-ErrorLog dùng -Message (không có Code)
        vẫn tự suy được EventId mặc định đúng Worker, không phải truyền lại mỗi lần gọi.
    #>
    param([Parameter(Mandatory)] [string]$WorkerId)
    if (-not $script:WorkerIdEventIdBase.ContainsKey($WorkerId)) {
        throw "Worker-ID '$WorkerId' chưa đăng ký trong `$script:WorkerIdEventIdBase (Common.psm1) — thêm base EventId cho Worker-ID này trước."
    }
    $script:CurrentWorkerId = $WorkerId
}

function Get-CurrentWorkerId {
    return $script:CurrentWorkerId
}

function Write-CodedLogInternal {
    <#
    .SYNOPSIS
        Engine dùng chung cho Write-InfoLog/-WarningLog/-ErrorLog — KHÔNG export riêng, luôn đi
        qua 1 trong 3 hàm đó để Level không bao giờ tách rời khỏi prefix của Code.
    .DESCRIPTION
        Nhận -Code HOẶC -Message (ít nhất 1 trong 2) — ưu tiên -Code nếu cả 2 cùng truyền:
          - -Code: tra template trong đúng catalog theo prefix (INFO/WARN/ERR ->
            src/config/log-{info,warning,error}-messages.json, xem LogCatalogFileByPrefix — trừ
            khi -CatalogPath chỉ định tay), thay {{Token}}, prefix "[Code] " vào message (trừ khi
            -IncludeCodePrefix:$false). Worker-ID để suy EventId lấy từ chính Code (vd
            ERR-ALLOC-0001 -> ALLOC).
          - -Message: dùng thẳng làm nội dung log (vẫn cho {{Token}} qua -Parameters nếu muốn,
            không bắt buộc). Worker-ID để suy EventId lấy từ Get-CurrentWorkerId (đăng ký trước
            bằng Set-CurrentWorkerId) — nếu chưa đăng ký và cũng không truyền -EventId thì throw.

        EventId: nếu truyền -EventId thì dùng nguyên giá trị đó (vd giữ đúng 1001/1002/1003 của
        ARP theo thiết kế gốc 7.3). Không truyền thì tự suy = WorkerIdEventIdBase[Worker-ID] — 1
        Worker CHỈ 1 EventId mặc định duy nhất cho mọi log không chỉ định tay (không phân biệt
        theo Level/Seq — đơn giản hoá, không cần độ chi tiết cao hơn ở tầng EventId; định danh
        chi tiết luôn nằm ở chuỗi Code/Message, không phải EventId).
    #>
    param(
        [string]$Code,
        [string]$Message,
        [Parameter(Mandatory)] [ValidateSet('Information', 'Warning', 'Error', 'Debug')] [string]$Level,
        [Parameter(Mandatory)] [string]$ExpectedPrefix,
        [hashtable]$Parameters = @{},
        [Nullable[int]]$EventId = $null,
        [switch]$IncludeCodePrefix = $true,
        [string]$LogDirectory = "$PSScriptRoot\..\..\logs",
        [string]$CatalogPath
    )
    if (-not $Code -and -not $Message) {
        throw "Phải truyền -Code hoặc -Message (ít nhất 1 trong 2)."
    }

    $workerId = $null
    if ($Code) {
        if ($Code -notmatch $script:LogCodePattern) {
            throw "Code '$Code' sai định dạng — phải là <PREFIX>-<Worker-ID>-<XXXX> (vd ERR-ALLOC-0001)."
        }
        if ($Matches.Prefix -ne $ExpectedPrefix) {
            throw "Code '$Code' có prefix '$($Matches.Prefix)' nhưng đang gọi qua hàm mức '$ExpectedPrefix' — prefix và hàm gọi phải khớp nhau."
        }
        $workerId = $Matches.WorkerId
        $resolvedCatalogPath = if ($CatalogPath) { $CatalogPath } else { "$PSScriptRoot\..\config\$($script:LogCatalogFileByPrefix[$Matches.Prefix])" }
        $template = Get-LogMessageTemplate -Code $Code -CatalogPath $resolvedCatalogPath
        $renderedMessage = Expand-MessageTemplate -Text $template -Parameters $Parameters
        $finalMessage = if ($IncludeCodePrefix) { "[$Code] $renderedMessage" } else { $renderedMessage }
    }
    else {
        $workerId = $script:CurrentWorkerId
        $finalMessage = Expand-MessageTemplate -Text $Message -Parameters $Parameters
    }

    $resolvedEventId = $EventId
    if ($null -eq $resolvedEventId) {
        if (-not $workerId) {
            throw "Không xác định được Worker-ID để tự suy EventId — dùng -Code, hoặc gọi Set-CurrentWorkerId trước khi dùng -Message, hoặc truyền tay -EventId."
        }
        if (-not $script:WorkerIdEventIdBase.ContainsKey($workerId)) {
            throw "Worker-ID '$workerId' chưa đăng ký trong `$script:WorkerIdEventIdBase (Common.psm1) — thêm base EventId cho Worker-ID này, hoặc truyền tay -EventId."
        }
        $resolvedEventId = $script:WorkerIdEventIdBase[$workerId]
    }

    Write-WorkerLog -Message $finalMessage -Level $Level -EventId $resolvedEventId -LogDirectory $LogDirectory
}

function Write-InfoLog {
    <#
    .SYNOPSIS
        Ghi log Information — qua -Code (tra message trong src/config/log-info-messages.json,
        Code dạng INFO-<Worker-ID>-XXXX) HOẶC -Message (chuỗi tự do). Ưu tiên -Code nếu truyền cả
        2. Tên "Write-InfoLog" (không phải "Write-Info") để không đụng namespace tương lai.
        -EventId: tuỳ chọn, truyền tay khi cần khớp đúng 1 số cụ thể; bỏ trống thì tự suy theo
        Worker (xem Write-CodedLogInternal). -IncludeCodePrefix: mặc định BẬT (message kèm
        "[Code] " ở đầu khi dùng -Code), tắt bằng -IncludeCodePrefix:$false.
    #>
    param(
        [string]$Code,
        [string]$Message,
        [hashtable]$Parameters = @{},
        [Nullable[int]]$EventId = $null,
        [switch]$IncludeCodePrefix = $true,
        [string]$LogDirectory = "$PSScriptRoot\..\..\logs",
        [string]$CatalogPath
    )
    Write-CodedLogInternal -Code $Code -Message $Message -Level Information -ExpectedPrefix 'INFO' -EventId $EventId `
        -IncludeCodePrefix:$IncludeCodePrefix -Parameters $Parameters -LogDirectory $LogDirectory -CatalogPath $CatalogPath
}

function Write-WarningLog {
    <#
    .SYNOPSIS
        Như Write-InfoLog, mức Warning — tra src/config/log-warning-messages.json. -Code (nếu
        dùng) bắt buộc dạng WARN-<Worker-ID>-XXXX. Tên "Write-WarningLog" (KHÔNG phải
        "Write-Warning" — đó là cmdlet có sẵn của PowerShell, trùng tên sẽ che mất cmdlet gốc).
    #>
    param(
        [string]$Code,
        [string]$Message,
        [hashtable]$Parameters = @{},
        [Nullable[int]]$EventId = $null,
        [switch]$IncludeCodePrefix = $true,
        [string]$LogDirectory = "$PSScriptRoot\..\..\logs",
        [string]$CatalogPath
    )
    Write-CodedLogInternal -Code $Code -Message $Message -Level Warning -ExpectedPrefix 'WARN' -EventId $EventId `
        -IncludeCodePrefix:$IncludeCodePrefix -Parameters $Parameters -LogDirectory $LogDirectory -CatalogPath $CatalogPath
}

function Write-ErrorLog {
    <#
    .SYNOPSIS
        Như Write-InfoLog, mức Error — tra src/config/log-error-messages.json. -Code (nếu dùng)
        bắt buộc dạng ERR-<Worker-ID>-XXXX. Error luôn được ghi bất kể LogLevel cấu hình (xem
        Write-WorkerLog — 8.4, cấm silent error). Tên "Write-ErrorLog" (KHÔNG phải "Write-Error"
        — đó là cmdlet có sẵn của PowerShell, trùng tên sẽ che mất cmdlet gốc).
    #>
    param(
        [string]$Code,
        [string]$Message,
        [hashtable]$Parameters = @{},
        [Nullable[int]]$EventId = $null,
        [switch]$IncludeCodePrefix = $true,
        [string]$LogDirectory = "$PSScriptRoot\..\..\logs",
        [string]$CatalogPath
    )
    Write-CodedLogInternal -Code $Code -Message $Message -Level Error -ExpectedPrefix 'ERR' -EventId $EventId `
        -IncludeCodePrefix:$IncludeCodePrefix -Parameters $Parameters -LogDirectory $LogDirectory -CatalogPath $CatalogPath
}

function Write-DebugLog {
    <#
    .SYNOPSIS
        Như Write-InfoLog, mức Debug — tra src/config/log-debug-messages.json. -Code (nếu dùng)
        bắt buộc dạng DEBUG-<Worker-ID>-XXXX. Debug KHÔNG ghi Windows Event Log, chỉ ghi file log
        (xem Write-WorkerLog) — dù vậy vẫn cần resolve được EventId nội bộ (qua Worker-ID hoặc
        -EventId tay) để đi qua chung 1 engine với 3 hàm kia, dù giá trị đó không thực sự dùng.
        Thêm hàm này để KHÔNG còn chỗ nào trong Worker phải gọi thẳng Write-WorkerLog nữa — mọi
        log (cả 4 mức) đều nên đi qua Write-InfoLog/-WarningLog/-ErrorLog/-DebugLog.
    #>
    param(
        [string]$Code,
        [string]$Message,
        [hashtable]$Parameters = @{},
        [Nullable[int]]$EventId = $null,
        [switch]$IncludeCodePrefix = $true,
        [string]$LogDirectory = "$PSScriptRoot\..\..\logs",
        [string]$CatalogPath
    )
    Write-CodedLogInternal -Code $Code -Message $Message -Level Debug -ExpectedPrefix 'DEBUG' -EventId $EventId `
        -IncludeCodePrefix:$IncludeCodePrefix -Parameters $Parameters -LogDirectory $LogDirectory -CatalogPath $CatalogPath
}

Export-ModuleMember -Function `
    Enter-WorkerLock, Exit-WorkerLock, `
    Enter-IpEntryMutex, Exit-IpEntryMutex, `
    Invoke-WithExponentialBackoff, `
    Get-ElapsedDaysWithSkipCorrection, `
    Get-ExternalThreshold, `
    Write-WorkerLog, Set-WorkerLogLevel, Get-WorkerLogLevel, `
    Expand-MessageTemplate, `
    Set-CurrentWorkerId, Get-CurrentWorkerId, `
    Get-LogMessageTemplate, Write-InfoLog, Write-WarningLog, Write-ErrorLog, Write-DebugLog, `
    ConvertTo-UInt32IpAddress, `
    Test-IpAddressInCidr, `
    Test-IpAddressInRange, `
    ConvertFrom-StaticIpRangeRaw, `
    Test-IpAddressInStaticRange
