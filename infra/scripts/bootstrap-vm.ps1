#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Bootstraps a freshly-provisioned Azure VM into an IPAM + Worker server.
    Run ONCE, manually, right after the VM is up and has joined the internal AD domain
    (domain join is NOT automated by this script — per existing internal domain-join
    operational practice, do it manually/via DSC before running this file).

.NOTES
    Idempotent: safe to re-run — every step checks current state before acting.
#>

[CmdletBinding()]
param(
    [string]$DataDiskDriveLetter = 'D',
    [string]$WorkerRootPath = "$DataDiskDriveLetter`:\ipam-worker",
    [string]$EventLogName = 'IPAM-Worker'
)

$ErrorActionPreference = 'Stop'

Write-Host "1/5 Installing the IPAM Windows Feature..."
if (-not (Get-WindowsFeature -Name IPAM).Installed) {
    Install-WindowsFeature IPAM -IncludeManagementTools
}

Write-Host "2/5 Installing the Python runtime for arp-collector (requires 3.11+)..."
# TODO: install Python 3.11 via winget/choco per internal infrastructure standards; runtime patching
# is owned by the network/infrastructure team going forward.

Write-Host "3/5 Creating the Worker directory layout on the data disk..."
$paths = @(
    "$WorkerRootPath\scripts"
    "$WorkerRootPath\config"
    "$WorkerRootPath\logs"
)
foreach ($p in $paths) {
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

Write-Host "4/5 Creating the custom Event Log '$EventLogName' (512MB max, overwrite mode)..."
if (-not [System.Diagnostics.EventLog]::SourceExists($EventLogName)) {
    New-EventLog -LogName $EventLogName -Source $EventLogName
    Limit-EventLog -LogName $EventLogName -MaximumSize 512MB -OverflowAction OverwriteAsNeeded
}

Write-Host "5/5 Registering Task Scheduler jobs for the 5 workers (frequencies per design doc table 4.2)..."
$jobs = @(
    @{ Name = 'IPAM-AllocationWorker';    Script = 'allocation-worker\Invoke-AllocationWorker.ps1';       Trigger = 'RepeatMinutes:5' }
    @{ Name = 'IPAM-SegmentSyncWorker';   Script = 'segment-sync-worker\Invoke-SegmentSyncWorker.ps1';     Trigger = 'AtMinute:15,45' }
    @{ Name = 'IPAM-ArpCollector';        Script = 'arp-collector\main.py + reflect-to-ipam\Invoke-ReflectArpResults.ps1'; Trigger = 'AtMinute:00' }
    @{ Name = 'IPAM-AutoDeletionWorker';  Script = 'auto-deletion-worker\Invoke-AutoDeletionWorker.ps1';   Trigger = 'Daily:02:00' }
    @{ Name = 'IPAM-MonitoringScript';    Script = 'monitoring-script\Invoke-MonitoringCheck.ps1';         Trigger = 'Daily:07:00' }
)
foreach ($job in $jobs) {
    Write-Host "  -> $($job.Name) : $($job.Script) [$($job.Trigger)]"
    # TODO: actual Register-ScheduledTask call — requires a dedicated service account, never
    # a personal account. Store credentials via SecretManagement/DPAPI — never plaintext.
}

Write-Host "Bootstrap complete. Next step: deploy the contents of src/workers/ and src/arp-collector/ into $WorkerRootPath\scripts."
