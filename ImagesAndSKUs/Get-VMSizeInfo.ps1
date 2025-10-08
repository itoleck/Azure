param (
    [string]$Location="eastus"
)

$skus=Get-AzComputeResourceSku -Location $Location
$a0=$skus|?{$_.name -like '*_A*'}|Select-Object -first 1
$a0.Capabilities
