Param(
    [Parameter(Mandatory=$true)][string] $resourceGroupName = '',
    [Parameter(Mandatory=$true)][string] $vmName = ''
)

$dt = (Get-Date -Format yyyyMMdd-HHmmss) 

$snapshotName = "$($vmName)-OS-$dt"
$myVM = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
$snapConfigDetails = New-AzSnapshotConfig -SourceUri $myVM.StorageProfile.OsDisk.ManagedDisk.Id -Location $myVM.Location -CreateOption Copy

New-AzSnapshot -Snapshot $snapConfigDetails -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName
Write-Output "Snapshot created: $snapshotName"