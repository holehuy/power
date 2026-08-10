// Provisions the lab's Active Directory Domain Controller and promotes it to a new forest via
// Azure Run Command (script content loaded inline — no storage account needed for a lab).

param location string
param dcName string
param subnetId string
param dcPrivateIp string
param domainName string
param adminUsername string

@secure()
param adminPassword string

@secure()
param safeModeAdministratorPassword string

param vmSize string = 'Standard_D2s_v5' // 2 vCPU / 8GB — plenty for a lab DC

resource pip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${dcName}-pip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${dcName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: dcPrivateIp
          publicIPAddress: { id: pip.id }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: dcName
  location: location
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: dcName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: { timeZone: 'Tokyo Standard Time' }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Premium_LRS' }
      }
    }
    networkProfile: {
      networkInterfaces: [ { id: nic.id } ]
    }
  }
}

resource promoteForest 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  parent: vm
  name: 'promote-adds-forest'
  location: location
  properties: {
    source: {
      script: loadTextContent('../scripts/promote-dc.ps1')
    }
    parameters: [
      { name: 'DomainName', value: domainName }
    ]
    protectedParameters: [
      { name: 'SafeModePassword', value: safeModeAdministratorPassword }
    ]
    timeoutInSeconds: 1800
    asyncExecution: false
  }
}

output dcResourceId string = vm.id
output dcPublicIp string = pip.properties.ipAddress
