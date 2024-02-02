<#
.SYNOPSIS
    Opens a CSV file made with .\Get-AzFilesSASTokensFromCSV.ps1 and copies files from Azure Files source to Azure Blob destination single container.
    
.DESCRIPTION
    Opens a CSV file made with .\Get-AzFilesSASTokensFromCSV.ps1 and copies files from Azure Files source to Azure Blob destination single container.

.PARAMETER CSVPath
    Local .csv file path. Columns (URI,ShareName,SAS)

.PARAMETER DestAccountURL
    The destination storage account blob URL (https://account.blob.core.windows.net)

.PARAMETER DestSAS
    The destination storage account blob SAS token with write permission

.PARAMETER DestRootContainerName
    The destination storage account blob container for the backup copies. All shares are copied into this one blob container so the archive bit can be set manually in Azure Portal or Storage Explorer or other means.

.PARAMETER isArchive
    Set to $true to copy the Azure Files Shares to Blob containers with the archive tier set.

.PARAMETER IncludeAfter
    Set to include only files modified after a date/time in format mm/dd/yyyy.
#>

Param(
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][string] $CSVPath,
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][string] $DestAccountURL,
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][string] $DestSAS,
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][string] $DestRootContainerName,
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][bool] $isArchive,
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][DateTime] $IncludeAfter = (Get-Date).AddDays(-365)
)

$azCtx = Get-AzContext
if (!$azCtx) {
    Add-AzAccount
}

$DestRootContainerName = ($DestRootContainerName).ToLower()
$DestRootContainerName = ($DestRootContainerName -replace '[^a-z0-9]', '')
$DestAccountURL = ($DestAccountURL).ToLower()
[String]$IncludeAfterStr = ($IncludeAfter).Date.ToString("yyy-MM-dd")
$Archive = ""

$azcopyexists = $false
$Csv = Import-Csv -Path $CSVPath

# Look for azcopy to make sure it's available, may work in Linux
if (Get-Command 'azcopy' -ErrorAction SilentlyContinue)
{ 
   $azcopyexists = $true
} else {
    Write-Error 'azcopy is not found in the path. Update your PATH or install azcopy.'
    Exit 1
}

if ($isArchive) {
    $Archive = " --block-blob-tier Archive "
}

# Create the root container for all shares
try {
    $con = 'BlobEndpoint=' + $DestAccountURL.TrimEnd('/') + '/;SharedAccessSignature=' + $DestSAS.TrimStart('?')
    $ctx = New-AzStorageContext -ConnectionString $con
    Write-Output "Creating new container for shares."
    New-AzStorageContainer -Name $DestRootContainerName -Context $ctx
}
catch {
    
}

# Create container in destination blob storage
# Loop through each share and create a blob container with the same sharename
$Csv | ForEach-Object {
    
    $source = $_.URI.TrimEnd('/') + '/' + $_.ShareName.TrimEnd('/') + $_.SAS
    $dest = $DestAccountURL.TrimEnd('/') + '/' + $DestRootContainerName + '/' + $_.ShareName.TrimEnd('/') + '/' + $DestSAS

    Write-Output "azcopy command:"
    Write-Output "azcopy.exe copy `"$source`" `"$dest`" --recursive --include-after $IncludeAfterStr $Archive"
    Start-Process -FilePath azcopy.exe -NoNewWindow -ArgumentList "copy `"$source`" `"$dest`" --recursive --put-md5 --include-after $IncludeAfterStr $Archive"
}