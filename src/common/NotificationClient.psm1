<#
    Gửi alert nội bộ qua SMTP relay (8.3/8.4). Tách riêng để đổi FQDN relay/địa chỉ gửi
    (còn treo — xem docs/open-questions.md mục A) chỉ sửa 1 nơi, không rải rác trong 4 Worker.

    Quy ước chung notification flow (7.4, áp dụng cho MỌI loại thông báo ở Phụ lục F):
      1. Độ song song = 1.
      2. Thứ tự bắt buộc: xác nhận gửi mail THÀNH CÔNG → mới cập nhật cột guard
         (NotificationSentAt / CompletionNotifiedAt / FailureNotifiedAt / AlertLastNotifiedAt / v.v.).
      3. Trigger có thể chạy nhiều lần (at-least-once) — việc chống gửi trùng dựa vào bước 2,
         KHÔNG dựa vào việc gộp PATCH.

    Template hoá (Send-TemplatedAlert/templates/): nội dung mail của 21 loại thông báo Phụ lục F
    tách khỏi code, vì chương 13 (mẫu thông báo thật) do khách hàng cung cấp sau (còn treo —
    docs/open-questions.md mục A) — khi có mẫu thật chỉ cần sửa/thêm file trong templates/, không
    sửa .psm1. Send-InternalAlert (gửi thẳng Subject/Body dựng sẵn) vẫn giữ nguyên cho trường hợp
    không cần template (nội dung động phức tạp hơn 1 template cố định có thể biểu diễn).

    Thay {{Token}} dùng Expand-MessageTemplate của Common.psm1 (KHÔNG cài riêng ở đây) — cùng hàm
    này còn được Write-InfoLog/-WarningLog/-ErrorLog (log theo code, xem Common.psm1) dùng lại.
#>

Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot\Common.psm1" -Force

function Send-InternalAlert {
    <#
    .SYNOPSIS
        Gửi 1 email tới nkis-network@nkc.co.jp (hoặc người nhận chỉ định) qua SMTP relay nội bộ.
        KHÔNG tự ý retry gửi lại ở đây nếu gửi thất bại sau khi đã log — theo A-4 (v1.4),
        việc phục hồi thông báo bị mất do lỗi cuối cùng của flow là trách nhiệm của src/monitoring/,
        không phải tự động gửi lại từ chính Worker.
    #>
    param(
        [Parameter(Mandatory)] [string]$Subject,
        [Parameter(Mandatory)] [string]$Body,
        [string]$To = 'nkis-network@nkc.co.jp',
        [switch]$BodyAsHtml,
        [string]$SmtpRelayFqdn = $env:IPAM_SMTP_RELAY_FQDN, # TODO: giá trị thật còn treo — docs/open-questions.md
        [string]$FromAddress = $env:IPAM_WORKER_MAIL_FROM
    )
    if (-not $SmtpRelayFqdn) { throw 'SMTP relay FQDN chưa cấu hình (giá trị thực còn treo phía khách hàng).' }

    # Dùng -Code (không phải -EventId tay) — Code tự mang Worker-ID "NOTIF" (đăng ký sẵn trong
    # $script:WorkerIdEventIdBase, Common.psm1) nên EventId tự suy đúng (1900) mà KHÔNG cần truyền
    # tay VÀ không phụ thuộc Get-CurrentWorkerId của Worker đang gọi vào đây — quan trọng nhất ở
    # nhánh lỗi bên dưới: nếu chính việc BÁO LỖI gửi mail lại phụ thuộc ambient Worker-ID, 1 lần
    # Set-CurrentWorkerId bị thiếu/gọi sai ở đâu đó có thể khiến việc báo lỗi cũng throw theo —
    # không chấp nhận được (8.4).
    Write-InfoLog -Code 'INFO-NOTIF-0001' -Parameters @{ Subject = $Subject; To = $To }

    try {
        Send-MailMessage -To $To -From $FromAddress -Subject $Subject -Body $Body -SmtpServer $SmtpRelayFqdn -BodyAsHtml:$BodyAsHtml
        Write-InfoLog -Code 'INFO-NOTIF-0002' -Parameters @{ Subject = $Subject; To = $To }
    }
    catch {
        # Cấm silent error (8.4): log lỗi gửi mail, không nuốt exception.
        Write-ErrorLog -Code 'ERR-NOTIF-0001' -Parameters @{ Subject = $Subject; ErrorDetail = $_ }
        throw
    }
}

