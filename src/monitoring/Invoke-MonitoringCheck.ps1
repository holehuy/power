#Requires -Modules IpamServer
<#
.SYNOPSIS
    Script giám sát (thiết kế 10.4). Chạy hằng ngày 07:00 JST.

.DESCRIPTION
    QUYỀN CHỈ ĐỌC (9.1) — script này KHÔNG được cấp quyền ghi. Cố tình chỉ phát hiện + báo cáo,
    KHÔNG tự động khôi phục / KHÔNG tự động gửi lại (quyết định A-4, v1.4), để tránh che giấu lỗi gốc.
    Phục hồi thủ công theo checklist trong docs/runbook/.

    4 nhóm phát hiện (10.4):
      (1) Kết quả chạy lần trước của từng Worker (Event Log "IPAM-Worker") — thất bại hoặc chưa chạy.
      (2) Tình trạng vượt chu kỳ / skip cycle thường xuyên (8.4).
      (3) Thiếu thông báo hoàn tất: CompletionNotifiedAt chưa set nhưng Status cha đã Assigned/PartiallyFailed.
      (4) Tồn đọng record cha: Status cha vẫn Pending quá 24 giờ kể từ khi tạo.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\..\common\Common.psm1" -Force
Import-Module "$PSScriptRoot\..\common\SharePointClient.psm1" -Force
Import-Module "$PSScriptRoot\..\common\NotificationClient.psm1" -Force
Set-CurrentWorkerId -WorkerId 'MON'

Write-InfoLog -Code 'INFO-MON-0001'

$findings = New-Object System.Collections.Generic.List[string]

# (1) Kết quả chạy lần trước của từng Worker
function Test-WorkerLastRunHealth {
    # TODO: đọc Event Log "IPAM-Worker", tìm entry gần nhất của từng Worker (event ID theo từng loại),
    # so sánh với tần suất kỳ vọng (5p/30p/1h/1 ngày). Nếu quá hạn hoặc entry cuối là lỗi -> thêm finding.
}
Test-WorkerLastRunHealth

# (2) Vượt chu kỳ / skip cycle thường xuyên
function Test-CycleOverrunPattern {
    # TODO: đếm số lần "skip cycle" ghi trong Event Log (8.4) trong khoảng thời gian gần đây,
    # nếu vượt ngưỡng bất thường -> thêm finding (dấu hiệu Worker đang chạy quá lâu so với chu kỳ).
}
Test-CycleOverrunPattern

# (3) Thiếu thông báo hoàn tất
function Test-MissingCompletionNotification {
    $stuck = Get-SharePointListItems -ListName 'IPRequests' `
        -Filter "fields/Status in ('Assigned','PartiallyFailed') and fields/CompletionNotifiedAt eq null"
    foreach ($r in $stuck) { $findings.Add("Thiếu thông báo hoàn tất: RequestId=$($r.RequestId)") }
}
Test-MissingCompletionNotification

# (4) Tồn đọng record cha ở Pending quá 24 giờ
function Test-StalePendingParent {
    $stale = Get-SharePointListItems -ListName 'IPRequests' -Filter "fields/Status eq 'Pending'" |
        Where-Object { ((Get-Date) - [datetime]$_.Created).TotalHours -gt 24 }
    foreach ($r in $stale) { $findings.Add("Record cha tồn đọng Pending > 24h: RequestId=$($r.RequestId)") }
}
Test-StalePendingParent

if ($findings.Count -gt 0) {
    Send-InternalAlert -Subject "[IPAM] Monitoring: phát hiện $($findings.Count) bất thường" `
        -Body ($findings -join "`n")
}

Write-InfoLog -Code 'INFO-MON-0002' -Parameters @{ Count = $findings.Count }
