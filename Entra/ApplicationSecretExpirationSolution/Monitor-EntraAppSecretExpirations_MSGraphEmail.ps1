#Connects to MSGraph to download all Entra Application information to find expired/expiring secrets.
#Emails an administrator (Set in command) or Application owner/s (From Application)
#Ingests list of expired/expiring secrets and email status to custom log in Log Analytics workspace
#Used as an Azure Automation Runbook or locally
#Chad Schultz https://github.com/itoleck/VariousScripts/tree/main/Azure/Entra

using namespace System.Collections.Generic

##requires -Modules Microsoft.Graph,Microsoft.Graph.Applications,Microsoft.Graph.Authentication

#Run in Azure Automation
# Param(
#     [Parameter(Mandatory=$false)][string] $MSGraphAppClientId = (Get-AutomationVariable -Name 'MSGraphAppClientId'),
#     [Parameter(Mandatory=$false)][string] $MSGraphAppTenantId = (Get-AutomationVariable -Name 'MSGraphAppTenantId'),
#     [Parameter(Mandatory=$false)][string] $MSGraphAppSecret = (Get-AutomationVariable -Name 'MSGraphAppSecret'),
#     [Parameter(Mandatory=$false)][string] $SendGridKey = (Get-AutomationVariable -Name 'SendGridKey'),
#     [Parameter(Mandatory=$false)][string] $EmailTo = (Get-AutomationVariable -Name 'EmailTo'),
#     [Parameter(Mandatory=$false)][string] $EmailFrom = (Get-AutomationVariable -Name 'EmailFrom'),
#     [Parameter(Mandatory=$false)][string[]] $AppIdsToMonitor,
#     [Parameter(Mandatory=$true)][ValidateRange(1, 365)][UInt16] $DaysUntilExpiration,
#     [Parameter(Mandatory=$false)][string] $NoSend,
#     [Parameter(Mandatory=$false)][string] $OnePage
# )
###

#Run locally
Param(
    [Parameter(Mandatory=$true)][string] $MSGraphAppClientId,
    [Parameter(Mandatory=$true)][string] $MSGraphAppTenantId,
    [Parameter(Mandatory=$true)][string] $MSGraphAppSecret,
    [Parameter(Mandatory=$true)][string] $SendGridKey,
    [Parameter(Mandatory=$true)][string] $EmailTo,
    [Parameter(Mandatory=$true)][string] $EmailFrom,
    [Parameter(Mandatory=$false)][string[]] $AppIdsToMonitor,
    [Parameter(Mandatory=$false)][ValidateRange(1, 365)][UInt16] $DaysUntilExpiration,
    [Parameter(Mandatory=$false)][string] $NoSend,
    [Parameter(Mandatory=$false)][string] $OnePage
)
###

#Globals
$global:MSGraphUri = 'https://graph.microsoft.com/'
$global:MSGraphToken = ''
$global:EntraAppUri = 'https://graph.microsoft.com/v1.0/applications?$select=id,appId,displayName,keyCredentials,passwordCredentials&$top=250'  #Find better query to find only apps with secrets or certs
    #Test Queries
    #Error - https://graph.microsoft.com/v1.0/applications?$filter=keyCredentials/any(c:c ne 0)&$top=1
    #Error - https://graph.microsoft.com/v1.0/applications?$filter=keyCredentials/endDateTime/any(k:k gt '2022/01/01')$top=1
    #Filtering in MSGraph not possible at this time per, https://learn.microsoft.com/en-us/graph/aad-advanced-queries?view=graph-rest-1.0&tabs=http#application-properties
$global:BearerTokenHeader = ''
$global:SecretApps = New-Object System.Collections.ArrayList
$global:TrackLimitErrors = 0
$global:TotalAppsProcessed = 0

$stopwatch = [system.diagnostics.stopwatch]::StartNew()

Class SecretApp
{
    [string]$App_Name
    [string]$App_AppId
    [string]$App_InternalId

    [string]$Secret_DisplayName
    [string]$Secret_EndDateTime
    [int]$Secret_DaysUntilExpiration
    [string]$Secret_StartDateTime
}

