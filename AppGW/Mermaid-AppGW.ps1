Param(
    [parameter(Mandatory=$true)][string] $DiagramTitle,
    [Parameter(Mandatory=$true)][string] $ApplicationGatewayResourceId,
    [Parameter(Mandatory=$false)][ValidateSet("TD", "DT", "LR", "RL")][string] $MermaidDirection = 'TD'
)

$MermaidText = ""

$ApplicationGatewaySubscription = ""
$ApplicationGatewayResourceGroup = ""
$ApplicationGatewayName = ""

$ApplicationGatewayResourceIdParts = $ApplicationGatewayResourceId.Split("/")
$ApplicationGatewaySubscription = $ApplicationGatewayResourceIdParts[2]
$ApplicationGatewayResourceGroup = $ApplicationGatewayResourceIdParts[4]
$ApplicationGatewayName = $ApplicationGatewayResourceIdParts[8]

Set-AzContext -Subscription $ApplicationGatewaySubscription | Out-Null

$AppGW = Get-AzApplicationGateway -ResourceGroupName $ApplicationGatewayResourceGroup -Name $ApplicationGatewayName

$MermaidText = Build-MermaidTitle -title $DiagramTitle -mermaidDirection $MermaidDirection

$http2 = "HTTP2: False";if ($AppGW.EnableHttp2){$http2 = "HTTP2: True"}
$fips = "FIPS: False";if ($AppGW.EnableFips){$fips = "FIPS: True"}
$zones = "Zones: False";if ($AppGW.Zones){$zones = "Zones: True"}
$label = "";$label = $ApplicationGatewayName + "<br />Tier: " + $AppGW.Sku.Tier + "<br />" + $http2 + "<br />" + $fips + "<br />" + $zones + "<br />Operational State: " + $AppGW.OperationalState + "<br />Provisioning State: " + $AppGW.ProvisioningState

$MermaidText += Build-MermaidNode -sourceNode $ApplicationGatewayName -sourceNodeLabel $label -sourceNodeType "[]" -destNode $AppGW.Location -destNodeLabel $AppGW.Location -destNodeType "[]" -edgeType "-->" -edgeLabel "AppGW"

Write-Output $MermaidText