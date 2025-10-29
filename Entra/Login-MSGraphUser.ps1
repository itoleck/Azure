#https://learn.microsoft.com/en-us/graph/api/application-list?view=graph-rest-1.0&tabs=http

#Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
#Import-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "User.Read", "User.Read.All", "Application.Read.All", "Directory.Read.All"
$ctx = Get-MgContext
#$ctx
#$ctx.Scopes
#Invoke-MgGraphRequest -Method GET 'https://graph.microsoft.com/v1.0/me'
$res = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/applications/?$top=2' #-Headers @{ ConsistencyLevel = 'eventual'; Prefer = 'odata.maxpagesize=10'; 'Content-Type' = 'application/json' }
#$res.Values.Values
$objects = $res.Values | ForEach-Object { [PSCustomObject]$_}
$objects[0].passwordCredentials
Disconnect-MgGraph