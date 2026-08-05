<#
.SYNOPSIS
    Script phản ánh IPAM (thiết kế 7.3) — chạy NỐI TIẾP trong cùng Task Scheduler job,
    ngay sau khi `arp_collector/main.py` xuất xong file JSON. Đây là phần DUY NHẤT được phép
    ghi vào IPAM cho luồng thu thập ARP (Python không thao tác IPAM trực tiếp).

.DESCRIPTION
    Lấy snapshot Segments ĐẦU chu kỳ này (không query lại giữa chừng) để phân loại IP thuộc
    dải IP cố định hay dynamic pool. Với mỗi IP trong dải IP cố định, phân nhánh theo 3 case (7.3):
      (a) đã đăng ký, Source chứa Cooldown -> khôi phục theo bản chuẩn (6.8/7.4).
      (b) đã đăng ký, không Cooldown -> chỉ cập nhật LastSeenAt (throttle 24h).
      (c) chưa đăng ký -> Add-IpamAddress Source=AutoDetected, TRỪ KHI segment đó IsActive=false
          hoặc RangeChangePending=true (giữ đăng ký mới, không giữ cập nhật LastSeenAt của entry có sẵn).

    QA (đã thêm vào docs/open-questions.md):
      - Cú pháp chính xác của Get-IpamAddress/Add-IpamAddress/Set-IpamAddress khi đọc/ghi custom
        field (Source/LastSeenAt/RequestId/CooldownStartedAt, 6.1/6.8) cần xác nhận với version
        Windows Server IPAM thật trên VM (8.1: Server 2022+) — code dưới dùng cú pháp hashtable
        `-CustomField @{Name=Value}` nhất quán, nhưng chưa được chạy thử với module IpamServer
        thật (không có ở môi trường lint/test Docker này — xem README "Limitation").
      - Nội dung email (Subject/Body) là placeholder hợp lý, KHÔNG phải văn bản cuối cùng —
        chương 13 (mẫu thông báo) chưa có, đã tracked ở docs/open-questions.md.

    Testability: file này CỐ Ý không có `#Requires -Modules IpamServer` ở đầu (khác với các
    Worker PowerShell khác trong repo) — `#Requires` chặn cả việc DOT-SOURCE file để lấy định
    nghĩa hàm, điều mà tests/powershell/ReflectArpResults.Tests.ps1 cần làm để Mock
    Get-/Add-/Set-IpamAddress trong môi trường không có IpamServer (Docker dev-toolchain trên
    Linux/Mac, xem README "Limitation"). Việc thiếu module IpamServer khi chạy PRODUCTION thật
    vẫn không silent: các cmdlet IPAM sẽ tự throw "command not found" ngay khi gọi (8.4).
#>

[CmdletBinding()]
param(
    [string]$ArpResultPath = 'D:\ipam-worker\logs\arp-collection-result.json'
)

$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\..\..\workers\common\IpamWorkerCommon.psm1" -Force
Import-Module "$PSScriptRoot\..\..\workers\common\SharePointClient.psm1" -Force
Import-Module "$PSScriptRoot\..\..\workers\common\NotificationClient.psm1" -Force

function ConvertTo-JstIso8601 {
    <#
    .SYNOPSIS
        Chuẩn hoá thời điểm về ISO 8601 kèm offset JST (6.8: định dạng bắt buộc của LastSeenAt).
    #>
    param([Parameter(Mandatory)] [string]$UtcIsoString)
    $utc = [DateTimeOffset]::Parse($UtcIsoString)
    return $utc.ToOffset([TimeSpan]::FromHours(9)).ToString('yyyy-MM-ddTHH:mm:sszzz')
}

function Get-SegmentForIp {
    <#
    .SYNOPSIS
        Tìm segment mà 1 IP thuộc dải CỐ ĐỊNH của nó (Test-IpAddressInStaticRange, IpamWorkerCommon).
        Trả $null nếu IP thuộc dynamic pool hoặc không thuộc bất kỳ segment nào -> bỏ qua ở 7.3.
    #>
    param(
        [Parameter(Mandatory)] [string]$IpAddress,
        [Parameter(Mandatory)] [object[]]$SegmentsSnapshot
    )
    foreach ($segment in $SegmentsSnapshot) {
        if (Test-IpAddressInStaticRange -IpAddress $IpAddress -Segment $segment) {
            return $segment
        }
    }
    return $null
}

