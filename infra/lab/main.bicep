// Lab-only entry point: simulates the pieces the CLIENT owns in production (VNet, subnet,
// on-prem-style AD domain) so the vendor-side deployment (infra/bicep/main.bicep) and the
// manual domain-join step (README.md §5.1) can be exercised end to end without a real client
// network. Never deploy this against a production subscription.

targetScope = 'resourceGroup'

param location string = resourceGroup().location

@description('Public IP (CIDR or single IP, e.g. 203.0.113.5/32) allowed to RDP into the lab DC.')
param allowedRdpSourceIp string

param vnetName string = 'vnet-lab-client'
param vnetAddressPrefix string = '10.10.0.0/16'
param subnetName string = 'snet-lab-client'
param subnetAddressPrefix string = '10.10.1.0/24'

param dcName string = 'vm-lab-dc-01'

@description('Static private IP for the lab DC — must fall inside subnetAddressPrefix. Also used as the VNet\'s DNS server.')
param dcPrivateIp string = '10.10.1.4'

@description('FQDN of the new lab AD forest, e.g. lab.local. Keep it clearly fake — never reuse a real domain name.')
param domainName string = 'lab.local'

param adminUsername string = 'labadmin'

@secure()
@description('Local admin password for the DC — becomes the Domain Administrator password after forest promotion.')
param adminPassword string

@secure()
@description('Directory Services Restore Mode password, required by AD DS forest promotion.')
param safeModeAdministratorPassword string

module vnet 'modules/vnet.bicep' = {
  name: 'lab-vnet'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnetName: subnetName
    subnetAddressPrefix: subnetAddressPrefix
    dcPrivateIp: dcPrivateIp
    allowedRdpSourceIp: allowedRdpSourceIp
  }
}

module dc 'modules/dc.bicep' = {
  name: 'lab-dc'
  params: {
    location: location
    dcName: dcName
    subnetId: vnet.outputs.subnetId
    dcPrivateIp: dcPrivateIp
    domainName: domainName
    adminUsername: adminUsername
    adminPassword: adminPassword
    safeModeAdministratorPassword: safeModeAdministratorPassword
  }
}

@description('Feed this into infra/bicep/main.bicep as `existingSubnetId` to deploy the vendor VM into this lab network.')
output subnetId string = vnet.outputs.subnetId
output dcPublicIp string = dc.outputs.dcPublicIp
output domainName string = domainName
