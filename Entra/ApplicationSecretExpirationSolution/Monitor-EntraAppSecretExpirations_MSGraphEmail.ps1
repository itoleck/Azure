#Connects to MSGraph to download all Entra Application information to find expired/expiring secrets.
#Emails an administrator (Set in command) or Application owner/s (From Application)
#Ingests list of expired/expiring secrets and email status to custom log in Log Analytics workspace
#Used as an Azure Automation Runbook or locally
#Chad Schultz https://github.com/itoleck/VariousScripts/tree/main/Azure/Entra

##requires -Modules Microsoft.Graph,Microsoft.Graph.Applications,Microsoft.Graph.Authentication,Microsoft.Graph.Mail

#Run in Azure Automation
# Param(
#     [Parameter(Mandatory=$false)][string] $MSGraphAppClientId = (Get-AutomationVariable -Name 'MSGraphAppClientId'),
#     [Parameter(Mandatory=$false)][string] $MSGraphAppTenantId = (Get-AutomationVariable -Name 'MSGraphAppTenantId'),
#     [Parameter(Mandatory=$false)][string] $MSGraphAppSecret = (Get-AutomationVariable -Name 'MSGraphAppSecret'),
#     [Parameter(Mandatory=$false)][string] $EmailTo = (Get-AutomationVariable -Name 'EmailTo'),
#     [Parameter(Mandatory=$false)][string] $EmailFrom = (Get-AutomationVariable -Name 'EmailFrom'),
#     [Parameter(Mandatory=$false)][string[]] $AppIdsToMontior,
#     [Parameter(Mandatory=$false)][ValidateRange(1, 365)][UInt16] $DaysUntilExpiration
# )
###

#Run locally
Param(
    [Parameter(Mandatory=$true)][string] $MSGraphAppClientId,
    [Parameter(Mandatory=$true)][string] $MSGraphAppTenantId,
    [Parameter(Mandatory=$true)][string] $MSGraphAppSecret,
    [Parameter(Mandatory=$true)][string] $EmailTo,
    [Parameter(Mandatory=$true)][string] $EmailFrom,
    [Parameter(Mandatory=$false)][string[]] $AppIdsToMontior,
    [Parameter(Mandatory=$false)][ValidateRange(1, 365)][UInt16] $DaysUntilExpiration
)
###

#Globals
$global:MSGraphUri = 'https://graph.microsoft.com/'
$global:MSGraphToken = ''
$global:EntraAppUri = 'https://graph.microsoft.com/v1.0/applications?$select=id,appId,displayName,keyCredentials,passwordCredentials&$top=250'  #Find better query to find only apps with secrets or certs
    #Test Queries
    #Error - https://graph.microsoft.com/v1.0/applications?$filter=keyCredentials/any(c:c ne 0)&$top=1
    #Error - https://graph.microsoft.com/v1.0/applications?filter=keyCredentials/endDateTime/any(k:k gt '2022/01/01')$top=1
    #
    #
    #
    #
$global:BearerTokenHeader = ''
$global:SecretApps = New-Object System.Collections.ArrayList
$global:TrackLimitErrors = 0
$global:TotalAppsProcessed = 0

$TotalTicks = 0
$stopwatch = [system.diagnostics.stopwatch]::StartNew()

Class SecretApp
{
  [string]$Name
  [string]$AppId
  [string]$InternalId
  [object]$Secrets
  [object]$Certs
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
    if ($WriteVerboseLog) {
        $MSGraphAuthBody
    }
    try {
        $MSGraphAuthResponse = Invoke-RestMethod -Method Post -Uri $MSGraphAuthUri -Body $MSGraphAuthBody -ErrorAction Stop
    }
    catch {
        Write-Verbose "Error getting MSGraph token"
        Write-Verbose $MSGraphAuthResponse
    }
    $global:MSGraphToken = $MSGraphAuthResponse.access_token
}

Function Get-GraphAppPageItems($apps) {

    ForEach ($app in $apps) {

        $AddApp = $false

        #Check if the script is monitoring a set of Apps and if the appId is in the list
        If ($global:AppIdsToMontior.count -gt 0) {
            If ($global:AppIdsToMontior.Contains($app.appId) ) {
                ForEach ($c in $app.keyCredentials) {
                    If ( $c.endDateTime -lt ( (Get-Date).AddDays($DaysUntilExpiration) ) ) {
                        $AddApp = $true
                    }
                }
                ForEach ($p in $app.passwordCredentials) {
                    If ( $p.endDateTime -lt ( (Get-Date).AddDays($DaysUntilExpiration) ) ) {
                        $AddApp = $true
                    }
                }
            }
        } else {    #Not processing appIds so add any apps that have old secrets
            ForEach ($c in $app.keyCredentials) {
                If ( $c.endDateTime -lt ( (Get-Date).AddDays($DaysUntilExpiration) ) ) {    #Fix - Did not catch app with expired cert
                    $AddApp = $true
                }
            }
            ForEach ($p in $app.passwordCredentials) {
                If ( $p.endDateTime -lt ( (Get-Date).AddDays($DaysUntilExpiration) ) ) {
                    $AddApp = $true
                }
            }
        }

        If ($AddApp) {
            $secapp = New-Object SecretApp
            $secapp.Name = $app.displayName
            $secapp.AppId = $app.appId
            $secapp.InternalId = $app.id    #Needed for app owner query
            $secapp.Secrets = ($app.keyCredentials | ConvertTo-Json)
            $secapp.Certs = ($app.passwordCredentials | ConvertTo-Json)
            $null = $global:SecretApps.Add($secapp)
        }

        #if ($WriteVerboseLog) { $global:SecretApps }   #working, not needed
        Write-Verbose "Processing app: $($app.displayName)"
    }
}

