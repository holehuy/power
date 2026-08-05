#Requires -Modules PnP.PowerShell
<#
.SYNOPSIS
    Nạp dữ liệu ban đầu cho list Segments (~1000 record theo ước tính 2.2) từ file CSV
    do khách hàng cung cấp (Phụ lục G RACI: "Segments master initial input work" = khách hàng
    tạo/xác nhận dữ liệu nguồn, vendor chỉ chịu trách nhiệm NHẬP LIỆU).

.NOTES
    KHÔNG tự suy đoán/generate dữ liệu Segments — mọi giá trị (CIDR, SiteCode, DhcpScopeExists...)
    phải đến từ file CSV đã được khách hàng xác nhận, đối chiếu cùng Phụ lục C.1.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SiteUrl,
    [Parameter(Mandatory)] [string]$CsvPath,
    [switch]$WhatIfOnly
)

$ErrorActionPreference = 'Stop'
Connect-PnPOnline -Url $SiteUrl -Interactive

$rows = Import-Csv -Path $CsvPath
Write-Host "Đọc $($rows.Count) dòng từ $CsvPath."

$requiredColumns = @('SegmentName', 'SiteCode', 'SiteName', 'CIDR', 'DhcpScopeExists')
foreach ($col in $requiredColumns) {
    if ($col -notin $rows[0].PSObject.Properties.Name) {
        throw "CSV thiếu cột bắt buộc '$col'. Xem sharepoint/schema/Segments.schema.json."
    }
}

foreach ($row in $rows) {
    # TODO: validate CIDR hợp lệ (network address đúng, không trùng segment khác) trước khi nhập —
    # thiết kế ghi rõ đây chỉ có kiểm tra thủ công (10.6), nhưng ở bước nhập ban đầu nên tự động hoá
    # validation cơ bản để tránh nhập sai hàng loạt.
    if ($WhatIfOnly) {
        Write-Host "[WhatIf] Sẽ tạo Segments: $($row.SegmentName) / $($row.CIDR)"
        continue
    }
    # TODO: Add-PnPListItem -List Segments -Values @{ SegmentName = $row.SegmentName; ... }
}

Write-Host "Xong. Nhắc: chạy segment-sync-worker 1 lần thủ công để đồng bộ range IPAM cho các segment DhcpScopeExists=true vừa nhập."
