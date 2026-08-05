// Dedicated Recovery Services vault for this system — do not share with other vaults.
// Backs up: System State (including the IPAM WID database) + the entire data disk. Retention: 30 days / 13 weeks / 12 months.

param location string
param vmResourceId string
param vmName string

resource vault 'Microsoft.RecoveryServices/vaults@2023-06-01' = {
  name: 'rsv-ipam-worker'
  location: location
  sku: { name: 'RS0', tier: 'Standard' }
  properties: {}
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-06-01' = {
  parent: vault
  name: 'daily-30d-13w-12m'
  properties: {
    backupManagementType: 'AzureIaasVM'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [ '2026-01-01T18:00:00Z' ] // TODO: time the backup window to avoid the auto-deletion-worker's 02:00 JST run
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [ '2026-01-01T18:00:00Z' ]
        retentionDuration: { count: 30, durationType: 'Days' }
      }
      weeklySchedule: {
        daysOfTheWeek: [ 'Sunday' ]
        retentionTimes: [ '2026-01-01T18:00:00Z' ]
        retentionDuration: { count: 13, durationType: 'Weeks' }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleWeekly: { daysOfTheWeek: [ 'Sunday' ], weeksOfTheMonth: [ 'First' ] }
        retentionTimes: [ '2026-01-01T18:00:00Z' ]
        retentionDuration: { count: 12, durationType: 'Months' }
      }
    }
  }
}

// TODO: register vmResourceId/vmName against the policy above (Microsoft.RecoveryServices/vaults/backupFabrics/...
// backupProtectionContainers/protectedItems) — requires knowing the actual fabric name at deploy time.
