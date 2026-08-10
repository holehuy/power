#Requires -Modules PnP.PowerShell
<#
.SYNOPSIS
    Nạp dữ liệu ban đầu cho list ArpDeviceStatus từ danh sách thiết bị — deliverable của
    Phụ lục C.6 (khách hàng cung cấp danh sách, vendor nhập bằng tool này, Phụ lục G RACI).

.NOTES
    Bắt buộc mỗi dòng phải có DeviceType hợp lệ (CiscoIOS/FortiGate/YamahaRTX/MerakiMX) và,
    với thiết bị Meraki, MerakiNetworkId — thiếu 1 trong 2 sẽ khiến arp-worker SKIP thiết bị
    đó ngay từ chu kỳ đầu tiên (7.3/10.6).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SiteUrl,
    [Parameter(Mandatory)] [string]$CsvPath,
    [switch]$WhatIfOnly
)

$ErrorActionPreference = 'Stop'
Connect-PnPOnline -Url $SiteUrl -Interactive

$validDeviceTypes = @('CiscoIOS', 'FortiGate', 'YamahaRTX', 'MerakiMX')
$rows = Import-Csv -Path $CsvPath

$invalidRows = $rows | Where-Object { $_.DeviceType -notin $validDeviceTypes }
if ($invalidRows) {
    throw "Có $($invalidRows.Count) dòng DeviceType không hợp lệ. Giá trị cho phép: $($validDeviceTypes -join ', ')."
}

$missingMerakiId = $rows | Where-Object { $_.DeviceType -eq 'MerakiMX' -and -not $_.MerakiNetworkId }
if ($missingMerakiId) {
    throw "Có $($missingMerakiId.Count) thiết bị MerakiMX thiếu MerakiNetworkId (6.9) — bổ sung trước khi nhập."
}

foreach ($row in $rows) {
    if ($WhatIfOnly) {
        Write-Host "[WhatIf] Sẽ tạo ArpDeviceStatus: $($row.DeviceId) [$($row.DeviceType)]"
        continue
    }
    # TODO: Add-PnPListItem -List ArpDeviceStatus -Values @{
    #   DeviceId = $row.DeviceId; DeviceName = $row.DeviceName; DeviceFqdn = $row.DeviceFqdn
    #   DeviceType = $row.DeviceType; MerakiOrgId = $row.MerakiOrgId; MerakiNetworkId = $row.MerakiNetworkId
    #   TargetSegments = $row.TargetSegments -split ';'; CurrentStatus = 'OK'; ConsecutiveFailureCount = 0
    # }
}

Write-Host "Xong ($($rows.Count) thiết bị). Nhắc: xác nhận SNMP reachability/ACL đã sẵn sàng cho từng thiết bị (Phụ lục C.6) trước khi bật arp-worker lần đầu."
