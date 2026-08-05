#Requires -Modules IpamServer, DnsServer
<#
.SYNOPSIS
    Worker cấp phát IP (thiết kế 7.1). Chạy mỗi 5 phút qua Task Scheduler.

.DESCRIPTION
    Xử lý theo ĐƠN VỊ DÒNG CHI TIẾT (IPRequestItems), không theo record cha.
    Thứ tự đúng theo 7.1:
      0. Đầu chu kỳ: tổng hợp Status cha cho các record đã đủ điều kiện kết thúc (tự phục hồi sau crash).
      1. Lấy dòng chi tiết Status=Pending (join cha qua ParentItemId), SKIP segment có RangeChangePending=true.
      2. Set Status=Processing (lock). Thu hồi Processing tồn đọng > 30 phút.
      3. Với từng dòng: kiểm tra đã có entry IPAM theo khoá dòng chi tiết chưa (resume nếu có).
      4. Chọn IP trống (tối đa 3 ứng viên), Add-IpamAddress — lỗi uniqueness = phát hiện trùng (không pre-check).
      5. Đăng ký DNS nếu có hostname (kiểm tra trùng DNS trước).
      6. Ghi Status=Assigned + AssignedIp/AssignedFqdn/ProcessedAt trong CÙNG 1 PATCH.
      7. Lỗi vĩnh viễn (NoFreeIp/DnsDuplicate/NamingRule) -> Failed ngay. Lỗi tạm thời -> retry qua chu kỳ (RetryCount, max 3).
#>

[CmdletBinding()]
param(
    [string]$ConfigPath = "$PSScriptRoot\..\..\config\thresholds.json"
)

$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\..\common\IpamWorkerCommon.psm1" -Force
Import-Module "$PSScriptRoot\..\common\SharePointClient.psm1" -Force
Import-Module "$PSScriptRoot\..\common\NotificationClient.psm1" -Force

