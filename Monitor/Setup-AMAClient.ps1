param (
    [Parameter(Mandatory=$true)][string] $TenantID,
    [Parameter(Mandatory=$true)][string] $SubscriptionID,
    [Parameter(Mandatory=$true)][string] $Location,
    [Parameter(Mandatory=$true)][string] $ResouceGroup,
    [Parameter(Mandatory=$true)][string] $DCRName
)

#Get Token
Connect-AzAccount -Tenant $TenantID
Select-AzSubscription -SubscriptionId $SubscriptionID

$auth = Get-AzAccessToken
$AuthenticationHeader = @{
    "Content-Type" = "application/json"
    "Authorization" = "$($auth.Type) " + $auth.Token
}

#Create Management Object, need Monitored Object Contributor role
$request = "https://management.azure.com/providers/Microsoft.Insights/monitoredObjects/$TenantID`?api-version=2021-09-01-preview"
$body = "{ ""properties"":{ ""location"":""$Location"" } }"
Invoke-RestMethod -Uri $request -Headers $AuthenticationHeader -Method PUT -Body $body -Verbose

#Associate DCR to Management Object
$request = "https://management.azure.com$RespondId/providers/microsoft.insights/datacollectionruleassociations/assoc?api-version=2021-04-01"
$body = @"
{
    "properties": {
        "dataCollectionRuleId": "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionRules/$DCRName"
    }
}
"@

Invoke-RestMethod -Uri $request -Headers $AuthenticationHeader -Method PUT -Body $body