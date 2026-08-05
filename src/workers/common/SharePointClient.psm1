<#
    Wrapper gọi Graph API để đọc/ghi 7 SharePoint list. Tách riêng khỏi từng Worker để:
    - đổi cách xác thực (xoay chứng chỉ Entra ID app, 9.2) chỉ sửa 1 nơi;
    - đảm bảo mọi Worker dùng chung 1 cách retry/log khi gọi Graph (qua IpamWorkerCommon).

    Xác thực: đăng ký ứng dụng Entra ID chuyên dụng + chứng chỉ (9.1), quyền tối thiểu
    (chỉ truy cập SharePoint list — KHÔNG cấp quyền đọc directory rộng hơn mức cần).
#>

Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot\IpamWorkerCommon.psm1" -Force

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
    # TODO: dùng MSAL.PS hoặc thư viện tương đương để lấy token bằng cert từ CurrentUser\My store.
    # Không lưu token/refresh token ra đĩa dạng plaintext.
    throw "TODO: implement Connect-SharePointGraph (MSAL cert auth)."
}

function Get-SharePointListItems {
    <#
    .SYNOPSIS
        Lấy danh sách item của 1 SharePoint list, có filter OData.
    .EXAMPLE
        Get-SharePointListItems -ListName 'IPRequestItems' -Filter "fields/Status eq 'Pending'"
    #>
    param(
        [Parameter(Mandatory)] [string]$ListName,
        [string]$Filter,
        [string[]]$Select
    )
    Invoke-WithExponentialBackoff {
        # TODO: GET /sites/{site-id}/lists/{list-id}/items?expand=fields&$filter=...
        throw "TODO: implement Get-SharePointListItems for list '$ListName'."
    }
}

function New-SharePointListItem {
    param(
        [Parameter(Mandatory)] [string]$ListName,
        [Parameter(Mandatory)] [hashtable]$Fields
    )
    Invoke-WithExponentialBackoff {
        # TODO: POST /sites/{site-id}/lists/{list-id}/items { fields: $Fields }
        # Trả về ID item vừa tạo — dùng để suy ra ParentItemId (IPRequestItems) hay RequestId (7.1).
        throw "TODO: implement New-SharePointListItem for list '$ListName'."
    }
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
    Invoke-WithExponentialBackoff {
        # TODO: PATCH /sites/{site-id}/lists/{list-id}/items/{item-id}/fields
        throw "TODO: implement Update-SharePointListItem for list '$ListName' item '$ItemId'."
    }
}

Export-ModuleMember -Function `
    Connect-SharePointGraph, `
    Get-SharePointListItems, `
    New-SharePointListItem, `
    Update-SharePointListItem
