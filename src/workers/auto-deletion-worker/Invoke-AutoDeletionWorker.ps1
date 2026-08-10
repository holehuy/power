#Requires -Modules IpamServer, DnsServer
<#
.SYNOPSIS
    Worker tự động xóa (thiết kế 7.4). Chạy hằng ngày 02:00 JST qua Task Scheduler.

.DESCRIPTION
    RỦI RO CAO NHẤT trong toàn hệ thống (có thể xóa nhầm IP đang dùng) — build/test SAU CÙNG,
    sau khi segment-sync-worker và arp-worker đã chạy ổn định và có dữ liệu LastSeenAt/SkippedDays thật.

    Thứ tự bắt buộc theo 7.4:
      1. Snapshot Segments + ArpDeviceStatus tại thời điểm BẮT ĐẦU quét (dùng snapshot này xuyên suốt
         cả file — không query lại giữa chừng, để tiêu chí phán định không dao động).
      2. Tính danh sách segment loại trừ = (thiết bị Failed) UNION (segment chưa được cover).
      3. Cộng SkippedDays + ghi LastSkipDate cho các segment loại trừ.
      4. Với entry KHÔNG thuộc segment loại trừ: tính bậc thang theo Get-ElapsedDaysWithSkipCorrection.
      5. Sub-flow riêng: xóa vật lý khi hết hạn Cooldown (+31 ngày, không phải +30).
      6. Bộ đệm khi gỡ skip: tối đa 1 bậc chuyển giai đoạn/lần chạy, không xóa archive 12 tháng ở lần
         chạy đầu tiên sau khi gỡ.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\..\..\common\Common.psm1" -Force
Import-Module "$PSScriptRoot\..\..\common\SharePointClient.psm1" -Force
Import-Module "$PSScriptRoot\..\..\common\NotificationClient.psm1" -Force
Set-CurrentWorkerId -WorkerId 'DEL'

$lockPath = Enter-WorkerLock -WorkerName 'AutoDeletionWorker'
try {
    Write-InfoLog -Code 'INFO-DEL-0001'

    # --- Bước 1: snapshot đầu ca quét (7.4 — mọi tham chiếu Segments trong file này dùng snapshot này) ---
    $segmentsSnapshot = Get-SharePointListItems -ListName 'Segments'
    $arpDeviceSnapshot = Get-SharePointListItems -ListName 'ArpDeviceStatus'

    # --- Bước 2: tính segment loại trừ (KHÔNG phụ thuộc IsActive — tính lại tại runtime, 7.4/A-2) ---
    $failedDeviceSegments = $arpDeviceSnapshot | Where-Object { $_.CurrentStatus -eq 'Failed' } |
        ForEach-Object { $_.TargetSegments } | Select-Object -Unique
    $uncoveredSegments = $segmentsSnapshot | Where-Object {
        $cidr = $_.CIDR
        -not ($arpDeviceSnapshot | Where-Object { $_.TargetSegments -contains $cidr })
    }
    $excludedSegments = @($failedDeviceSegments) + @($uncoveredSegments.CIDR) | Select-Object -Unique

    # --- Bước 3: cộng SkippedDays cho segment loại trừ (tích luỹ VĨNH VIỄN — không reset, Phụ lục B #12) ---
    foreach ($cidr in $excludedSegments) {
        # TODO: Update-SharePointListItem Segments -> SkippedDays += 1, LastSkipDate = hôm nay (JST).
    }

    $anySkipNotification = $excludedSegments.Count -gt 0

    # --- Bước 4: quét entry IPAM, bỏ qua entry thuộc segment loại trừ và entry Cooldown (đánh giá riêng ở bước 5) ---
    $ipamEntries = @() # TODO: Get-IpamAddress toàn bộ, loại các entry Source chứa 'Cooldown'
    $deletionTable = @(
        @{ Source = 'AutoDetected'; Days = 30;  Action = 'Cooldown' }
        @{ Source = 'Requested';    Days = 90;  Stage = '3M-Reminder' }
        @{ Source = 'Requested';    Days = 180; Stage = '6M-Reminder' }
        @{ Source = 'Requested';    Days = 365; Stage = '12M-Deleted'; Action = 'Archive' }
    )

    foreach ($entry in $ipamEntries) {
        # Guard: IP không thuộc bất kỳ IPAM range nào (Segments.StaticIpRangeRaw) -> KHÔNG đánh giá xóa,
        # đưa vào danh sách "giữ xóa theo predicate đơn vị IP" và ghi nhận cho thông báo #15 (7.4).
        $segment = $segmentsSnapshot | Where-Object { $_.CIDR -eq $entry.SegmentCidr }
        if (-not $segment) { $anySkipNotification = $true; continue }

        $skippedDays = if ($excludedSegments -contains $segment.CIDR) { $segment.SkippedDays } else { 0 }
        if ($excludedSegments -contains $segment.CIDR) { continue } # skip toàn bộ phán định LastSeenAt cho segment loại trừ

        $elapsedDays = Get-ElapsedDaysWithSkipCorrection -FromTimestampUtc $entry.LastSeenAt -SkippedDays $skippedDays

        # TODO: map $elapsedDays vào $deletionTable theo $entry.Source, ghi NotificationStage chỉ khi
        # khác giá trị hiện tại (7.4), xử lý clear/giữ NotificationSentAt theo quy tắc Error-override,
        # và với AutoDetected 30 ngày -> chuyển Source += Cooldown, set CooldownStartedAt (KHÔNG xoá DNS
        # vì AutoDetected không có DNS).
    }

    # --- Bước 5: sub-flow xóa vật lý khi hết hạn Cooldown (+31 ngày = 30 giữ + 1 xác nhận) ---
    $cooldownEntries = @() # TODO: entry có Source chứa 'Cooldown', LẤY TỪ CÙNG snapshot ipamEntries phía trên
    foreach ($entry in $cooldownEntries) {
        $segment = $segmentsSnapshot | Where-Object { $_.CIDR -eq $entry.SegmentCidr }
        $skippedDays = if ($segment -and $excludedSegments -contains $segment.CIDR) { $segment.SkippedDays } else { 0 }
        $elapsedSinceCooldown = Get-ElapsedDaysWithSkipCorrection -FromTimestampUtc $entry.CooldownStartedAt -SkippedDays $skippedDays

        $expired = $elapsedSinceCooldown -ge 31 # 30 ngày giữ + 1 ngày xác nhận (Phụ lục A)
        $stillCooldown = $entry.Source -contains 'Cooldown'
        $notTouchedSinceCooldown = $entry.LastSeenAt -le $entry.CooldownStartedAt

        if ($expired -and $stillCooldown -and $notTouchedSinceCooldown) {
            # TODO: Remove-IpamAddress -> trả về pool trống. KHÔNG thao tác DNS (đã xoá khi chuyển Cooldown).
        }
        # Nếu segment đó nằm trong $excludedSegments -> skip ngay cả khi đã hết hạn, đưa vào #15.
    }

    if ($anySkipNotification) {
        # TODO: gửi Phụ lục F#15, phân biệt rõ lý do (Failed thiết bị / chưa cover / không thuộc range)
        # và số ngày skip liên tục (SkippedDays cho 2 lý do đầu).
    }

    Write-InfoLog -Code 'INFO-DEL-0002'
}
finally {
    Exit-WorkerLock -LockPath $lockPath
}
