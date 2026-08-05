<#
    Module dùng chung cho cả 4 Worker: khoá thực thi, retry, tính ngày, tham số ngoài, ghi log.
    Mọi Worker PHẢI dùng các hàm ở đây thay vì tự cài lại logic tương đương — các quy tắc này
    (đặc biệt Get-ElapsedDaysWithSkipCorrection) là "bản chuẩn" theo thiết kế 6.8-2; cài lại riêng
    ở từng Worker sẽ có nguy cơ lệch công thức giữa các Worker.
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
        [string]$LockDirectory = "$PSScriptRoot\..\..\..\logs\locks",
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
        [string]$ConfigPath = "$PSScriptRoot\..\..\config\thresholds.json"
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

function Write-WorkerLog {
    <#
    .SYNOPSIS
        Ghi đồng thời vào Windows Event Log "IPAM-Worker" và file log. Cấm silent error (8.4):
        mọi exception bắt buộc phải qua hàm này trước khi bị nuốt.
    #>
    param(
        [Parameter(Mandatory)] [string]$Message,
        [ValidateSet('Information', 'Warning', 'Error')] [string]$Level = 'Information',
        [int]$EventId = 1000,
        [string]$LogDirectory = "$PSScriptRoot\..\..\..\logs"
    )
    $entryType = switch ($Level) { 'Warning' { 'Warning' } 'Error' { 'Error' } default { 'Information' } }
    try {
        Write-EventLog -LogName 'IPAM-Worker' -Source 'IPAM-Worker' -EventId $EventId -EntryType $entryType -Message $Message
    }
    catch {
        Write-Warning "Không ghi được Event Log (đã cài? xem infra/scripts/bootstrap-vm.ps1): $_"
    }
    if (-not (Test-Path $LogDirectory)) { New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null }
    $logFile = Join-Path $LogDirectory "worker-$(Get-Date -Format 'yyyy-MM-dd').log"
    "$(Get-Date -Format 'o') [$Level] $Message" | Add-Content -Path $logFile
}

Export-ModuleMember -Function `
    Enter-WorkerLock, Exit-WorkerLock, `
    Enter-IpEntryMutex, Exit-IpEntryMutex, `
    Invoke-WithExponentialBackoff, `
    Get-ElapsedDaysWithSkipCorrection, `
    Get-ExternalThreshold, `
    Write-WorkerLog, `
    ConvertTo-UInt32IpAddress, `
    Test-IpAddressInCidr, `
    Test-IpAddressInRange, `
    ConvertFrom-StaticIpRangeRaw, `
    Test-IpAddressInStaticRange
