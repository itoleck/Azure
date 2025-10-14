$params = @{
    Name='SetRepoUbuntu2204'
    Configuration='.\localhost.mof'
    Type='AuditandSet'
    Force=$true
}
New-GuestConfigurationPackage @params   # Creates SetRepoUbuntu2204.zip, upload to storage and use in deploypolicy.ps1