<#
.SYNOPSIS
    Opens an Azure cost report CSV file with storage account information and creates SAS tokens for full read for each and saves in another CSV file.
    
.DESCRIPTION
    Opens an Azure cost report CSV file with storage account information and creates SAS tokens for full read for each and saves in another CSV file.

.PARAMETER CSVPath
    Local Azure cost report CSV file path. Columns (ResourceName,ResourceId,ResourceType,ResourceGroup,ResourceGroupId,ResourceLocation,Subscription,SubscriptionId,Tags,Cost,CostUSD,Currency)
 
#>

Param(
    [Parameter(Mandatory=$true)][string] $CSVPath
)

$azCtx = Get-AzContext
if (!$azCtx) {
    Add-AzAccount
}

$Csv = Import-Csv -Path $CSVPath
$AzFileShares = New-Object System.Collections.ArrayList

# Read input csv and get the storage account keys for each subscription and storage account with your current login context
    # For each sub in csv
    $Csv | ForEach-Object {

        # For each resource group and storage account in sub
            # Get and save key
            $accountkey = (Get-AzStorageAccountKey -ResourceGroupName $_.ResourceGroup -Name $_.ResourceName)[0].Value
            
            # Get storage account context with the key
            $ctx = New-AzStorageContext -StorageAccountName $_.ResourceName -StorageAccountKey $accountkey

            # Enumerate all of the shares in the storage account
            $shares = Get-AzStorageShare -Context $ctx

            # Store storage account name
            $accountname = $_.ResourceName

            # Store resource group name
            $resourcegroup = $_.ResourceGroup

            $shares | ForEach-Object {

                # Create a read/list SAS token for the file service for each storage account
                # For each storage account with key saved create storage context
                # Create and save SAS token for storage account
                # Enumerate all shares in csv list of storage accounts
                # Save to csv each connection string with SAS token for each storage account
                $AzFileShareRow=New-Object AzFileShareStorageInfo
                $AzFileShareRow.URI = 'https://' + $accountname + '.file.core.windows.net/'
                $AzFileShareRow.ShareName = $_.name

                $accountkey = $_ | New-AzStorageAccountSASToken -Service File -ResourceType Service,Container,Object -Permission 'racwdlup' -ExpiryTime (Get-Date).AddDays(31)

                $AzFileShareRow.SAS = $accountkey
                $AzFileShareRow.RG = $resourcegroup
                $AzFileShareRow.StorageAccountName = $accountname
                $null=$AzFileShares.Add($AzFileShareRow)

            }
    }

    $savecsvpath = $CSVPath + '.keys.csv'
    $AzFileShares | Export-Csv -Path $savecsvpath -Force

Class AzFileShareStorageInfo {
    [String]$URI
    [String]$ShareName
    [String]$SAS
    [String]$RG
    [String]$StorageAccountName
}