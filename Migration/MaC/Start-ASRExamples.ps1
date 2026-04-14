#Azure Migrate/ASR Simplified Agent-based Migration test script
#requires -Version 7 -module Az.RecoveryServices, Az.Accounts, Az.Network

param (
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,         # Resource group name where the Recovery Services vault/s are located
    [Parameter(Mandatory=$true)][string]$SubscriptionId,            # Subscription ID of the project subscription, needed to find vault and construct API URIs
    [Parameter(Mandatory=$false)][string]$VNetId,                   # Full Virtual Network Id of the destination subnet in Azure, needed for agent-based migration failover
    [Parameter(Mandatory=$false)][string]$SubnetName,               # Subnet name in the VNet, needed for agent-based migration failover
    [Parameter(Mandatory=$false)][string]$targetResourceGroupId,    # Full resource group id of the target VM. Will be used for the test and manul failovers
    [Parameter(Mandatory=$false)][string]$targetBootDiagnosticsStorageAccountId,    # Full storage account id for enabling boot diagnostics for the migrated VM
    [Parameter(Mandatory=$false)][string]$logStorageAccountId       # Full storage account id for migration log
)

# Set global variable for failover Azure-AsyncOperation
# So a failover can be checked in another PowerShell script run or from terminal
$global:AsyncOperation
$script:vault_name
$script:fabric_name
$script:container_name
$script:protected_item_name     #Friendly Name of a protected item, needed for enabling replication and failover operations. This is the name shown in the friendlyName property of the protected item, which can be obtained by running the getprotecteditems function.
$script:sites = [System.Collections.Generic.List[object]]::new()
$script:site                    #Site ID for enabling replication. This is the name shown in the properties.friendlyName of the server site, which can be obtained by running the getmigrationserversites function. For agent-based migration, this is typically the server site that represents the on-prem environment.
$script:policy                  #Policy for enabling replication. This is the full object of the replication policy, which can be obtained by running the getpolicy function or from the Azure portal. It is needed for enabling replication for a protected item.
$script:run_as_account_id

# These variables are used if you want to overwrite the PowerShell parameters for testing in the code editor with F8
# Duplicate the next 7 lines and change the values if you want to hardcode the parameters for testing, otherwise it will use the parameters you input when running the script.
$sub_id = $SubscriptionId
$rg = $ResourceGroupName
$net_id = $VNetId
$subnet_name = $SubnetName
$target_rg = $targetResourceGroupId
$targetbootdiagstorage_id = $targetBootDiagnosticsStorageAccountId
$logstorage_id = $logStorageAccountId

# Check if user is logged in to Azure, if not prompt to login. This is needed to get an access token for the REST API calls
if (Get-AzContext) {
    Write-Host "`n`rAlready logged in to Azure`n"
    Write-host (Get-AzContext).Subscription.Name
}
else {
    Write-Host "`n`rNot logged in to Azure. Please login."
    Add-AzAccount
}

# This function is used to display a list of objects and prompt the user to select one. It is used throughout the script to select vault, fabric, container, and protected item.
function selectchoice($Title, $Message, $Objects) {
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]::new($Objects.Count)

    for ($i = 0; $i -lt $Objects.Count; $i++) {
        
        $hasFriendlyName = ($null -ne $Objects[$i].properties) -and ($null -ne $Objects[$i].properties.psobject.properties['friendlyName'])
        $hasDisplayname = ($null -ne $Objects[$i].properties) -and ($null -ne $Objects[$i].properties.psobject.properties['displayName'])

        if($hasFriendlyName) {
            # Add a number and an ampersand (&) to create a keyboard shortcut
            # If the object has a friendlyName property, we display that instead of the name property for better readability
            $choices[$i] = [System.Management.Automation.Host.ChoiceDescription]::new("&$($i + 1). $($Objects[$i].properties.friendlyName)", "Selects $($Objects[$i].properties.friendlyName)")
        } elseif($hasDisplayname) {
            # Add a number and an ampersand (&) to create a keyboard shortcut
            $choices[$i] = [System.Management.Automation.Host.ChoiceDescription]::new("&$($i + 1). $($Objects[$i].properties.displayName)", "Selects $($Objects[$i].properties.displayName)")
        } else {
            # Add a number and an ampersand (&) to create a keyboard shortcut
            $choices[$i] = [System.Management.Automation.Host.ChoiceDescription]::new("&$($i + 1). $($Objects[$i].Name)", "Selects $($Objects[$i].Name)")
        }
    }
    $choiceresult = $Host.UI.PromptForChoice($title, $message, $choices, 0)
    $result = $Objects[$choiceresult]
    return $result
}