$lockPath = Enter-WorkerLock -WorkerName 'AllocationWorker'
try {
    Write-WorkerLog -Message 'AllocationWorker bắt đầu chu kỳ.' -EventId 1101

    # --- Bước 0: tổng hợp Status cha cho các record đã đủ điều kiện kết thúc (7.1, idempotent) ---
    function Sync-ParentRequestStatus {
        # TODO: tìm IPRequests.Status=Pending có toàn bộ IPRequestItems con đã ở trạng thái kết thúc
        # (Assigned/Failed), rồi PATCH Status cha = Assigned/PartiallyFailed/Failed theo quy tắc tổng hợp.
        # Đây là bước tự phục hồi cho trường hợp Worker crash sau khi ghi xong dòng chi tiết cuối
        # nhưng trước khi tổng hợp cha.
    }
    Sync-ParentRequestStatus

    # --- Bước 1: lấy dòng chi tiết Pending, loại trừ segment đang RangeChangePending=true ---
    $pendingItems = Get-SharePointListItems -ListName 'IPRequestItems' -Filter "fields/Status eq 'Pending'"
    # TODO: join Segments qua Segment của record cha; nếu Segments.RangeChangePending = true thì SKIP
    # (không cộng RetryCount, không đưa vào thu hồi Processing tồn đọng — 7.1).

    foreach ($item in $pendingItems) {
        # --- Bước 2: lock dòng chi tiết ---
        Update-SharePointListItem -ListName 'IPRequestItems' -ItemId $item.Id -Fields @{ Status = 'Processing' }

        try {
            # --- Bước 3: resume nếu đã có entry IPAM theo khoá dòng chi tiết (REQ-yyyymmdd-{cha}-{con}) ---
            $itemKey = "REQ-{0}-{1}-{2}" -f (Get-Date -Format 'yyyyMMdd'), $item.ParentItemId, $item.Id
            # TODO: Get-IpamAddress -RequestId $itemKey ; nếu tồn tại thì dùng lại IP đó, không cấp mới.

            # --- Bước 4: chọn IP trống, tối đa 3 ứng viên, Add-IpamAddress là điểm phát hiện trùng ---
            $assignedIp = $null
            $errorCategory = $null
            for ($candidateAttempt = 1; $candidateAttempt -le 3 -and -not $assignedIp; $candidateAttempt++) {
                try {
                    # TODO: $candidate = Find-IpamFreeAddress -NetworkId <segment CIDR range> | Select -First 1
                    # TODO: Add-IpamAddress -IpAddress $candidate -Source Requested -RequestId $itemKey
                    # $assignedIp = $candidate
                }
                catch {
                    if ($_.Exception.Message -notmatch 'uniqueness|duplicate') { throw }
                    Write-WorkerLog -Message "Ứng viên IP trùng (lần $candidateAttempt/3) cho item $($item.Id)." -Level Warning
                }
            }
            if (-not $assignedIp) {
                $errorCategory = 'NoFreeIp' # lỗi vĩnh viễn -> Failed ngay, không retry qua chu kỳ (7.1(4))
            }

            # --- Bước 5: đăng ký DNS nếu có hostname ---
            $assignedFqdn = $null
            if ($errorCategory -eq $null -and $item.HostName) {
                # TODO: Resolve-DnsName -Name "$($item.HostName).ad.nkc.co.jp" -Server <DNS server ghi>
                #   - có kết quả & aging timestamp (record động) -> ErrorCategory=DnsDuplicateDynamic
                #   - có kết quả tĩnh -> ErrorCategory=DnsDuplicate
                #   - không có -> Add-DnsServerResourceRecordA -CreatePtr
                # Lỗi DNS -> ROLLBACK IPAM (Remove-IpamAddress) trước khi xác định Failed.
            }

            # --- Bước 6/7: ghi kết quả trong CÙNG 1 PATCH ---
            if ($errorCategory) {
                Update-SharePointListItem -ListName 'IPRequestItems' -ItemId $item.Id -Fields @{
                    Status        = 'Failed'
                    ErrorCategory = $errorCategory
                    ProcessedAt   = (Get-Date).ToString('o')
                }
            }
            else {
                Update-SharePointListItem -ListName 'IPRequestItems' -ItemId $item.Id -Fields @{
                    Status       = 'Assigned'
                    AssignedIp   = $assignedIp
                    AssignedFqdn = $assignedFqdn
                    ProcessedAt  = (Get-Date).ToString('o')
                }
                # LastSeenAt của entry IPAM được khởi tạo = thời điểm cấp phát (7.1) — thực hiện cùng lúc Add-IpamAddress.
            }
        }
        catch {
            # Lỗi tạm thời (Graph/IPAM/DNS) -> rollback IPAM nếu đã đăng ký -> trả Pending -> tăng RetryCount.
            Write-WorkerLog -Message "Lỗi xử lý item $($item.Id): $_" -Level Error -EventId 1102
            # TODO: tăng RetryCount; nếu RetryCount >= 3 -> rollback IPAM -> Status=Failed, ErrorCategory=SystemError,
            # gửi escalation tới nkis-network (Phụ lục F#17). Nếu < 3 -> Status=Pending để xử lý ở chu kỳ sau.
        }
    }

    # --- Thu hồi Processing tồn đọng > 30 phút (8.4) ---
    function Reclaim-StuckProcessingItems {
        # TODO: tìm IPRequestItems.Status=Processing có thời điểm cập nhật cuối > 30 phút trước.
        # Trả về Pending + tăng RetryCount; nếu RetryCount >= 3 -> rollback IPAM -> Failed (SystemError).
        # Gửi cảnh báo Phụ lục F#18.
    }
    Reclaim-StuckProcessingItems

    Write-WorkerLog -Message 'AllocationWorker kết thúc chu kỳ.' -EventId 1103
}
finally {
    Exit-WorkerLock -LockPath $lockPath
}
