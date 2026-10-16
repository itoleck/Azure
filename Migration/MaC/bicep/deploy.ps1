#Requires -Modules Az.Resources

<#
.SYNOPSIS
Creates an Azure Migrate project with public or private connectivity.
.DESCRIPTION
Deploys migrate.bicep at subscription scope using the current Azure PowerShell
context. Private connectivity requires an existing subnet and creates a private
endpoint, private DNS zone, and virtual network link.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Location,

    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[a-zA-Z0-9-]{3,24}$')]
    [string] $Name,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1, 90)]
    [string] $ResourceGroupName,

    [ValidateSet('Public', 'Private')]
    [string] $Connectivity = 'Public',

    [ValidatePattern('^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\.Network/virtualNetworks/[^/]+/subnets/[^/]+$')]
    [string] $PrivateEndpointSubnetId
)

if ($Connectivity -eq 'Private' -and [string]::IsNullOrWhiteSpace($PrivateEndpointSubnetId)) {
    throw 'PrivateEndpointSubnetId is required for Private connectivity.'
}

if ($Connectivity -eq 'Public' -and -not [string]::IsNullOrWhiteSpace($PrivateEndpointSubnetId)) {
    throw 'PrivateEndpointSubnetId can only be specified with Private connectivity.'
}

$templateParameters = @{
    name = $Name
    resourceGroupName = $ResourceGroupName
    location = $Location
    connectivity = if ($Connectivity -eq 'Private') { 'Private' } else { 'Public' }
    privateEndpointSubnetId = if ($Connectivity -eq 'Private') { $PrivateEndpointSubnetId } else { '' }
}

New-AzSubscriptionDeployment `
    -Name "${Name}-deployment" `
    -TemplateFile (Join-Path $PSScriptRoot 'migrate.bicep') `
    -Location $Location `
    -TemplateParameterObject $templateParameters `
    -ErrorAction Stop