# This function is used to get the status of a long-running operation, such as a failover, by querying the Azure-AsyncOperation URI provided in the response headers of the initial API call that started the operation.
function getstatus($Response) {
    # Get the failover operation status
    $Response.Headers | ForEach-Object {
        if ($_.Key -eq "Azure-AsyncOperation") {
            $OperationUri = $_.Value
        }
    }
    $res = Invoke-AzRestMethod -Method GET -Uri $($OperationUri)
    $global:AsyncOperation = $OperationUri
    Write-Host "Failover Operation Status: $(($res.Content | ConvertFrom-Json).status)`n`r"
    Write-Host "AsyncOperation Uri:`n`r$($global:AsyncOperation)"
    return $res
}

function getstatusloop($operation, $operation_uri, $finishing_message) {
    # Loop through 300 seconds and write a period each second to the console
    # Then check the status of the operation. Exit when the operation is Succeeded. Not sure of every status message available so may need to update later.
    $i = 0
    do {
        for ($i = 0; $i -lt 300; $i++) {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 1
        }
        $res = Invoke-AzRestMethod -Method GET -Uri "$($operation_uri)"
        $jres=($res.Content)|ConvertFrom-Json
        Write-Host "`n$($operation) Status: $($jres.status)"
    } while ($jres.status -ne "Succeeded")
     Write-Host "$($finishing_message)"
}

# The following functions are used to get the necessary parameters for the failover operations, such as vault name, fabric name, container name, and protected item name. They use the selectchoice function to prompt the user to select from a list of available options.
function getvault {
    # Find the Recovery Services vault in the project resource group
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults?api-version=2024-04-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $vault = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select Recovery Services Vault" -Message "Which Recovery Services vault would you like to use?" -Objects $vault)
    $script:vault_name = ($selectedObject.name)
    Write-Host "Vault Name: $($script:vault_name)"
}

function getfabric {
    # List replication fabrics
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics?api-version=2024-10-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $fabric = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select Recovery Services Fabric" -Message "Which Recovery Services fabric would you like to use?" -Objects $fabric)
    $script:fabric_name = ($selectedObject.name)
    Write-Host "Fabric Name: $($script:fabric_name)"
}

function getprotectioncontainers {
    # List protection containers
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers?api-version=2024-10-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $container = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select Protection Container" -Message "Which Protection Container would you like to use?" -Objects $container)
    $script:container_name = ($selectedObject.name)
    Write-Host "Protection Container Name: $($script:container_name)"
}

function getprotecteditems {
    # Get protected items
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationProtectedItems?api-version=2025-08-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $protected_items = ($res.Content | convertfrom-json).value
    #$protected_items | Select-Object name,properties
    #$protected_item = $protected_items | Where-Object { $_.properties.friendlyName -eq $computer_name }

    $selectedObject = (selectchoice -Title "Select Protected Item" -Message "Which Protected Item would you like to use?" -Objects $protected_items)
    $script:protected_item_name = ($selectedObject.name)

    #$protected_item_name = $protected_item.name
    Write-Host "Protected Item Name: $($script:protected_item_name)"
}

function getpolicy {
    # Get replication policy
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationPolicies?api-version=2024-10-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $policies = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select Replication Policy" -Message "Which Replication Policy would you like to use?" -Objects $policies)
    $script:policy = ($selectedObject)
    Write-Host "Selected Policy: $($script:policy)"
}

# Called by the failover functions to get all necessary parameters for the API calls. You can also run the individual get functions separately if you want to just get specific information or test the API calls without running a failover.
function getmigrationparams {
    getvault
    getfabric
    getprotectioncontainers
    getprotecteditems
}

function getmigrationserversites {
    # Get Microsoft.OffAzure/ServerSites
    # Not needed for failover, but just to find the server site ID if needed for other calls. Not really used.
    $rtype = "Microsoft.OffAzure/serversites"
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/resources?`$filter=resourceType eq `'$rtype`'&api-version=2022-09-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $sites = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select Server Site" -Message "Which Server Site would you like to use for replication?" -Objects $sites)
    return $selectedObject
}

function getmigrationvmwaresites {
    # Get Microsoft.OffAzure/VMWareSites
    # Not needed for failover, but just to find the server site ID if needed for other calls.
    $rtype = "Microsoft.OffAzure/vmwaresites"
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/resources?`$filter=resourceType eq `'$rtype`'&api-version=2022-09-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $sites = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select VMWare Site" -Message "Which VMWare Site would you like to use for replication?" -Objects $sites)
    return $selectedObject
}

