// Entry point for the infrastructure the vendor is responsible for:
//   "New Azure VM ~ OS configuration, IPAM feature, scheduler registration" = vendor
//   Subscription / VNet / NSG / naming convention                          = client (NKC) — NOT provisioned
//   here, only referenced via parameter as an existing resource ID.
//
// VM spec: 4 vCPU / 16GB RAM, Windows Server 2022+,
// 128GB OS disk (Premium SSD) + a separate 128GB data disk for scripts/logs.

targetScope = 'resourceGroup'

@description('Resource ID of the existing subnet provided by the client (already able to join the internal AD domain via VPN/ExpressRoute).')
param existingSubnetId string

@description('VM name. Follow the client\'s internal naming convention — confirm before deploying.')
param vmName string = 'vm-ipam-worker-01'

@description('VM timezone — must be JST.')
param vmTimeZone string = 'Tokyo Standard Time'

param location string = resourceGroup().location

@secure()
@description('Temporary local admin password — replace with a gMSA/domain account right after the domain join.')
param localAdminPassword string

@description('Resource ID of the Azure Monitor action group to notify on the VM heartbeat alert. Leave blank to deploy the alert with no notification target (nobody gets paged) — create one with `az monitor action-group create` and pass its ID here, or re-deploy later once it exists.')
param actionGroupId string = ''

module vm 'modules/vm.bicep' = {
  name: 'vm-ipam-worker'
  params: {
    vmName: vmName
    location: location
    subnetId: existingSubnetId
    timeZone: vmTimeZone
    adminPassword: localAdminPassword
  }
}

module backupVault 'modules/backup-vault.bicep' = {
  name: 'backup-vault'
  params: {
    location: location
    vmResourceId: vm.outputs.vmResourceId
    vmName: vmName
  }
}

module heartbeat 'modules/monitor-heartbeat.bicep' = {
  name: 'monitor-heartbeat'
  params: {
    vmResourceId: vm.outputs.vmResourceId
    actionGroupId: actionGroupId
  }
}

output vmResourceId string = vm.outputs.vmResourceId
