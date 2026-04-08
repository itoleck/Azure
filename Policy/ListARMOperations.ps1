param (
    [string]$ProviderString = "Microsoft.Network/virtualNetworks/*"
)

$ops=Get-AzProviderOperation ProviderString
$ops|select Operation