function getmigrationhypervsites {
    # Get Microsoft.OffAzure/HyperVSites
    # Not needed for failover, but just to find the server site ID if needed for other calls. Not really used.
    $rtype = "Microsoft.OffAzure/hypervsites"
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/resources?`$filter=resourceType eq `'$rtype`'&api-version=2022-09-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $sites = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select HyperV Site" -Message "Which HyperV Site would you like to use for replication?" -Objects $sites)
    return $selectedObject
}

function getmigrationmastersites {
    # Get Microsoft.OffAzure/MasterSites
    # Not needed for failover, but just to find the server site ID if needed for other calls. Not really used.
    $rtype = "Microsoft.OffAzure/mastersites"
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/resources?`$filter=resourceType eq `'$rtype`'&api-version=2022-09-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $sites = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select Master Site" -Message "Which Master Site would you like to use for replication?" -Objects $sites)
    return $selectedObject
}

function getallsites {
    #Cycle through all site types and add to the global sites list for selection.
    $script:sites.Add((getmigrationserversites))
    $script:sites.Add((getmigrationvmwaresites))
    $script:sites.Add((getmigrationhypervsites))
    $script:sites.Add((getmigrationmastersites))
}

function selectsinglesite {
    # Select a single site from the list of all sites
    $selectedObject = (selectchoice -Title "Select Site" -Message "Which Site would you like to use?" -Objects $script:sites)
    $script:site = ($selectedObject)
    Write-Host "Selected Site Id: $($script:site.id)"
}

# This function get the replication jobs, which includes failover jobs, for a vault.
function getmigrationfailoverjobs {
    # Get all failover job data
    $uri = "/subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationJobs?api-version=2025-08-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $jobs = ($res.Content | convertfrom-json).value
    $jobs | Select-Object -Property  @{Name = 'time'; Expression = { $_.properties.endTime }},
        @{Name = 'friendlyName'; Expression = { $_.properties.friendlyName }},
        @{Name = 'state';     Expression = { $_.properties.state }},
        @{Name = 'id'; Expression = { $_.name }}
}

# This function gets a single replication item based on the protected item name. This is used to get the details of the protected item, which can be useful for troubleshooting and to verify that the correct item is being used for the failover.
function getsinglereplicationitem {
    # Test getting 1 repl item
    $uri = "/subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/$($protected_item_name)?api-version=2025-08-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $res_obj = $res.Content|ConvertFrom-Json
    $name = $res_obj.properties.friendlyName
    Write-Host "Replication Item Name: $name`n`r"
    return $res_obj
}

# This function initiates a test failover for the selected protected item. It constructs the API URI and payload based on the selected vault, fabric, container, and protected item, and then makes a POST request to start the test failover. After initiating the failover, it calls the getstatus function to check the status of the operation.
function testfailover {
    # Test failover
    $response = Read-Host "Run Test Failover code? (y/n)"
    if ($response.Trim() -match "^y") {
        $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
        $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/$($protected_item_name)/"
        $uri = $uri + "testFailover?api-version=2025-08-01"
        Write-Host "Test Failover URI: $uri"

        $payload = @{
            properties= @{
                failoverDirection="PrimaryToRecovery"
                networkType="VmNetworkAsInput"      # This is the only valid option for agent-based migration
                networkId="$net_id"                 # The full network ID must be provided for agent-based migration
                providerSpecificDetails=@{
                    instanceType="InMageRcm"
                    recoveryPointId = ""            # Blank for latest
                    networkId="$net_id"             # The full network ID must be provided for agent-based migration
                }
            }
        }
        $body = $payload | ConvertTo-Json -Depth 10
        Write-Host "Test Failover Payload: $body"
        $res = Invoke-AzRestMethod -Method POST -Path $uri -Payload $body
        Write-Host "Test Failover initiated. Status code: $($res.StatusCode).`nWait 60 seconds for status, status update every 5 minutes."
    }
    Start-Sleep -Seconds 60

    # Get the failover operation status
    getstatus -Response $res

    getstatusloop -operation "Test Failover" -operation_uri $global:AsyncOperation -finishing_message "Test Failover of machine $($machine_fixedname) completed"
}

