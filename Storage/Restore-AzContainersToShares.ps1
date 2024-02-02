<#
.SYNOPSIS
    Opens a CSV file made with .\Get-AzSASTokensFromCSV and restores files from Azure blob container source to Azure Files share destination.
    
.DESCRIPTION
    Opens a CSV file made with .\Get-AzSASTokensFromCSV and restores files from Azure blob container source to Azure Files share destination.

.PARAMETER CSVPath
    Local .csv file path. Columns (URI,ShareName,SAS)

.PARAMETER SourceSAS
    The source storage account file SAS token with read permission

.PARAMETER SourceContainerURL
    The source storage account blob container for the backup copies.

.PARAMETER IncludeAfter
    Set to include only files modified after a date/time in format mm/dd/yyyy.
#>

Param(
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][string] $CSVPath,
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][string] $SourceSAS,
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][string] $SourceContainerURL,
    [Parameter(Mandatory=$false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][DateTime] $IncludeAfter = (Get-Date).AddYears(-30)
)

$azCtx = Get-AzContext
if (!$azCtx) {
    Add-AzAccount
}

$SourceContainerURL = ($SourceContainerURL).ToLower().TrimEnd("/") + "/"
[String]$IncludeAfterStr = ($IncludeAfter).Date.ToString("yyy-MM-dd")

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

$Csv | ForEach-Object {

    $source = $SourceContainerURL + $_.ShareName + "/" + $SourceSAS
    $dest = $_.URI + $_.ShareName + $_.SAS
    
    # Create the root container for all shares
    try {
        $ctx = New-AzStorageContext -FileEndpoint ($_.URI).TrimEnd('/') -SasToken ($_.SAS).TrimStart('?')
        $ctx
        New-AzStorageShare -Name $_.ShareName -Context $ctx

        # Cannot find working cmdlet to change quota and storage share tier
        # New-AzRmStorageShare: The value for one of the HTTP headers is not in the correct format.
        #New-AzRmStorageShare -ResourceGroupName $_.RG -StorageAccountName $_.StorageAccountName -Name $_.ShareName -QuotaGiB 102400 -AccessTier Cool
    }
    catch {
        
    }

    Write-Output "azcopy command:"
    Write-Output "azcopy.exe copy `"$source`" `"$dest`" --recursive --include-after $IncludeAfterStr"
    Write-Output ""

    Start-Process -FilePath azcopy.exe -NoNewWindow -ArgumentList "copy `"$source`" `"$dest`" --recursive --include-after $IncludeAfterStr"

}