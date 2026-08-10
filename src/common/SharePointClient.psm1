<#
    Wrapper gọi Graph API để đọc/ghi 7 SharePoint list. Tách riêng khỏi từng Worker để:
    - đổi cách xác thực (xoay chứng chỉ Entra ID app, 9.2) chỉ sửa 1 nơi;
    - đảm bảo mọi Worker dùng chung 1 cách retry/log khi gọi Graph (qua Common.psm1).

    Xác thực: đăng ký ứng dụng Entra ID chuyên dụng + chứng chỉ (9.1), quyền tối thiểu
    (chỉ truy cập SharePoint list — KHÔNG cấp quyền đọc directory rộng hơn mức cần).

    Dùng module MSAL.PS (gợi ý sẵn trong thiết kế gốc của hàm Connect-SharePointGraph) để lấy
    access token bằng chứng chỉ từ Cert:\CurrentUser\My — KHÔNG hand-roll JWT signing ở đây.

    QA (đã thêm vào docs/open-questions.md):
      - MSAL.PS chưa được liệt kê trong bảng "Requirements" của README.md — đã bổ sung khi
        implement file này. Cần cài `Install-Module MSAL.PS` trên VM lúc bootstrap
        (infra/scripts/bootstrap-vm.ps1 hiện chưa có bước này — cần bổ sung).
      - TenantId/ClientId/CertificateThumbprint thật chỉ có sau khi khách hàng hoàn tất đăng ký
        ứng dụng Entra ID + admin consent (RACI, Phụ lục G).
      - SiteId thật (hoặc host+path để tự resolve) chỉ có sau khi khách hàng cấp site SharePoint
        (RACI, Phụ lục G) — biến môi trường IPAM_SHAREPOINT_SITE_HOST/IPAM_SHAREPOINT_SITE_PATH
        dùng để tự resolve khi không truyền thẳng -SiteId.
#>

Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot\Common.psm1" -Force

$script:GraphConnectionParams = $null
$script:GraphSiteId = $null
$script:GraphListIdCache = @{}

function Connect-SharePointGraph {
    <#
    .SYNOPSIS
        Lấy access token bằng client credential flow (chứng chỉ), không dùng client secret dạng plaintext (Phụ lục E).
    #>
    param(
        [Parameter(Mandatory)] [string]$TenantId,
        [Parameter(Mandatory)] [string]$ClientId,
        [Parameter(Mandatory)] [string]$CertificateThumbprint,
        [string]$SiteId
    )
    # Dùng -Code (không phải -EventId tay) — Code tự mang Worker-ID "SHAREPOINT" (đăng ký sẵn
    # trong $script:WorkerIdEventIdBase, Common.psm1) nên EventId tự suy đúng (1800) mà KHÔNG cần
    # truyền tay VÀ không phụ thuộc Get-CurrentWorkerId của Worker đang gọi vào đây.
    Write-InfoLog -Code 'INFO-SHAREPOINT-0001'

    Import-Module MSAL.PS -ErrorAction Stop

    $cert = Get-Item "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction Stop
    $script:GraphConnectionParams = @{
        TenantId          = $TenantId
        ClientId          = $ClientId
        ClientCertificate = $cert
    }

    if ($SiteId) {
        $script:GraphSiteId = $SiteId
    }
    else {
        $siteHost = $env:IPAM_SHAREPOINT_SITE_HOST
        $sitePath = $env:IPAM_SHAREPOINT_SITE_PATH
        if (-not $siteHost -or -not $sitePath) {
            throw 'Thiếu -SiteId và biến môi trường IPAM_SHAREPOINT_SITE_HOST/IPAM_SHAREPOINT_SITE_PATH chưa cấu hình (giá trị đặc thù khách hàng — xem docs/open-questions.md).'
        }
        $headers = @{ Authorization = "Bearer $(Get-GraphAccessToken)" }
        $siteResponse = Invoke-WithExponentialBackoff {
            Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/sites/${siteHost}:${sitePath}" -Headers $headers
        }
        $script:GraphSiteId = $siteResponse.id
    }

    Write-InfoLog -Code 'INFO-SHAREPOINT-0002' -Parameters @{ SiteId = $script:GraphSiteId }
}

function Get-GraphAccessToken {
    <#
    .SYNOPSIS
        Lấy access token hiện hành, dựa vào token cache nội bộ của MSAL.PS (tự refresh khi gần
        hết hạn) — không tự cache lại token ở tầng module này để tránh 2 nguồn cache lệch nhau.
    #>
    if (-not $script:GraphConnectionParams) {
        throw 'Chưa gọi Connect-SharePointGraph trước khi dùng SharePointClient.'
    }
    (Get-MsalToken @script:GraphConnectionParams -Scopes 'https://graph.microsoft.com/.default').AccessToken
}

