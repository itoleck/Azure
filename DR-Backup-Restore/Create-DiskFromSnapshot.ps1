Param (
    [Parameter(Mandatory=$true)][string]$SourceResourceGroup,
    [Parameter(Mandatory=$true)][string]$TargetResourceGroup,
    [Parameter(Mandatory=$true)][string]$SnapshotName,
    [Parameter(Mandatory=$true)][string]$newOsDiskName,
    [Parameter(Mandatory=$true)][string]$Location,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Standard_LRS", "StandardSSD_LRS", "StandardSSD_ZRS", "Premium_LRS", "Premium_ZRS", "UltraSSD_LRS")]
    [string]$DiskSku
)

#Check Login to Azure Account
try {
    $azContext = Get-AzContext
    if ($null -eq $azContext) {
        throw "Not logged in to any Azure account. Please login using Connect-AzAccount."
    }
} catch {
    throw "Error checking Azure login status: $_"
}

$osSnap = Get-AzSnapshot -ResourceGroupName $SourceResourceGroup -SnapshotName $SnapshotName

$osDiskConfig = New-AzDiskConfig -Location $Location -CreateOption Copy -SourceResourceId $osSnap.Id -SkuName $DiskSku -DiskSizeGB $osSnap.DiskSizeGB

New-AzDisk -ResourceGroupName $TargetResourceGroup -DiskName $newOsDiskName -Disk $osDiskConfig -ErrorAction Stop | Out-Null

$newOsDisk = Get-AzDisk -ResourceGroupName $TargetResourceGroup -DiskName $newOsDiskName

Write-Output "Managed OS disk created:"
$newOsDisk
Write-Output "Create a new VM from the Portal from the Disk resource."