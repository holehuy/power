param(
  [Parameter(Mandatory = $true)][string]$DomainName,
  [Parameter(Mandatory = $true)][string]$SafeModePassword
)

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

$secureSafeModePwd = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force

Install-ADDSForest `
  -DomainName $DomainName `
  -SafeModeAdministratorPassword $secureSafeModePwd `
  -InstallDns:$true `
  -NoRebootOnCompletion:$true `
  -Force:$true

# Install-ADDSForest with -NoRebootOnCompletion lets this script return success before the
# reboot happens, so the Run Command extension doesn't report failure due to the connection
# dropping mid-reboot. The scheduled reboot below finishes the promotion.
shutdown -r -t 60 -c "Rebooting to complete AD DS Forest promotion"