function Resolve-SharePointListId {
    <#
    .SYNOPSIS
        Tra id thật của 1 list theo displayName (cache trong phiên chạy — mỗi Task Scheduler job
        là 1 process mới nên không cần bền vững qua các lần chạy).
    #>
    param([Parameter(Mandatory)] [string]$ListName)
    if ($script:GraphListIdCache.ContainsKey($ListName)) {
        return $script:GraphListIdCache[$ListName]
    }

    $headers = @{ Authorization = "Bearer $(Get-GraphAccessToken)" }
    $uri = "https://graph.microsoft.com/v1.0/sites/$($script:GraphSiteId)/lists?`$filter=displayName eq '$ListName'&`$select=id"
    $response = Invoke-WithExponentialBackoff { Invoke-RestMethod -Method Get -Uri $uri -Headers $headers }
    if (-not $response.value -or $response.value.Count -eq 0) {
        throw "Không tìm thấy SharePoint list '$ListName' trong site đã cấu hình."
    }
    $script:GraphListIdCache[$ListName] = $response.value[0].id
    return $script:GraphListIdCache[$ListName]
}

function Get-SharePointListItems {
    <#
    .SYNOPSIS
        Lấy danh sách item của 1 SharePoint list, có filter OData. Trả về object phẳng (field trực
        tiếp là property, cộng thêm .Id) — KHÔNG lồng trong .fields — để các Worker gọi $_.CIDR,
        $_.IsActive... trực tiếp như quy ước hiện có trong reflect-to-ipam/Invoke-ReflectArpResults.ps1.
    .EXAMPLE
        Get-SharePointListItems -ListName 'IPRequestItems' -Filter "fields/Status eq 'Pending'"
    #>
    param(
        [Parameter(Mandatory)] [string]$ListName,
        [string]$Filter,
        [string[]]$Select
    )
    $listId = Resolve-SharePointListId -ListName $ListName
    $headers = @{ Authorization = "Bearer $(Get-GraphAccessToken)" }
    $uri = "https://graph.microsoft.com/v1.0/sites/$($script:GraphSiteId)/lists/$listId/items?`$expand=fields"
    if ($Filter) { $uri += "&`$filter=$Filter" }

    $items = @()
    while ($uri) {
        $response = Invoke-WithExponentialBackoff { Invoke-RestMethod -Method Get -Uri $uri -Headers $headers }
        foreach ($raw in $response.value) {
            $flat = [PSCustomObject]@{ Id = $raw.id }
            foreach ($prop in $raw.fields.PSObject.Properties) {
                Add-Member -InputObject $flat -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
            }
            $items += $flat
        }
        $uri = $response.'@odata.nextLink'
    }
    return $items
}

function New-SharePointListItem {
    param(
        [Parameter(Mandatory)] [string]$ListName,
        [Parameter(Mandatory)] [hashtable]$Fields
    )
    $listId = Resolve-SharePointListId -ListName $ListName
    $headers = @{ Authorization = "Bearer $(Get-GraphAccessToken)"; 'Content-Type' = 'application/json' }
    $uri = "https://graph.microsoft.com/v1.0/sites/$($script:GraphSiteId)/lists/$listId/items"
    $body = @{ fields = $Fields } | ConvertTo-Json -Depth 10

    $response = Invoke-WithExponentialBackoff { Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body }
    # Trả về ID item vừa tạo — dùng để suy ra ParentItemId (IPRequestItems) hay RequestId (7.1).
    return $response.id
}

function Update-SharePointListItem {
    <#
    .SYNOPSIS
        PATCH nhiều field trong 1 lần gọi — thiết kế yêu cầu gộp các field liên quan vào cùng 1 PATCH
        (ví dụ Status + AssignedIp + AssignedFqdn + ProcessedAt của IPRequestItems, 7.1) để giảm số lần
        Power Automate trigger phát hỏa và tránh trạng thái trung gian dở dang.
    #>
    param(
        [Parameter(Mandatory)] [string]$ListName,
        [Parameter(Mandatory)] [string]$ItemId,
        [Parameter(Mandatory)] [hashtable]$Fields
    )
    $listId = Resolve-SharePointListId -ListName $ListName
    $headers = @{ Authorization = "Bearer $(Get-GraphAccessToken)"; 'Content-Type' = 'application/json' }
    $uri = "https://graph.microsoft.com/v1.0/sites/$($script:GraphSiteId)/lists/$listId/items/$ItemId/fields"
    $body = $Fields | ConvertTo-Json -Depth 10

    Invoke-WithExponentialBackoff { Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $body } | Out-Null
}

Export-ModuleMember -Function `
    Connect-SharePointGraph, `
    Get-SharePointListItems, `
    New-SharePointListItem, `
    Update-SharePointListItem
