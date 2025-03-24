

Param(
    [Parameter(Mandatory=$true)][string] $resourceGroupName = '',
    [Parameter(Mandatory=$true)][string] $AppGWName = ''
)

$AppGW = Get-AzApplicationGateway -ResourceGroupName $resourceGroupName -Name $AppGWName
$BackendPools = Get-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGW

function AzLogin {
    $context = Get-AzContext
    if (!$context) {
        Add-AzAccount -UseDeviceAuthentication
        Set-AzContext
    }
    Write-Output $context
}

function addAppGWConfig {
    $Script:mermaid += "AppGW[Application Gateway:<br />$($AppGW.Name)<br />$($AppGW.Sku.Tier)<br />$http2<br />$fips<br />$zones<br />$($AppGW.OperationalState)<br />$($AppGW.ProvisioningState)] --> AppGWPublic;`n"
    $Script:mermaid += "AppGW[Application Gateway:<br />$($AppGW.Name)<br />$($AppGW.Sku.Tier)<br />$http2<br />$fips<br />$zones<br />$($AppGW.OperationalState)<br />$($AppGW.ProvisioningState)] --> AppGWPrivate;`n"
}

function addFrontendConfig {
    $public = $AppGW.FrontendIPConfigurations.Name[0] + "`n" + $AppGW.FrontendPorts.Port
    $private = $AppGW.FrontendIPConfigurations.Name[1] + "`n" + $AppGW.FrontendPorts.Port
    $Script:mermaid += "AppGWPublic[Public<br />$public] --> AppGWListeners[Listeners];`n"
    $Script:mermaid += "AppGWPrivate[Private<br />$private] --> AppGWListeners[Listeners];`n"
}

function addListenerConfig {
    foreach($listener in $AppGW.HttpListeners){
        $cert = $listener.SslCertificate.Id.Split("/")[-1]
        $Script:mermaid += "AppGWListeners[Listeners] --> $($listener.Name)[$($listener.Name)<br />Protocol: $($listener.Protocol)<br />Hostname/s: $($listener.HostName)<br />$($listener.HostNames)<br />Certificate: $cert<br />Provisioning: $($listener.ProvisioningState)];`n"
    }
}

function addRulesConfig {
    foreach($rule in $AppGW.RequestRoutingRules){
        $Script:mermaid += "$($rule.HttpListener.Id.Split("/")[-1]) --> $($rule.Name)[$($rule.Name)<br />$($rule.RuleType)<br />$($rule.Priority)];`n"
    }
}

AzLogin

$Script:mermaid = "``````` mermaid <!-- Remove this line if importing to Drawio -->`n"
$Script:mermaid += "---`n"
$Script:mermaid += "Title: Application Gateway Topology`n"
$Script:mermaid += "---`n"
$Script:mermaid += "flowchart TD;`n"
$Script:mermaid += "RG[Resource Group:<br />$($AppGW.resourceGroupName)] --> Loc;`n"
$Script:mermaid += "Loc[Location:<br />$($AppGW.Location)] --> AppGW;`n"
$http2 = "HTTP2: False";if ($AppGW.EnableHttp2){$http2 = "HTTP2: True"}
$fips = "FIPS: False";if ($AppGW.EnableFips){$fips = "FIPS: True"}
$zones = "Zones: False";if ($AppGW.Zones){$zones = "Zones: True"}
addAppGWConfig
addFrontendConfig
addListenerConfig
addRulesConfig
$Script:mermaid += "`n"

Write-Output $Script:mermaid
