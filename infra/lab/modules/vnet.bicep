// Simulates the client-owned network: a VNet + subnet with DNS already pointed at the lab's
// AD domain controller. In production this whole module doesn't exist — the client provides
// an existing subnet ID (see infra/bicep/main.bicep). Here we build it so the rest of the
// deploy+domain-join flow can be exercised end to end.

param location string
param vnetName string
param vnetAddressPrefix string
param subnetName string
param subnetAddressPrefix string
param dcPrivateIp string

@description('Public IP (CIDR or single IP) allowed to RDP into the lab DC. Use your own public IP, not 0.0.0.0/0.')
param allowedRdpSourceIp string

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${vnetName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRdpFromAdminIp'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedRdpSourceIp
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: [ vnetAddressPrefix ] }
    // Points every VM in this VNet at the lab DC for name resolution + domain discovery —
    // this is the setting a client would normally already have configured.
    dhcpOptions: { dnsServers: [ dcPrivateIp ] }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: { id: nsg.id }
        }
      }
    ]
  }
}

output subnetId string = vnet.properties.subnets[0].id
output vnetId string = vnet.id
