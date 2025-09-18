$params = @{
    Name='TimeZone'
    Configuration='.\localhost.mof'
    Type='AuditandSet'
    Force=$true
}
New-GuestConfigurationPackage @params   # Creates TimeZone.zip, upload to storage and use in deploypolicy.ps1