Function Get-MSGraphToken {
    #Get the token for the Application used for solution with Application.Read.All & Directory.Read.All scope API permissions
    $MSGraphAuthUri = "https://login.windows.net/$MSGraphAppTenantId/oauth2/token"
    $MSGraphAuthBody = [Ordered] @{
        resource      = $global:MSGraphUri
        client_id     = $MSGraphAppClientId
        client_secret = $MSGraphAppSecret
        grant_type    = 'client_credentials'
        #ConsistencyLevel = 'eventual'  #Needed in MSGraph advanced queries; https://learn.microsoft.com/en-us/graph/aad-advanced-queries?tabs=http
    }
    Write-Verbose "Getting Graph API token for tenant $($MSGraphAuthUri)"
    Write-Verbose $MSGraphAuthBody

    try {
        $MSGraphAuthResponse = Invoke-RestMethod -Method Post -Uri $MSGraphAuthUri -Body $MSGraphAuthBody -ErrorAction Stop
    }
    catch {
        Write-Verbose "Error getting MSGraph token"
        Write-Verbose $MSGraphAuthResponse
    }
    $global:MSGraphToken = $MSGraphAuthResponse.access_token
}

Function Add-App($app, $secret) {
    $secapp = New-Object SecretApp
    $secapp.App_Name = $app.displayName
    $secapp.App_AppId = $app.appId
    $secapp.App_InternalId = $app.id    #Needed for app owner query
    $secapp.Secret_DisplayName = $secret.displayName
    $secapp.Secret_EndDateTime = $secret.endDateTime

    $secapp.Secret_DaysUntilExpiration = ([DateTime]($secret.endDateTime) - [DateTime](Get-Date)).Days
    $secapp.Secret_StartDateTime = $secret.startDateTime

    $null = $global:SecretApps.Add($secapp)
    Write-Debug "Processing app: $($app.displayName)"
}

Function Get-GraphAppPageItems($apps) {

    ForEach ($app in $apps) {

        #Check if the script is monitoring a set of Apps and if the appId is in the list
        If ($global:AppIdsToMontior.count -gt 0) {
            If ($global:AppIdsToMontior.Contains($app.appId) ) {
                Write-Verbose "Monitored app, checking expirations: $($app.appId), $($app.displayName), $($app.keyCredentials), $($app.passwordCredentials)"
                ForEach ($c in $app.keyCredentials) {
                    If ( $c.endDateTime -lt ( (Get-Date).AddDays($DaysUntilExpiration) ) ) {
                        Add-App $app $c
                    }
                }
                ForEach ($p in $app.passwordCredentials) {
                    If ( $p.endDateTime -lt ( (Get-Date).AddDays($DaysUntilExpiration) ) ) {
                        Add-App $app $p
                    }
                }
            }
        } else {    #Not processing appIds so add any apps that have old secrets
            Write-Verbose "Checking app expirations: $($app.appId), $($app.displayName), $($app.keyCredentials), $($app.passwordCredentials)"
            ForEach ($c in $app.keyCredentials) {
                If ( $c.endDateTime -lt ( (Get-Date).AddDays($DaysUntilExpiration) ) ) {    #Fix - Did not catch app with expired cert, this is when running in PS5.1, ISO date format does not match .Net, need to fix.
                    Add-App $app $c
                }
            }
            ForEach ($p in $app.passwordCredentials) {
                If ( $p.endDateTime -lt ( (Get-Date).AddDays($DaysUntilExpiration) ) ) {
                    Add-App $app $p
                }
            }
        }
    }
}

