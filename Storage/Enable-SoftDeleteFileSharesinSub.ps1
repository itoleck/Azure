<#
.SYNOPSIS
    Enumerates all storage accounts with file share service in a subscription or list of subscriptions and sets the soft delete to enabled with a retention time.
    
.DESCRIPTION
    Enumerates all storage accounts with file share service in a subscription or list of subscriptions and sets the soft delete to enabled with a retention time.

.PARAMETER SubscriptionID
    (string) - The subscription ID to use to enumerate the storage accounts in.
    To enter multiple subscription IDs, seperate by comma (,)
    i.e. -SubscriptionID 00000000-0000-0000-0000-000000000001,00000000-0000-0000-0000-000000000002,00000000-0000-0000-0000-000000000003

.PARAMETER OverwriteCurrent
    (boolean) - Set to $true to overwrite any current retention days settings.
    Default is to only set the retention days for storage account file shares that are not already enabled.

.PARAMETER RetentionDays
    (int) - The number of days to retain deleted files (1 - 365 days).
    Default is 7 days.
#>

Param(
    [Parameter(Mandatory=$true)][string[]] $SubscriptionID,
    [Parameter(Mandatory=$false)][boolean] $OverwriteCurrent = $false,
    [Parameter(Mandatory=$false)][ValidateRange(1, 365)][int] $RetentionDays = 7
)

$azCtx = Get-AzContext
if (!$azCtx) {
    Add-AzAccount
}

$subs = $SubscriptionID.Split(',')
foreach ($sub in $subs) {
    try {
        Set-AzContext -Subscription $sub
        Write-Output ("Getting storage accounts from subscription {0}" -f $sub)

        try {
            #Only get storage accounts that have file shares
            $saccounts = Get-AzStorageAccount | Where-Object {!$_.Kind.contains("Blob")}
    
            foreach ($saccount in $saccounts) {
                try {
                    $fsprop = $saccount | Get-AzStorageFileServiceProperty
                    $fsprop_issoftdeleteenabled = $fsprop.ShareDeleteRetentionPolicy.Enabled
                    #$fsprop_softdeletedays  = $fsprop.ShareDeleteRetentionPolicy.Days  #Unused
        
                    if (!$fsprop_issoftdeleteenabled) {
                        #Soft Delete is not enabled, enable and set the retention
                        try {
                            $saccount | Update-AzStorageFileServiceProperty -EnableShareDeleteRetentionPolicy $true -ShareRetentionDays $RetentionDays
                            Write-Output ("Successfully set the soft delete for file service account {0}" -f $saccount.StorageAccountName)
                        }
                        catch {
                            Write-Error ("Error setting the soft delete settings for {0}" -f $saccount.StorageAccountName)
                        }
                    } else {
                        #Check if overwrite is set to treu
                        if ($OverwriteCurrent) {
                            try {
                                $saccount | Update-AzStorageFileServiceProperty -EnableShareDeleteRetentionPolicy $true -ShareRetentionDays $RetentionDays
                                Write-Output ("Successfully set the soft delete for file service account {0}" -f $saccount.StorageAccountName)
                            }
                            catch {
                                Write-Error ("Error setting the soft delete settings for {0}" -f $saccount.StorageAccountName)
                            }
                        } else {
                            Write-Output ("Skipping setting the soft delete for {0} as it was already set and overwrite is set to false" -f $saccount.StorageAccountName)
                        }
                    }
        
                }
                catch {
                    Write-Error ("Error getting storage account for {0}" -f $saccount.StorageAccountName)
                }
            }
        }
        catch {
            Write-Error ("Error getting storage accounts for subscription {0}" -f $sub)
        }
    }
    catch {
        Write-Error ("Error setting context for subscription {0}" -f $sub)
    }
}