function Invoke-ArpReflection {
    <#
    .SYNOPSIS
        Thân xử lý chính (7.3) — tách khỏi top-level script để Pester gọi trực tiếp với dữ liệu
        giả lập (Mock Get-/Add-/Set-IpamAddress), không cần chạy nguyên file (vốn Import-Module
        ở top-level và đọc file/SharePoint thật).
    .OUTPUTS
        Số entry đã xử lý (dùng để ghi log tổng kết).
    #>
    param(
        [Parameter(Mandatory)] [object[]]$ArpEntries,
        [Parameter(Mandatory)] [object[]]$SegmentsSnapshot
    )

    $processedCount = 0
    foreach ($entry in $ArpEntries) {
        $segment = Get-SegmentForIp -IpAddress $entry.ip_address -SegmentsSnapshot $SegmentsSnapshot
        if (-not $segment) {
            continue  # dynamic pool hoặc ngoài mọi dải cố định -> bỏ qua (7.3 mở đầu)
        }

        $mutex = Enter-IpEntryMutex -IpAddress $entry.ip_address
        if ($null -eq $mutex) {
            Write-WorkerLog -Message "Bỏ qua $($entry.ip_address): không lấy được mutex trong timeout (8.4)." -Level Warning
            continue
        }
        try {
            $existingIpamEntry = Get-IpamAddress -IpAddress $entry.ip_address -ErrorAction SilentlyContinue
            $observedAtJst = ConvertTo-JstIso8601 -UtcIsoString $entry.observed_at

            if ($existingIpamEntry -and $existingIpamEntry.Source -contains 'Cooldown') {
                # (a) Khôi phục từ Cooldown — ĐÚNG THỨ TỰ, không đảo (bản chuẩn 7.4 "ghi chú cooldown sau xóa"):
                #     1) LastSeenAt trước tiên — nếu bước sau lỗi giữa chừng, sub-flow hết hạn Cooldown (7.4)
                #        vẫn bị chặn xóa nhờ điều kiện LastSeenAt <= CooldownStartedAt không còn đúng.
                # Source/RequestId/LastSeenAt/CooldownStartedAt là 4 custom field của IPAM (6.1) —
                # KHÔNG phải tham số dựng sẵn của cmdlet, nên đều đi qua -CustomField như nhau.
                $originalHadRequested = $existingIpamEntry.Source -contains 'Requested'
                Set-IpamAddress -IpAddress $entry.ip_address -CustomField @{ LastSeenAt = $observedAtJst }
                Set-IpamAddress -IpAddress $entry.ip_address -CustomField @{ Source = 'AutoDetected' }
                Set-IpamAddress -IpAddress $entry.ip_address -CustomField @{ CooldownStartedAt = $null }
                Set-IpamAddress -IpAddress $entry.ip_address -CustomField @{ RequestId = $null }
                # MacAddress KHÔNG thao tác ở đây — cập nhật sau đó tuân theo quy tắc MAC chung bên dưới.
                if ($originalHadRequested) {
                    Send-InternalAlert `
                        -Subject "[IPAM-Worker] Khôi phục IP $($entry.ip_address) từ Cooldown (Phụ lục F#14)" `
                        -Body "IP $($entry.ip_address) vừa được ARP phát hiện lại và khôi phục từ Cooldown sang AutoDetected. Nguồn gốc trước khi vào Cooldown có bao gồm Requested — DNS record và sổ đăng ký KHÔNG được khôi phục tự động, cần IT xác nhận chủ sở hữu/mục đích sử dụng hiện tại của IP này."
                }
            }
            elseif ($existingIpamEntry) {
                # (b) Chỉ cập nhật LastSeenAt, throttle 24h, KHÔNG xét IsActive (duy trì quy định v1.2).
                $shouldUpdateLastSeen = $true
                if ($existingIpamEntry.LastSeenAt) {
                    $hoursSinceLastSeen = ([DateTimeOffset]::Parse($observedAtJst) - [DateTimeOffset]::Parse($existingIpamEntry.LastSeenAt)).TotalHours
                    $shouldUpdateLastSeen = $hoursSinceLastSeen -ge 24
                }
                if ($shouldUpdateLastSeen) {
                    Set-IpamAddress -IpAddress $entry.ip_address -CustomField @{ LastSeenAt = $observedAtJst }
                }
            }
            else {
                # (c) Chưa đăng ký -> AutoDetected, TRỪ KHI segment IsActive=false hoặc RangeChangePending=true.
                if (-not $segment.IsActive -or $segment.RangeChangePending) {
                    Write-WorkerLog -Message "Giữ đăng ký AutoDetected của $($entry.ip_address): segment '$($segment.SegmentName)' IsActive=false hoặc RangeChangePending=true (7.3) — đánh giá lại chu kỳ sau." -Level Information
                    continue
                }
                Add-IpamAddress -IpAddress $entry.ip_address -MacAddress $entry.mac_address `
                    -CustomField @{ Source = 'AutoDetected'; LastSeenAt = $observedAtJst }
                $processedCount++
                continue  # entry mới: MAC vừa gán = MAC phát hiện, không cần đối chiếu xung đột (7.3)
            }

            # Đối chiếu MAC — chỉ áp dụng cho entry ĐÃ TỒN TẠI từ trước (nhánh a/b). Nhánh (c) đã continue ở trên.
            if (-not $existingIpamEntry.MacAddress) {
                # IP đã đăng ký nhưng chưa thiết lập MAC -> liên kết giá trị MAC phát hiện (chỉ lần đầu).
                Set-IpamAddress -IpAddress $entry.ip_address -MacAddress $entry.mac_address
            }
            elseif ($existingIpamEntry.MacAddress -ne $entry.mac_address) {
                # MAC khác nhau cho cùng 1 IP -> timestamp mới nhất thắng, ghi đè MAC (v1.1).
                Set-IpamAddress -IpAddress $entry.ip_address -MacAddress $entry.mac_address
                if ($existingIpamEntry.Source -contains 'Requested') {
                    Send-InternalAlert `
                        -Subject "[IPAM-Worker] Nghi ngờ xung đột IP $($entry.ip_address) (Phụ lục F#13)" `
                        -Body "IP $($entry.ip_address) (Source=Requested) vừa phát hiện MAC khác với MAC đã đăng ký trước đó. MAC cũ: $($existingIpamEntry.MacAddress). MAC mới phát hiện: $($entry.mac_address). Đã ghi đè theo quy tắc timestamp mới nhất thắng — cần kiểm tra thủ công xem có thiết bị lạ đang dùng IP này không."
                }
                # Source=AutoDetected -> không thông báo (v1.1).
            }
            $processedCount++
        }
        finally {
            Exit-IpEntryMutex -Mutex $mutex
        }
    }
    return $processedCount
}

# --- Entry point cấp script ---------------------------------------------------------------
# Bọc trong guard "không dot-sourced" để Pester dot-source file này chỉ lấy định nghĩa hàm
# (Invoke-ArpReflection, Get-SegmentForIp, ConvertTo-JstIso8601) mà không chạy I/O thật
# (đọc file JSON/SharePoint/Exit-WorkerLock) — quy ước testability cho script .ps1 dạng này.
if ($MyInvocation.InvocationName -ne '.') {
    $arpEntries = @(Get-Content $ArpResultPath -Raw | ConvertFrom-Json)
    $segmentsSnapshot = @(Get-SharePointListItems -ListName 'Segments')

    $processedCount = Invoke-ArpReflection -ArpEntries $arpEntries -SegmentsSnapshot $segmentsSnapshot

    Write-WorkerLog -Message "Phản ánh IPAM xong: $processedCount/$($arpEntries.Count) entry xử lý." -EventId 1301

    # Lock bao trùm CẢ 2 pha (Python thu thập + PowerShell phản ánh, cùng 1 Task Scheduler job) —
    # pha PowerShell (CUỐI) là bên giải phóng lock do Python tạo ở đầu job (xem QA trong
    # arp_collector/worker_lock.py về quyết định kiến trúc này). Exit-WorkerLock chỉ xoá file theo
    # đường dẫn, không kiểm tra PID sở hữu, nên xoá được lock do tiến trình Python tạo ra.
    Exit-WorkerLock -LockPath (Join-Path "$PSScriptRoot\..\..\..\logs\locks" 'ArpCollectionJob.lock')
}
