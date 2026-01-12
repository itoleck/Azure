param (
    [String]$TenantId = "",
    [String]$SubscriptionId = ""
)

#login to Azure
Add-AzAccount

#Set the context to the subscription
Set-AzContext -SubscriptionId $SubscriptionId

#Get the token for MS Graph
$token = (Get-AzAccessToken -ResourceUrl "https://login.windows.net/$TenantId/oauth2/token").Token

#Convert the secure string to plain text
$plainToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))

#Prepare the header for the REST call
$tokenHeader = @{Authorization = "Bearer $plaintoken"}

#Make the REST call to get the applications
$res=Invoke-WebRequest -Method Get -Uri 'https://graph.microsoft.com/v1.0/applications?$top=10' -Headers $tokenHeader -UseBasicParsing -ContentType 'application/json'

#Gets error, Authentication failed against resource https://login.windows.net/<tokenid>/oauth2/token. User interaction is required. This may be due to the conditional access policy settings such as
# | multi-factor authentication (MFA). Please rerun 'Connect-AzAccount' with additional parameter '-AuthScope https://login.windows.net/<tenantid>/oauth2/token'.
# Do not believe that user login can be used

#Alternative way to get token using SPN
#curl --location 'https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/token' \
#--header 'Content-Type: application/x-www-form-urlencoded' \
#--data-urlencode 'client_id=<your-client-id>' \
#--data-urlencode 'client_secret=<your-client-secret>' \
#--data-urlencode 'grant_type=client_credentials' \
#--data-urlencode 'scope=https://graph.microsoft.com/.default'


