param (
    [Parameter(Mandatory=$true)][string]$Location = "eastus"
)

Get-AzVmImagePublisher -Location $Location | Get-AzVMExtensionImageType | Get-AzVMExtensionImage | Select-Object Type -Unique
