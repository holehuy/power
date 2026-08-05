// Provisions the VM that acts as both the primary Windows IPAM server and all Workers.
// Does NOT provision NSG/VNet here — the subnet already exists and is the client's responsibility.

param vmName string
param location string
param subnetId string
param timeZone string

@secure()
param adminPassword string

param adminUsername string = 'ipamworkeradmin'
param vmSize string = 'Standard_D4s_v5' // 4 vCPU / 16GB

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: { timeZone: timeZone }
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
        diskSizeGB: 128
      }
      // Separate data disk for Worker scripts + logs — kept apart from the OS disk so
      // backup/retention can be managed independently.
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 128
          managedDisk: { storageAccountType: 'Premium_LRS' }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [ { id: nic.id } ]
    }
  }
}

// TODO: domain join is done via a DSC extension or manually after the VM comes up —
// follows existing internal domain-join operational practice, not automated on first pass.

output vmResourceId string = vm.id