# This function initiates the cleanup of a test failover for the selected protected item. It constructs the API URI and payload based on the selected vault, fabric, container, and protected item, and then makes a POST request to start the cleanup of the test failover. After initiating the cleanup, it calls the getstatus function to check the status of the operation.
function cleanuptestfailover {
    # Clean up test failover job
    $response = Read-Host "Run Test Failover Cleanup code? (y/n)"
    if ($response.Trim() -match "^y") {
        $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
        $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/$($protected_item_name)/"
        $uri = $uri + "testFailoverCleanup?api-version=2025-08-01"
        Write-Host "Test Failover URI: $uri"

        $payload = @{
            properties= @{
                comments="Clean up from script"
            }
        }
        $body = $payload | ConvertTo-Json -Depth 10
        Write-Host "Test Failover Cleanup Payload:`n$body"
        $res = Invoke-AzRestMethod -Method POST -Path $uri -Payload $body
        Write-Host "Test Failover Cleanup initiated. Status code: $($res.StatusCode).`nWait 60 seconds for status, status update every 5 minutes."
    }
    Start-Sleep -Seconds 60

    # Get the failover operation status
    getstatus -Response $res

    getstatusloop -operation "Test Failover Cleanup" -operation_uri $global:AsyncOperation -finishing_message "Test Failover Cleanup of machine $($machine_fixedname) completed"
}

# This function initiates a planned failover for the selected protected item. It constructs the API URI and payload based on the selected vault, fabric, container, and protected item, and then makes a POST request to start the planned failover. After initiating the failover, it calls the getstatus function to check the status of the operation.
function plannedfailover {
    # Planned failover
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$script:vault_name/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/$($protected_item_name)/"
    $uri = $uri + "unplannedFailover?api-version=2025-08-01"
    Write-Host "Planned Failover URI: $uri"

    $payload = @{
        properties= @{
            failoverDirection="PrimaryToRecovery"
            providerSpecificDetails=@{
                instanceType="InMageRcm"
                performShutdown="true"
            }
        }
    }
    $body = $payload | ConvertTo-Json -Depth 10
    Write-Host "Planned Failover Payload: $body"

    $res = Invoke-AzRestMethod -Method POST -Path $uri -Payload $body
    Write-Host "Planned Failover initiated. Status code: $($res.StatusCode).`nWait 60 seconds for status, status update every 5 minutes."

    Start-Sleep -Seconds 60

    # Get the failover operation status
    getstatus -Response $res

    getstatusloop -operation "Planned Failover" -operation_uri $global:AsyncOperation -finishing_message "Planned Failover of machine $($machine_fixedname) completed"
}

# This function initiates the cancellation of a planned failover for the selected protected item.
function cancelfailover {
    $response = Read-Host "Run Failover Cancel code? (y/n)"
    if ($response.Trim() -match "^y") {
        $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
        $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/$($protected_item_name)/"
        $uri = $uri + "failoverCancel?api-version=2025-08-01"
        Write-Host "Failover Cancel URI: $uri"

        $payload = @{
            properties= @{
                comments="Cancel from script"
            }
        }
        $body = $payload | ConvertTo-Json -Depth 10
        Write-Host "Failover Cancel Payload:`n$body"
        $res = Invoke-AzRestMethod -Method POST -Path $uri -Payload $body
        Write-Host "Failover Cancel initiated. Status code: $($res.StatusCode).`nWait 60 seconds for status, status update every 5 minutes."
    }
    Start-Sleep -Seconds 60

    # Get the failover operation status
    getstatus -Response $res

    getstatusloop -operation "Failover Cancel" -operation_uri $global:AsyncOperation -finishing_message "Failover Cancel of machine $($machine_fixedname) completed"
}

function commitfailover {
    $response = Read-Host "Run Failover Commit code? (y/n)"
    if ($response.Trim() -match "^y") {
        $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
        $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/$($protected_item_name)/"
        $uri = $uri + "failoverCommit?api-version=2025-08-01"
        Write-Host "Failover Commit URI: $uri"

        $payload = @{
            properties= @{
                comments="Commit from script"
            }
        }
        $body = $payload | ConvertTo-Json -Depth 10
        Write-Host "Failover Commit Payload:`n$body"
        $res = Invoke-AzRestMethod -Method POST -Path $uri -Payload $body
        Write-Host "Failover Commit initiated. Status code: $($res.StatusCode).`nWait 60 seconds for status, status update every 5 minutes."
    }
    Start-Sleep -Seconds 60

    # Get the failover operation status
    getstatus -Response $res

    getstatusloop -operation "Failover Commit" -operation_uri $global:AsyncOperation -finishing_message "Failover Commit of machine $($machine_fixedname) completed"
}

