param (
    [string]$Location
)

$skus=Get-AzComputeResourceSku -Location $Location
$skus|Where-Object{$_.name -like '*_A*'}|Select-Object -first 1|Select-Object *
$a0=$skus|?{$_.name -like '*_A*'}|Select-Object -first 1
$a0.RestrictionInfo
