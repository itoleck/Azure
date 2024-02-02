<#
.SYNOPSIS
    Opens a CSV file made with .\Get-AzFilesSASTokensFromCSV.ps1 and deletes old files from Azure Files source.
    
.DESCRIPTION
    Opens a CSV file made with .\Get-AzFilesSASTokensFromCSV.ps1 and deletes old files from Azure Files source.
    Based on work by https://learn.microsoft.com/en-us/users/na/?userid=644e0f37-c28c-4865-98a8-3fde4cc4d068
.PARAMETER CSVPath
    Local .csv file path. Columns (URI,ShareName,SAS)

.PARAMETER DeleteBeforeDate
    Set to delete only files modified before a date/time in format mm/dd/yyyy.
#>

Param(
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][string] $CSVPath,
    [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][DateTime] $DeleteBeforeDate,
    [Parameter(Mandatory=$false, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)][boolean] $force = $false
)

$Csv = Import-Csv -Path $CSVPath
$Csv | ForEach-Object {
    $ctx = New-AzStorageContext -FileEndpoint ($_.URI).TrimEnd('/') -SasToken ($_.SAS).TrimStart('?')

    $DirIndex = 0
    $dirsToList = New-Object System.Collections.Generic.List[System.Object]

    # Get share root Dir
    $shareroot = Get-AzStorageFile -ShareName $_.ShareName -Path . -context $ctx 
    $dirsToList += $shareroot

    While ($dirsToList.Count -gt $DirIndex) {
        $dir = $dirsToList[$DirIndex]
        $DirIndex ++
        $fileListItems = $dir | Get-AzStorageFile
        $dirsListOut = $fileListItems | Where-Object {$_.GetType().Name -eq "AzureStorageFileDirectory"}
        $dirsToList += $dirsListOut
        $files = $fileListItems | Where-Object {$_.GetType().Name -eq "AzureStorageFile"}
        
        foreach($file in $files)
        {
            # Fetch Attributes of each file and output
            $task = $file.CloudFile.FetchAttributesAsync()
            $task.Wait()
        
            # remove file if it's older than $DeleteBeforeDate.
            if ($file.CloudFile.Properties.LastModified -lt $DeleteBeforeDate)
            {
                ## print the file LMT
                $file | Select-Object @{ Name = "Uri"; Expression = { $_.CloudFile.SnapshotQualifiedUri} }, @{ Name = "LastModified"; Expression = { $_.CloudFile.Properties.LastModified } } 
                # remove file
                if ($force) {
                    $file | Remove-AzStorageFile
                }
            }
        }
    }
}