function disablereplication {
    # Disable replication for the selected protected item
    $response = Read-Host "Run Disable Replication code? (y/n)"
    if ($response.Trim() -match "^y") {
        $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
        $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/$($protected_item_name)/"
        $uri = $uri + "remove?api-version=2025-08-01"
        Write-Host "Disable Replication URI: $uri"

        $payload = @{
            properties= @{
                disableProtectionReason="NotSpecified"
                replicationProviderInput=@{
                    instanceType="InMageRcm"            # API says 'InMage' but testing with 'InMageRcm'
                    replicaVmDeletionStatus="Retain"    # or 'Delete'
                }
            }
        }
        $body = $payload | ConvertTo-Json -Depth 10
        Write-Host "Disable Replication Payload:`n$body"
        $res = Invoke-AzRestMethod -Method POST -Path $uri -Payload $body
        Write-Host "Disable Replication initiated. Status code: $($res.StatusCode).`nWait 60 seconds for status, status update every 5 minutes."
    }
    Start-Sleep -Seconds 60

    # Get the failover operation status
    getstatus -Response $res

    getstatusloop -operation "Disable Replication" -operation_uri $global:AsyncOperation -finishing_message "Disable Replication of machine $($machine_fixedname) completed"
}

# This function lists the recovery points for the selected protected item. It constructs the API URI based on the selected vault, fabric, container, and protected item, and then makes a GET request to retrieve the list of recovery points. The recovery points are then displayed in a formatted list.
function listrecoverypoints {
    # List recovery points for the protected item
    $uri = "/subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$script:vault_name/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/$($protected_item_name)/recoveryPoints?api-version=2025-08-01"
    Write-Host "List Recovery Points URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $recovery_points = ($res.Content | convertfrom-json).value
    $recovery_points | Select-Object Properties | Format-List
}

function replicationMigrationItems {
    # Get unreplicated items
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/"
    $uri = $uri + "replicationMigrationItems?api-version=2025-08-01"
    Write-Host "replicationMigrationItems URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $res | Format-List
}

function replicationProtectableItems {
    # Get protectable items by replication protection container
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/"
    $uri = $uri + "replicationProtectableItems?api-version=2025-08-01"
    Write-Host "replicationProtectableItems URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $res | Format-List
}

function replicationProtectableItem {
    # Get protectable items by replication protection container
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/"
    $uri = $uri + "replicationProtectableItems?api-version=2025-08-01"
    Write-Host "replicationProtectableItems URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $selectedObject = (selectchoice -Title "Select Machine" -Message "Which protected machine would you like?" -Objects $res)
    return $selectedObject
}

function replicationAppliances {
    # Get replication appliances
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/"
    $uri = $uri + "replicationAppliances?api-version=2025-08-01"
    Write-Host "replicationAppliances URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $appliances = ($res.Content | convertfrom-json).value
    $appliances.properties.providerSpecificDetails.appliances | Format-List
}

function replicationAlertSettings {
    # Get replication appliances
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/"
    $uri = $uri + "replicationAlertSettings?api-version=2025-08-01"
    Write-Host "replicationAlertSettings URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $alerts = ($res.Content | convertfrom-json).value
    Write-Host "Alert Name: $($alerts.name)"
    $alerts.properties | Format-List
}

function replicationEvents {
    # Get replication appliances
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/"
    $uri = $uri + "replicationEvents?api-version=2025-08-01"
    Write-Host "replicationEvents URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $events = ($res.Content | convertfrom-json).value
    $events | Format-List
}

function replicationPolicies {
    # Get replication appliances
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/"
    $uri = $uri + "replicationPolicies?api-version=2025-08-01"
    Write-Host "replicationPolicies URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $policies = ($res.Content | convertfrom-json).value
    $policies | Format-List
}