Function Send-Email {

    $secureString = New-Object System.Security.SecureString
    foreach ($char in $global:MSGraphToken.ToCharArray()) {
        $secureString.AppendChar($char)
    }

    Connect-MgGraph -AccessToken $secureString



    $body = '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Expired/Expiring Application Secrets</title></head><body><table style="padding: 10px;border: 1px solid black;border-collapse: collapse;table-layout:fixed;width: 100%;">'
    $body = $body + ('<tr style="background-color:808080;border-bottom: 1px solid black;"><td style="padding: 10px;width: 300px;overflow: hidden;"><b>Application(SPN) Name</b></td><td style="padding: 10px;width: 300px;overflow: hidden;"><b>Application ID</b></td><td style="padding: 10px;width: 300px;overflow: hidden;"><b>Expiring/Expired Secrets</b></td><td style="padding: 10px;width: 300px;overflow: hidden;"><b>Expiring/Expired Certificates</b></td></tr>')
    ForEach($app in $global:SecretApps) {
        $secrets = ''
        $certs = ''
        $body = $body + ("<tr><td style='padding: 10px;width: 300px;overflow: hidden;'>{0}</td>" -f ($app.Name))
        $body = $body + ("<td style='padding: 10px;width: 300px;overflow: hidden;'>{0}</td>" -f ($app.AppId))

        If (!($null -eq $app.Secrets)) {
            $split = $app.Secrets.split(',')
            ForEach($lit in $split) {
                If (($lit|Select-String -Pattern 'displayName' -SimpleMatch).Length -gt 0 -or ($lit|Select-String -Pattern 'endDateTime' -SimpleMatch).Length -gt 0) {
                    $secrets = $secrets + $lit.replace('"','').replace('{','').replace('}','')
                }
            }
            #$secrets = ($app.Secrets | Out-String -Stream | Select-String -Pattern 'displayName' -SimpleMatch -Raw)
            #$secrets = $secrets + ($app.Secrets | Out-String -Stream | Select-String -Pattern 'endDateTime' -SimpleMatch -Raw)
            $body = $body + ("<td style='padding: 10px;width: 300px;overflow: hidden;'>{0}</td>" -f $secrets)
        }
        If (!($null -eq $app.Certs)) {
            $split = $app.Certs.split(',')
            ForEach($lit in $split) {
                If (($lit|Select-String -Pattern 'displayName' -SimpleMatch).Length -gt 0 -or ($lit|Select-String -Pattern 'endDateTime' -SimpleMatch).Length -gt 0) {
                    $certs = $certs + $lit.replace('"','').replace('{','').replace('}','')
                }
            }
            #$certs = ($app.Certs | Select-String -Pattern 'displayName' -SimpleMatch)
            #$certs = $certs + ($app.Certs | Out-String -Stream | Select-String -Pattern 'endDateTime' -SimpleMatch -Raw)
            $body = $body + ("<td style='padding: 10px;width: 300px;overflow: hidden;'>{0}</td></tr>" -f $certs)
        }
        #$body = $body + "`n"
    }
    $body = $body + ("</table></body></html>")
    #$body = $body.replace('"','').replace('{','').replace('}','')

    # $headers = @{}
    # $headers.Add("Authorization","Bearer $SendGridKey")
    # $headers.Add("Content-Type", "application/json")
 
    # $jsonRequest = [ordered]@{
    #                         personalizations= @(@{to = @(@{email =  "$EmailTo"})
    #                             subject = "Expiring Entra ID Applications" })
    #                             from = @{email = "$EmailFrom"}
    #                             content = @( @{ type = "text/html"
    #                                         value = "$body" }
    #                             )} | ConvertTo-Json -Depth 10
    #$rest = Invoke-RestMethod -Uri "https://api.sendgrid.com/v3/mail/send" -Method Post -Headers $headers -Body $jsonRequest 
    #$body
    $MessageBody = @{
        content = "$($body)"
        ContentType = 'html'
    }
    $EmailAddress  = @{address = $EmailFrom} 
    $EmailRecipient = @{EmailAddress = $EmailTo}
    $NewEmail = New-MgUserMessage -UserId $EmailAddress -Body $MessageBody -ToRecipients $EmailRecipient -Subject "Expiring Entra ID Applications"
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

Write-Output "Apps List: $AppIdsToMontior"
Write-Output "Day until expiration: $DaysUntilExpiration"
Write-Output "$global:TotalAppsProcessed apps processed"
Write-Output "$($global:SecretApps.Count) apps in list"

$global:SecretApps

Send-Email

#Track duration of script
$stopwatch.Elapsed
$stopwatch.Stop()