function Get-NotificationTemplate {
    <#
    .SYNOPSIS
        Đọc 1 file template trong templates/ — định dạng:
            Subject: <dòng subject, có thể chứa {{Token}}>
            ---
            <nội dung body, nhiều dòng, có thể chứa {{Token}}>
        IsHtml suy ra từ đuôi file: .html -> gửi dạng HTML (BodyAsHtml), còn lại -> plain text.
        Tên file (không kèm đuôi) = TemplateName, đặt theo ID Phụ lục F (vd F14-cooldown-restore)
        để truy vết ngược thiết kế.
    #>
    param(
        [Parameter(Mandatory)] [string]$TemplateName,
        [string]$TemplateDirectory = "$PSScriptRoot\templates"
    )
    # So khớp BaseName CHÍNH XÁC (không dùng -Filter wildcard "$TemplateName.*" — quirk 8.3
    # short-filename trên Windows có thể match nhầm tên file khác gần giống).
    $matchingFiles = @(Get-ChildItem -Path $TemplateDirectory -ErrorAction SilentlyContinue | Where-Object { $_.BaseName -eq $TemplateName })
    if ($matchingFiles.Count -eq 0) {
        throw "Không tìm thấy template '$TemplateName' trong $TemplateDirectory"
    }
    if ($matchingFiles.Count -gt 1) {
        throw "Có nhiều hơn 1 file khớp template '$TemplateName' trong $TemplateDirectory — tên phải là duy nhất."
    }
    $file = $matchingFiles[0]
    $raw = Get-Content -Path $file.FullName -Raw

    $parts = $raw -split '(?m)^---\s*$', 2
    if ($parts.Count -ne 2) {
        throw "Template '$TemplateName' ($($file.Name)) thiếu dòng phân cách '---' giữa Subject và Body."
    }
    $subjectLine = $parts[0].Trim()
    if ($subjectLine -notmatch '^Subject:\s*(.+)$') {
        throw "Template '$TemplateName' ($($file.Name)) thiếu dòng 'Subject: ...' hợp lệ."
    }

    return [PSCustomObject]@{
        Subject = $Matches[1].Trim()
        Body    = $parts[1].Trim()
        IsHtml  = ($file.Extension -eq '.html')
    }
}

function Send-TemplatedAlert {
    <#
    .SYNOPSIS
        Gửi alert dựng từ template (templates/*.txt hoặc *.html) thay vì hardcode Subject/Body
        trong từng Worker — chuẩn hoá nhanh khi khách hàng cung cấp mẫu thông báo thật (chương 13,
        docs/open-questions.md mục A): chỉ cần thêm/sửa file template, không sửa Worker.
        Dùng Expand-MessageTemplate của Common.psm1 để thay {{Token}} — cùng logic với
        Write-InfoLog/-WarningLog/-ErrorLog (log theo code), không cài lại 2 nơi.
    #>
    param(
        [Parameter(Mandatory)] [string]$TemplateName,
        [hashtable]$Parameters = @{},
        [string]$To = 'nkis-network@nkc.co.jp',
        [string]$TemplateDirectory = "$PSScriptRoot\templates",
        [string]$SmtpRelayFqdn = $env:IPAM_SMTP_RELAY_FQDN,
        [string]$FromAddress = $env:IPAM_WORKER_MAIL_FROM
    )
    $template = Get-NotificationTemplate -TemplateName $TemplateName -TemplateDirectory $TemplateDirectory
    $subject = Expand-MessageTemplate -Text $template.Subject -Parameters $Parameters
    $body = Expand-MessageTemplate -Text $template.Body -Parameters $Parameters
    Send-InternalAlert -Subject $subject -Body $body -To $To -BodyAsHtml:$template.IsHtml `
        -SmtpRelayFqdn $SmtpRelayFqdn -FromAddress $FromAddress
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

Export-ModuleMember -Function `
    Send-InternalAlert, `
    Send-TemplatedAlert, Get-NotificationTemplate, `
    Test-NotificationAlreadySent