function enablereplication {
    # Enable replication for the selected protected item
    $response = Read-Host "Run Enable Replication code? (y/n)"
    if ($response.Trim() -match "^y") {

        $machine = getmachinesinsite -site_path $script:site.id
        $machine_displayname = $machine.properties.displayName
        $machine_fixedname = $machine_displayname.Replace(".","")
        $machine_id = $machine.id
        $machine_name = $machine.name

        $appliance = getreplicationAppliance

        $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
        $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/"
        $uri = $uri + "$($machine_name)?api-version=2025-08-01"
        Write-Host "Enable Replication URI: $uri"

        $payload = @{
            properties= @{
                policyId="$($script:policy.id)"
                protectableItemId="$($machine_id)"
                providerSpecificDetails=@{
                    instanceType="InMageRcm"
                    fabricDiscoveryMachineId="$($machine_id)"
                    targetResourceGroupId="$($target_rg)"    #Get from script param
                    targetNetworkId=$net_id
                    targetSubnetName="$($subnet_name)"         #Get from script param
                    testNetworkId=$net_id
                    testSubnetName="$($subnet_name)"
                    targetVmName="$($machine_fixedname)"
                    targetVmSize=$null
                    licenseType="NotSpecified"
                    targetAvailabilitySetId=$null
                    storageAccountId=$null
                    targetBootDiagnosticsStorageAccountId="$($targetbootdiagstorage_id)"
                    processServerId="$($appliance.processServer.id)"
                    runAsAccountId="$($script:run_as_account_id)"  #runAs account that maps to local account from ASR appliance
                    multiVmGroupName=$null
                    disksToInclude=$null
                    disksDefault=@{
                        diskType="Standard_LRS"
                        logStorageAccountId="$($logstorage_id)"
                    }
                }
            }
        }
        $body = $payload | ConvertTo-Json -Depth 10
        Write-Host "Enable Replication Payload:`n$body"
        pause
        $res = Invoke-AzRestMethod -Method PUT -Path $uri -Payload $body
        Write-Host "Enable Replication initiated. Status code: $($res.StatusCode).`nWait 60 seconds for status, status update every 5 minutes."
        $res

        Start-Sleep -Seconds 300
        getstatus -Response $res

        getstatusloop -operation "Enable Replication" -operation_uri $global:AsyncOperation -finishing_message "Enable Replication of machine $($machine_fixedname) completed"

    }
}

function resyncreplication {
    # Resync replication for the selected protected item
    Write-Host "Resyncing Replication for the selected protected item."

    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/"
    $uri = $uri + "$($script:protected_item_name)/repairReplication?api-version=2025-08-01"
    Write-Host "Resync-Replication URI: $uri"
    $res = Invoke-AzRestMethod -Method POST -Path $uri -Payload $body
    Write-Host "Resync Replication initiated for machine $($script:protected_item_name). Status code: $($res.StatusCode)."
    $res

    Start-Sleep -Seconds 60
    getstatus -Response $res
}

function reprotect {
    # Re-Protect replication for the selected protected item
    Write-Host "Re-Protecting Replication for the selected protected item."
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/replicationFabrics/$($script:fabric_name)/replicationProtectionContainers/$($script:container_name)/replicationProtectedItems/"
    $uri = $uri + "$($script:protected_item_name)/reProtect?api-version=2025-08-01"
    Write-Host "Resync-Replication URI: $uri"
    $res = Invoke-AzRestMethod -Method POST -Path $uri -Payload $body
    Write-Host "Resync Replication initiated for machine $($script:protected_item_name). Status code: $($res.StatusCode)."
    $res

    Start-Sleep -Seconds 60
    getstatus -Response $res
}

function getmachinesinsite($site_path) {
    # Get machines in a site
    $uri = $site_path + "/machines?api-version=2023-06-06"
    Write-Host "getmachinesinsite URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $machines = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select Machine" -Message "Which machine would you like to use for replication?" -Objects $machines)
    #$machines.properties | Select-Object displayName,networkAdapters,disks,applianceNames,ipAddresses,updatedTimestamp | Format-List
    return $selectedObject
}

function getrunasinsite($site_path) {
    # Get runas accounts for a site
    $uri = $site_path + "/runasAccounts?api-version=2020-01-01-preview"
    Write-Host "getrunasinsite URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $runas = ($res.Content | convertfrom-json).value
    $runas | Format-List
}

function getsinglerunasaccountinsite($site_path) {
    # Get single runas account in a site
    $uri = $site_path + "/runasAccounts?api-version=2020-01-01-preview"
    Write-Host "getrunasinsite URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $runas = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select runAs Account" -Message "Which machine would you like to use for replication?" -Objects $runas)
    $script:run_as_account_id = $selectedObject.id
    Write-Host "Selected runAs Account Id: $($script:run_as_account_id)"
    return $selectedObject
}

function getreplicationAppliance {
    # Get single replication appliance
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$($script:vault_name)/"
    $uri = $uri + "replicationAppliances?api-version=2025-08-01"
    Write-Host "replicationAppliances URI: $uri"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $appliances = ($res.Content | convertfrom-json).value
    $selectedObject = (selectchoice -Title "Select Appliance" -Message "Which appliance would you like to use for replication?" -Objects $appliances.properties.providerSpecificDetails.appliances)
    return $selectedObject
}

# Start of script - display menu and prompt for action
Clear-Host
$menu = @"
                                        Azure Migrate Agent-based Tests
