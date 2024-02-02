#Use this to get a token based on the a principal.
#Copy bearer token to Postman or other REST requests.

Param(
    [Parameter(Mandatory=$false)][string] $clientid = '',
    [Parameter(Mandatory=$false)][string] $tenantid = '',
    [Parameter(Mandatory=$false)][string] $secret = ''
)

#Graph resource URIs
$resourceGraphUri = 'https://graph.microsoft.com/'
$oAuthUri = "https://login.windows.net/$tenantid/oauth2/token"

$authBody = [Ordered] @{
    resource      = $resourceGraphUri
    client_id     = $clientid
    client_secret = $secret
    grant_type    = 'client_credentials'
}

Write-Verbose "Getting Graph API token for tenant $($tenantid)"
$authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
$token = $authResponse.access_token
Write-Output "Copying $token to clipboard"
$token | Set-Clipboard

