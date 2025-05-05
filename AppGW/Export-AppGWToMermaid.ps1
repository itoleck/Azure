

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

function addIcons {
    $Script:mermaid += 'RG@{ icon: "azure:resource-groups", pos: "b"};'
    $Script:mermaid += 'AppGW@{ icon: "azure:application-gateways", pos: "b"};'
    $Script:mermaid += 'Loc@{ icon: "azure:location", pos: "b"};'
}

function addAppGWConfig {
    $Script:mermaid += "AppGW[Application Gateway:<br />$($AppGW.Name)<br />$($AppGW.Sku.Tier)<br />$http2<br />$fips<br />$zones<br />$($AppGW.OperationalState)<br />$($AppGW.ProvisioningState)] --> AppGWPublic;`n"
    $Script:mermaid += "AppGW[Application Gateway:<br />$($AppGW.Name)<br />$($AppGW.Sku.Tier)<br />$http2<br />$fips<br />$zones<br />$($AppGW.OperationalState)<br />$($AppGW.ProvisioningState)] --> AppGWPrivate;`n"
}

function addFrontendConfig {
    $public = $AppGW.FrontendIPConfigurations.Name[0] + "<br />" + $AppGW.FrontendPorts.Port
    $private = $AppGW.FrontendIPConfigurations.Name[1] + "<br />" + $AppGW.FrontendPorts.Port
    $Script:mermaid += "AppGWPublic[Public<br />$public] --> AppGWListeners[Listeners];`n"
    $Script:mermaid += "AppGWPrivate[Private<br />$private] --> AppGWListeners[Listeners];`n"
}

function addListenerConfig {
    foreach($listener in $AppGW.HttpListeners){
        $cert = $listener.SslCertificate.Id.Split("/")[-1]
        $Script:mermaid += "AppGWListeners[Listeners] --> $($listener.Name){{$($listener.Name)<br />Protocol: $($listener.Protocol)<br />Hostname/s: $($listener.HostName)<br />$($listener.HostNames)<br />Certificate: $cert<br />Provisioning: $($listener.ProvisioningState)}};`n"
    }
}

function addRulesConfig {
    $redirect = ""

    foreach($rule in $AppGW.RequestRoutingRules){
        if ($rule.RedirectConfiguration.Id.Length -gt 0) {
            $redirect = "$($rule.RedirectConfiguration.Id.Split("/")[-1])"
            $Script:mermaid += "$($rule.HttpListener.Id.Split("/")[-1]) --> $($rule.Name)[$($rule.Name)<br />Type: $($rule.RuleType)<br />Priority: $($rule.Priority)<br />Redirect: $redirect];`n"
            $Script:mermaid += "$($rule.Name) --> redirectConfigurations$redirect[$redirect];`n"

            $redirectConfig = $AppGW.RedirectConfigurations | Where-Object {$_.Id -eq $rule.RedirectConfiguration.Id}
            $targetListener = $redirectConfig.TargetListener.Id.Split("/")[-1]
            if ($targetListener.Length -eq 0) {
                $targetListener = $redirectConfig.TargetUrl
            }
            $Script:mermaid += "redirectConfigurations$redirect[$redirect] --> $targetListener;`n"
        } else {
            $Script:mermaid += "$($rule.HttpListener.Id.Split("/")[-1]) --> $($rule.Name)[$($rule.Name)<br />Type: $($rule.RuleType)<br />Priority: $($rule.Priority)<br />$($rule.BackendHttpSettings.Id.Split("/")[-1])];`n"
            foreach($beSetting in $AppGW.BackendHttpSettingsCollection){
                $Script:mermaid += "$($beSetting.Name)([$($beSetting.Name)<br />Port: $($beSetting.Port)<br />Protocol: $($beSetting.Protocol)<br />CookieBasedAffinity: $($beSetting.CookieBasedAffinity)<br />$($beSetting.ProvisioningState)]) --> $($rule.Name)[$($rule.Name)];`n"
                
                if ($beSetting.Probe.Id.Length -gt 0) {
                    $probe = $AppGW.Probes | Where-Object {$_.Id -eq $beSetting.Probe.Id}
                    $Script:mermaid += "$($probe.Name) -->|$($rule.Name)| $($beSetting.Name);`n"
                } else {
                    $Script:mermaid += "Probe[Default Probe] -->|$($rule.Name)| $($beSetting.Name);`n"
                }
            }
            foreach($bePool in $AppGW.BackendAddressPools){
                $Script:mermaid += "$($bePool.Name)>$($bePool.Name)<br />$($bePool.BackendAddresses)<br />$($bePool.BackendIpConfigurations.Id)] --> $($rule.Name)[$($rule.Name)];`n"
            }
        }
        $redirect = ""
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

addIcons
addAppGWConfig
addFrontendConfig
addListenerConfig
addRulesConfig

$Script:mermaid += "`n"

Write-Output $Script:mermaid
