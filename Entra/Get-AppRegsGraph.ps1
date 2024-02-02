#requires -Modules Microsoft.Graph,Microsoft.Graph.Applications,Microsoft.Graph.Authentication

Param(
    [Parameter(Mandatory=$true)][string] $ClientId,
    [Parameter(Mandatory=$true)][string] $TenantId,
    [Parameter(Mandatory=$false)][string] $CertificateThumbprint,
    [Parameter(Mandatory=$false)][bool] $UseAppAuth
)

#Using the requires IfDef above
#Use MSGraph PowerShell
#if (-not(Get-Module -ListAvailable -Name 'Microsoft.Graph')) {
#    install-Module Microsoft.Graph -Scope CurrentUser
#    import-Module Microsoft.Graph -Scope Local
#}

if (!$UseAppAuth) {
    $azCtx = Get-AzContext
    if (!$azCtx) {
        Add-AzAccount
    }
    #Create a new App Registration in the Azure Portal
    #Give Application.Read.All API permission, give admin consent
    #Use clientId and tenantId to connect to MSGraph
    $graphScopes = "Application.Read.All"
    Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -Scopes $graphScopes
} else {
    #If using runbook you will need to use auth that does not have interaction (App based auth)
    #The machine running the script needs to have the certificate installed in the account store that is running the script and the thumbprint needs to be the same as the certificate in the Application
    Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint
}

$ctx = Get-MgContext
$ctx
#(Get-MgApplication -All).Count
$apps = Get-MgApplication -All
ForEach ($app in $apps) {
    Write-Output $app.Id
}