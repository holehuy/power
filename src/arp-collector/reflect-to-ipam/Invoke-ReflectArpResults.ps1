#Requires -Modules IpamServer
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
#>

[CmdletBinding()]
param(
    [string]$ArpResultPath = 'D:\ipam-worker\logs\arp-collection-result.json'
)

$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\..\..\workers\common\IpamWorkerCommon.psm1" -Force
Import-Module "$PSScriptRoot\..\..\workers\common\SharePointClient.psm1" -Force
Import-Module "$PSScriptRoot\..\..\workers\common\NotificationClient.psm1" -Force

$arpEntries = Get-Content $ArpResultPath -Raw | ConvertFrom-Json
$segmentsSnapshot = Get-SharePointListItems -ListName 'Segments'

foreach ($entry in $arpEntries) {
    $segment = $segmentsSnapshot | Where-Object {
        # TODO: kiểm tra $entry.ip_address có thuộc $_.CIDR không (dùng ipaddress logic tương đương .NET).
        $false
    }
    if (-not $segment) { continue }

    # Bỏ qua IP nằm trong dynamic pool (scope range - exclusion range) — không lập sổ quản lý DHCP client (7.3).
    $isInDynamicPool = $false # TODO
    if ($isInDynamicPool) { continue }

    $mutex = Enter-IpEntryMutex -IpAddress $entry.ip_address
    if ($null -eq $mutex) {
        Write-WorkerLog -Message "Bỏ qua $($entry.ip_address): không lấy được mutex trong timeout (8.4)." -Level Warning
        continue
    }
    try {
        # TODO: Get-IpamAddress -IpAddress $entry.ip_address
        $existingIpamEntry = $null

        if ($existingIpamEntry -and $existingIpamEntry.Source -contains 'Cooldown') {
            # (a) Khôi phục theo bản chuẩn 7.4 §"ghi chú cooldown sau xóa" — ĐÚNG THỨ TỰ:
            # 1) LastSeenAt = thời điểm phát hiện (làm trước tiên)
            # 2) Source = AutoDetected (loại bỏ Cooldown, bất kể Source gốc)
            # 3) clear CooldownStartedAt
            # 4) clear RequestId
            # Nếu Source gốc (trước khi loại Cooldown) có chứa Requested -> gửi Phụ lục F#14.
        }
        elseif ($existingIpamEntry) {
            # (b) chỉ cập nhật LastSeenAt nếu đã qua >= 24h so với giá trị trước (không phụ thuộc IsActive).
        }
        else {
            # (c) chưa đăng ký -> Add-IpamAddress, TRỪ KHI segment IsActive=false hoặc RangeChangePending=true.
            if (-not $segment.IsActive -or $segment.RangeChangePending) {
                continue # giữ đăng ký mới — entry sẽ được đánh giá lại ở chu kỳ sau
            }
            # TODO: Add-IpamAddress -IpAddress $entry.ip_address -Source AutoDetected -MacAddress $entry.mac_address -LastSeenAt (Get-Date)
        }

        # Đối chiếu MAC khác nhau cho cùng 1 IP: ưu tiên timestamp mới nhất, ghi đè MAC.
        # Nếu Source=Requested -> nghi ngờ xung đột IP -> Phụ lục F#13. Nếu AutoDetected -> không thông báo.
    }
    finally {
        Exit-IpEntryMutex -Mutex $mutex
    }
}

Write-WorkerLog -Message "Phản ánh IPAM xong: $($arpEntries.Count) entry xử lý." -EventId 1301