Function Send-Email {

    $secureString = New-Object System.Security.SecureString
    foreach ($char in $global:MSGraphToken.ToCharArray()) {
        $secureString.AppendChar($char)
    }

    Connect-MgGraph -AccessToken $secureString

    $head = "<style>table, th, td { border: 1px solid; padding: 5px; }</style><script>window.onload=function() {document.querySelectorAll('tr').forEach((tr, rowIndex) => {tr.querySelectorAll('td').forEach((td, colIndex) => {td.id = 'row-' + rowIndex + '-col-' + colIndex;if (!isNaN(td.innerHTML) && parseInt(td.innerHTML, 10) < 180) {td.style.backgroundColor = 'green';}if (!isNaN(td.innerHTML) && parseInt(td.innerHTML, 10) < 90) {td.style.backgroundColor = 'yellow';}if (!isNaN(td.innerHTML) && parseInt(td.innerHTML, 10) < 30) {td.style.backgroundColor = 'red';}});});};</script>"
    $title = "Entra ID Applications with Expired/Expiring Secrets"
    $body = [string]($global:SecretApps|convertTo-Html -Head $head -Title $title -PreContent "<h2>$title</h2>")
    
    $MessageBody = @{
        content = "$($body)"
        ContentType = 'html'
    }
    $EmailRecipient = @{emailAddress = @{address = $EmailTo} }
    $NewEmail = New-MgUserMessage -UserId $EmailFrom -Body $MessageBody -ToRecipients $EmailRecipient -Subject "Expiring Entra ID Applications"
    Send-MgUserMessage -UserId $EmailAddress -MessageId $NewEmail.Id
}

#START
$pagenum = 1
#First get the MSGraph token for access the Entra Application list
Get-MSGraphToken
Write-Verbose "MSGraph token"
Write-Verbose $global:MSGraphToken

#Get first page of Entra Applications based on MSGraph query
$global:BearerTokenHeader = @{
    Authorization = "Bearer $global:MSGraphToken"
}

$response = Invoke-WebRequest -Method Get -Uri $global:EntraAppUri -Headers $global:BearerTokenHeader -UseBasicParsing -ContentType 'application/json'
$global:rjson = $response | ConvertFrom-Json
$global:TotalAppsProcessed = $global:TotalAppsProcessed + $global:rjson.value.count
$appsinpagetoprocess = $global:rjson.value | where-Object( { ($_.keyCredentials.Count -gt 0) -or ($_.passwordCredentials.Count -gt 0) } )

#Get the properties of each app in the first MSGraph query page
Write-Verbose "Processing first page of results"
Get-GraphAppPageItems $appsinpagetoprocess

#Cycle through remaining pages
if ([string]::IsNullOrEmpty($OnePage)) {
    do {
        $pagenum = $pagenum + 1
        $response = Invoke-WebRequest -Method Get -Uri $global:rjson.'@odata.nextLink' -Headers $global:BearerTokenHeader -UseBasicParsing -ContentType 'application/json'
        $global:rjson = $response | ConvertFrom-Json
        $global:TotalAppsProcessed = $global:TotalAppsProcessed + $global:rjson.value.count
        $appsinpagetoprocess = $global:rjson.value | where-Object( { ($_.keyCredentials.Count -gt 0) -or ($_.passwordCredentials.Count -gt 0) } )

            #Throttle based on recommended time in 429 HTTP status
            If ($response.StatusCode -eq 429) {
                $global:TrackLimitErrors =+ 1
                Write-Output $response.Headers
                Start-Sleep -Seconds 30
            }

        #Add some time so that the MSGraph query quota does not trigger
        Start-Sleep -Seconds 1
        
        #Get each page of apps and process
        Write-Verbose "Processing page $pagenum of results"
        Get-GraphAppPageItems $appsinpagetoprocess

    } while (
        #Stop when the there is not a @odata.nextLink URL in the .json body
        ($global:rjson.'@odata.nextLink').Length -gt 0
    )
}

Write-Output "Apps List: $AppIdsToMontior"
Write-Output "Day until expiration: $DaysUntilExpiration"
Write-Output "$global:TotalAppsProcessed apps processed"
Write-Output "$($global:SecretApps.Count) apps in list"
Write-Output "`n`rUse global variable `$global:SecretApps for app list"
$global:SecretApps | Format-Table -AutoSize

Send-Email

#Track duration of script
Write-Output $stopwatch.Elapsed
$stopwatch.Stop()