=====================================================================================================================
Azure Migrate Replication Management PowerShell Examples
---------------------------------------------------------------------------------------------------------------------
100) Enable Replication
     101) Disable Replication
     102) Resyncrhonize Protected Item
     103) Re-Protect Protected Item
     104) Get Recovery Points for Protected Item
     105) Get single replication item detailed information

200) Run Test Failover
    201) Clean up Test Failover

300) Run Failover
    301) Cancel Failover
    302) Commit Failover

---------------------------------------------------------------------------------------------------------------------
Replication Status Queries
---------------------------------------------------------------------------------------------------------------------
400) Run Query all Replication Jobs
401) Get single Azure-AsyncOperation status via URI. (Get in terminal with '`$global:AsyncOperation')

---------------------------------------------------------------------------------------------------------------------
Replication Sites Queries
---------------------------------------------------------------------------------------------------------------------
800) Get All Replication Sites
801) Get ServerSites
802) Get VMWareSites
803) Get HyperVSites
804) Get MasterSites
805) Get all runasAccounts for a site
806) Get Machines in migration sites
807) Get single runasAccount in a site

---------------------------------------------------------------------------------------------------------------------
Direct Azure REST API Call Examples
---------------------------------------------------------------------------------------------------------------------
990) vaults - (Recovery Services Vaults - List)
991) replicationFabrics - (Replication Fabrics - List By Recovery Services Vault)
992) replicationProtectionContainers - (Replication Protection Containers - List By Replication Fabrics)
993) replicationMigrationItems - (Replication Migration Items - List)
994) replicationProtectableItems - (Replication Protectable Items - List By Replication Protection Containers)
995) replicationPolicies - (Replication Policies - List)
996) replicationEvents - (Replication Events - List)
997) replicationAlertSettings - (Replication Alert Settings - List)
998) replicationAppliances - (Replication Appliances - List)

999) Exit
================================   Scroll up for more   =============================================================
"@

