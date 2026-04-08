param(
    [Parameter(Mandatory=$true)][string] $Location,
    [Parameter(Mandatory=$true)][string] $Name,
    [Parameter(Mandatory=$true)][string] $KVPrincipal,
    [Parameter(Mandatory=$true)][string] $LogicAppName
)

New-AzSubscriptionDeployment `
    -Name $Name `
    -TemplateFile .\main.bicep `
    -Location $Location `
    -KVPrincipal $KVPrincipal `
    -LogicAppName $LogicAppName