param
(
    [Parameter(ValuefromPipeline=$true)] [string]$DomainName ="intuit.test",
    [Parameter(ValuefromPipeline=$true)] [string]$AdmincredsUserName ="adminuser",
    [Parameter(ValuefromPipeline=$true)] [string]$AdmincredsPassword ="P@ssw0rd!"
)

$username = $AdmincredsUserName
$password = ConvertTo-SecureString -AsPlainText $AdmincredsPassword -Force
$Cred = New-Object System.Management.Automation.PSCredential ($username, $password)

install-windowsfeature AD-Domain-Services,DNS, RSAT-DNS-Server -IncludeManagementTools

try {
    Test-ADDSForestInstallation -DomainName $DomainName -DomainMode 7 -ForestMode 7 -NoRebootOnCompletion

}catch{
    Write-Host $Error[0].Exception
    exit 1
}

Install-ADDSForest `
-DomainName $DomainName `
-SafeModeAdministratorPassword $AdmincredsPassword `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true