# Display menu and prompt for action
Write-Host $menu
$choice = Read-Host "Please select an option (1-999)"
switch ($choice) {
    "100" { #Enable Replication
        Write-Host "Enabling replication..." -ForegroundColor Cyan
        getvault
        getfabric
        getprotectioncontainers
        getpolicy
        getallsites
        selectsinglesite
        getsinglerunasaccountinsite -site_path $script:site.id
        enablereplication
    }
    "101" { #Disable Replication
        Write-Host "Disabling replication..." -ForegroundColor Cyan
        getmigrationparams
        disablereplication
    }
    "102" { #Resync/Repair Replication
        Write-Host "Resynchronizing Protected Item..." -ForegroundColor Cyan
        getmigrationparams
        resyncreplication
    }
    "103" { #Re-Protecting Protected Item
        Write-Host "Re-Protecting Protected Item..." -ForegroundColor Cyan
        getmigrationparams
        reprotect
    }
    "104" { #Getting Recovery Points for Protected Item
        Write-Host "Getting Recovery Points for Protected Item..." -ForegroundColor Cyan
        getmigrationparams
        listrecoverypoints
    }
    "105" { #Getting single replication item detailed information
        Write-Host "Getting single replication item detailed information..." -ForegroundColor Cyan
        getmigrationparams
        getsinglereplicationitem | Format-List
    }
    "200" { #Run Test Failover
        Write-Host "Running Test Failover..." -ForegroundColor Cyan
        getmigrationparams
        testfailover
    }
    "201" { #Cleaning up Test Failover
        Write-Host "Cleaning up Test Failover..." -ForegroundColor Cyan
        getmigrationparams
        #Make sure protected item is ready to clean up.
        $repl_item = getsinglereplicationitem
        If (($repl_item.properties.testFailoverState) -ne "WaitingForCompletion") {
            Write-Host "Protected item is not ready for test failover cleanup. Current state: $($repl_item.properties.testFailoverState)" -ForegroundColor Yellow
            Write-Host "Exiting cleanup to avoid errors. Please run terst failover and try again when it is ready for cleanup." -ForegroundColor Yellow
        } else {
            cleanuptestfailover
        }
    }

    "300" { #Run Failover
        Write-Host "Running Failover..." -ForegroundColor Cyan
        getmigrationparams
        plannedfailover
    }
    "301" { #Cancel Failover
        Write-Host "Canceling Failover..." -ForegroundColor Cyan
        getmigrationparams
        cancelfailover
    }
    "302" { #Commit Failover
        Write-Host "Committing Failover..." -ForegroundColor Cyan
        getmigrationparams
        commitfailover
    }

    "400" { #Get All Replication Jobs, past and present
        Write-Host "Getting all failover job data..." -ForegroundColor Cyan
        getvault
        getmigrationfailoverjobs
    }
    "401" { #Get single Azure-AsyncOperation status via URI.
        Write-Host "Getting failover job data for a specific job..." -ForegroundColor Cyan
        $async_uri = Read-Host "Enter Azure-AsyncOperation URI to query status"
        $global:AsyncOperation = $async_uri
        $res = Invoke-AzRestMethod -Method GET -Uri "$($global:AsyncOperation)"
        $res.StatusCode | Format-List
        $res.Content | Format-List
    }

    "800" { #Get All Replication Sites
        Write-Host "Getting all replication sites in a vault..." -ForegroundColor Cyan
        getmigrationserversites
        getmigrationvmwaresites
        getmigrationhypervsites
        getmigrationmastersites
    }
    "801" { #Get ServerSites
        Write-Host "Getting ServerSites..." -ForegroundColor Cyan
        Write-Host "ServerReplication Sites: $(getmigrationserversites)"
    }
    "802" { #Get VMWareSites
        Write-Host "Getting VMWareSites..." -ForegroundColor Cyan
        Write-Host "VMWareReplication Sites: $(getmigrationvmwaresites)"
    }
    "803" { #Get HyperVSites
        Write-Host "Getting HyperVSites..." -ForegroundColor Cyan
        Write-Host "Hyper-V Replication Sites: $(getmigrationhypervsites)"
    }
    "804" { #Get MasterSites
        Write-Host "Getting MasterSites..." -ForegroundColor Cyan
        Write-Host "Master Replication Sites: $(getmigrationmastersites)"
    }
    "805" { #Select a site and get the runAs accounts in that site
        getallsites
        selectsinglesite
        getrunasinsite -site_path $script:site.id
    }
    "806" { #Get a list of Machines in migration sites
        Write-Host "List the Discovered Machines in migration sites..." -ForegroundColor Cyan
        $site = getmigrationserversites
        if ($site.length -gt 0) {
            getmachinesinsite -site_path $site.id
        }

        $site = getmigrationhypervsites
        if ($site.length -gt 0) {
            getmachinesinsite -site_path $site.id
        }

        $site = getmigrationmastersites
        if ($site.length -gt 0) {
            getmachinesinsite -site_path $site.id
        }

        $site = getmigrationvmwaresites
        if ($site.length -gt 0) {
            getmachinesinsite -site_path $site.id
        }
    }
    "807" { #Get a single runAs account in a site
        Write-Host "Get single runAs account in a site..." -ForegroundColor Cyan
        getallsites
        selectsinglesite
        getsinglerunasaccountinsite -site_path $script:site.id
    }
    "990" { #Get a list of Recovery Services Vaults
        Write-Host "Listing Recovery Services Vaults in the subscription..." -ForegroundColor Cyan
        getvault
    }
    "991" { #Get a list of Replication Fabrics in a vault
        Write-Host "Listing Fabrics in a vault..." -ForegroundColor Cyan
        getvault
        getfabric
    }
    "992" { #Get a list of Replication Protection Containers in a vault
        Write-Host "Listing Protection Containers in a vault..." -ForegroundColor Cyan
        getvault
        getfabric
    }
    "993" { #Get a list of Replication Migration Items in a vault
        Write-Host "Listing Replication Migration Items..." -ForegroundColor Cyan
        getvault
        getfabric
        getprotectioncontainers
        replicationMigrationItems
    }
    "994" { #Get a list of Replication Protectable Items in a vault
        Write-Host "Listing protectable items by replication protection container..." -ForegroundColor Cyan
        getvault
        getfabric
        getprotectioncontainers
        replicationProtectableItems
    }
    "995" { #Get a list of Replication Policies in a vault
        Write-Host "replicationPolicies - (Replication Policies - List)" -ForegroundColor Cyan
        getvault
        replicationPolicies
    }
    "996" { #Get a list of Replication Events in a vault
        Write-Host "replicationEvents - (Replication Events - List)" -ForegroundColor Cyan
        getvault
        replicationEvents
    }
    "997" { #Get a list of Replication Alert Settings in a vault
        Write-Host "replicationAlertSettings - (Replication Alert Settings - List)" -ForegroundColor Cyan
        getvault
        replicationAlertSettings
    }
    "998" { #Get a list of Replication Appliances in a vault
        Write-Host "replicationAppliances - (Replication Appliances - List)" -ForegroundColor Cyan
        getvault
        replicationAppliances
    }
    "999" { #Exit
        Write-Host "Exiting..." -ForegroundColor Cyan
        exit
    }
    Default {
        Write-Host "Invalid selection." -ForegroundColor Red
    }
}