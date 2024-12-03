#This script will create how many Entra ID Application Registrations as you ask for
#Chad Schultz https://github.com/itoleck/VariousScripts/tree/main/Azure/Entra

Param(
    [Parameter(Mandatory=$false)][int] $numapps
)

for (($i = 1); $i -lt $numapps; $i++) {
    az ad app create --display-name AppTest$i
    Write-Output "AppTest$i"
    Start-Sleep -Seconds 1
}