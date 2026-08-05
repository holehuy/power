<#
    Gửi alert nội bộ qua SMTP relay (8.3/8.4). Tách riêng để đổi FQDN relay/địa chỉ gửi
    (còn treo — xem docs/open-questions.md mục A) chỉ sửa 1 nơi, không rải rác trong 4 Worker.

    Quy ước chung notification flow (7.4, áp dụng cho MỌI loại thông báo ở Phụ lục F):
      1. Độ song song = 1.
      2. Thứ tự bắt buộc: xác nhận gửi mail THÀNH CÔNG → mới cập nhật cột guard
         (NotificationSentAt / CompletionNotifiedAt / FailureNotifiedAt / AlertLastNotifiedAt / v.v.).
      3. Trigger có thể chạy nhiều lần (at-least-once) — việc chống gửi trùng dựa vào bước 2,
         KHÔNG dựa vào việc gộp PATCH.
#>

Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot\IpamWorkerCommon.psm1" -Force

function Send-InternalAlert {
    <#
    .SYNOPSIS
        Gửi 1 email tới nkis-network@nkc.co.jp (hoặc người nhận chỉ định) qua SMTP relay nội bộ.
        KHÔNG tự ý retry gửi lại ở đây nếu gửi thất bại sau khi đã log — theo A-4 (v1.4),
        việc phục hồi thông báo bị mất do lỗi cuối cùng của flow là trách nhiệm của monitoring-script,
        không phải tự động gửi lại từ chính Worker.
    #>
    param(
        [Parameter(Mandatory)] [string]$Subject,
        [Parameter(Mandatory)] [string]$Body,
        [string]$To = 'nkis-network@nkc.co.jp',
        [string]$SmtpRelayFqdn = $env:IPAM_SMTP_RELAY_FQDN, # TODO: giá trị thật còn treo — docs/open-questions.md
        [string]$FromAddress = $env:IPAM_WORKER_MAIL_FROM
    )
    if (-not $SmtpRelayFqdn) { throw 'SMTP relay FQDN chưa cấu hình (giá trị thực còn treo phía khách hàng).' }

    try {
        Send-MailMessage -To $To -From $FromAddress -Subject $Subject -Body $Body -SmtpServer $SmtpRelayFqdn
        Write-WorkerLog -Message "Đã gửi alert '$Subject' tới $To" -Level Information
    }
    catch {
        # Cấm silent error (8.4): log lỗi gửi mail, không nuốt exception.
        Write-WorkerLog -Message "Gửi alert '$Subject' thất bại: $_" -Level Error -EventId 1900
        throw
    }
}

function Test-NotificationAlreadySent {
    <#
    .SYNOPSIS
        Helper chuẩn hoá pattern "chỉ gửi nếu cột guard chưa thiết lập" dùng chung cho cả 21 loại
        thông báo ở Phụ lục F (NotificationSentAt / CompletionNotifiedAt / FailureNotifiedAt / ...).
    #>
    param([Parameter(Mandatory)] [Nullable[datetime]]$GuardColumnValue)
    return $null -ne $GuardColumnValue
}

Export-ModuleMember -Function Send-InternalAlert, Test-NotificationAlreadySent
