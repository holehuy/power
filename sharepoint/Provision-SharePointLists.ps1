#Requires -Modules PnP.PowerShell
<#
.SYNOPSIS
    Đọc toàn bộ schema/*.schema.json và tạo 7 SharePoint list + cột index tương ứng (6.1).

.DESCRIPTION
    Idempotent: nếu list/cột đã tồn tại thì bỏ qua, không lỗi khi chạy lại. Chạy 1 lần khi
    dựng môi trường mới (dev/staging/prod), KHÔNG chạy trên site đã có dữ liệu thật mà không
    review kỹ trước — sai schema sau khi đã có data thật sẽ khó sửa.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SiteUrl,
    [string]$SchemaDirectory = "$PSScriptRoot\schema"
)

$ErrorActionPreference = 'Stop'
Connect-PnPOnline -Url $SiteUrl -Interactive

$schemaFiles = Get-ChildItem -Path $SchemaDirectory -Filter '*.schema.json' |
    Where-Object { $_.Name -notlike '_*' } # bỏ qua _IpamCustomFields.reference.json — không phải SharePoint list

foreach ($file in $schemaFiles) {
    $schema = Get-Content $file.FullName -Raw | ConvertFrom-Json
    Write-Host "== $($schema.listName) =="

    if (-not (Get-PnPList -Identity $schema.listName -ErrorAction SilentlyContinue)) {
        New-PnPList -Title $schema.listName -Template GenericList | Out-Null
        Write-Host "  Đã tạo list."
    }

    foreach ($col in $schema.columns) {
        $existing = Get-PnPField -List $schema.listName -Identity $col.name -ErrorAction SilentlyContinue
        if ($existing) { continue }

        $fieldType = switch ($col.type) {
            'Text'          { 'Text' }
            'MultiLineText' { 'Note' }
            'MultiText'     { 'MultiChoice' } # TargetSegments — cân nhắc đổi sang Note (JSON) tùy PnP support thực tế
            'Number'        { 'Number' }
            'Boolean'       { 'Boolean' }
            'DateTime'      { 'DateTime' }
            'DateOnly'      { 'DateTime' }
            'Choice'        { 'Choice' }
            default         { 'Text' }
        }

        $params = @{
            List     = $schema.listName
            Type     = $fieldType
            AddToDefaultView = $true
        }
        if ($col.type -eq 'Choice' -and $col.choices) {
            Add-PnPField @params -InternalName $col.name -DisplayName $col.name -Choices $col.choices | Out-Null
        }
        else {
            Add-PnPField @params -InternalName $col.name -DisplayName $col.name | Out-Null
        }
        Write-Host "  + $($col.name) ($($col.type))"
    }

    # Cột index (6.1: bắt buộc cho delegation Power Apps — thiếu sẽ khiến query bị giới hạn 2000 dòng âm thầm sai)
    foreach ($indexCol in ($schema.indexes | Where-Object { $_ })) {
        try {
            Add-PnPFieldIndex -List $schema.listName -FieldInternalName $indexCol -ErrorAction Stop
            Write-Host "  Index: $indexCol"
        }
        catch {
            Write-Warning "  Không tạo được index cho '$indexCol': $_"
        }
    }
}

Write-Host "`nXong. Tiếp theo: chạy tools/initial-data-loader/ để nạp dữ liệu ban đầu Segments + ArpDeviceStatus."
