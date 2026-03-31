#Azire Migrate Simplified Agent-based Migration test script
#requires -Version 7 -module Az.RecoveryServices, Az.Accounts, Az.Network

param (
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][string]$SubscriptionId,
    [Parameter(Mandatory=$true)][string]$FullComputerName,
    [Parameter(Mandatory=$true)][string]$NetworkId
)

# Set global variable for failover Azure-AsyncOperation
# So a failover can be checked in another PowerShell script run or from terminal
$global:AsyncOperation

$sub_id = $SubscriptionId
$rg = $ResourceGroupName
$computer_name = $FullComputerName
$net_id = $NetworkId

if (Get-AzContext) {
    Write-Host "Already logged in to Azure"
}
else {
    Write-Host "Not logged in to Azure. Please login."
    Add-AzAccount
}

function getstatus($Response) {
    # Get the failover operation status
    $Response.Headers | ForEach-Object {
        if ($_.Key -eq "Azure-AsyncOperation") {
            $OperationUri = $_.Value
        }
    }
    $res = Invoke-AzRestMethod -Method GET -Uri $($OperationUri)
    $global:AsyncOperation = $OperationUri
    Write-Host "Failover Operation Status: $(($res.Content | ConvertFrom-Json).status)"
}

function getmigrationparams {
    # Find the Recovery Services vault in the project resource group
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults?api-version=2024-04-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $vault = ($res.Content | convertfrom-json).value
    $vault_name = ($vault.name)
    Write-Host "Vault Name: $vault_name"


    # List replication fabrics
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$vault_name/replicationFabrics?api-version=2024-10-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $fabric = ($res.Content | convertfrom-json).value
    $fabric_name = ($fabric.name)
    Write-Host "Fabric Name: $fabric_name"


    # List protection containers
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$vault_name/replicationFabrics/$fabric_name/replicationProtectionContainers?api-version=2024-10-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $container = ($res.Content | convertfrom-json).value
    $container_name = ($container.name)
    Write-Host "Protection Container Name: $container_name"


    # Get protected items
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$vault_name/replicationProtectedItems?api-version=2025-08-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $protected_items = ($res.Content | convertfrom-json).value
    #$protected_items | Select-Object name,properties
    $protected_item = $protected_items | Where-Object { $_.properties.friendlyName -eq $computer_name }
    $protected_item_name = $protected_item.name
    Write-Host "Protected Item Name: $protected_item_name"
}

function getmigrationserversites {
    # Get Microsoft.OffAzure/ServerSites
    # Not needed for failover, but just to find the server site ID if needed for other calls
    $rtype = "Microsoft.OffAzure/serversites"
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/resources?`$filter=resourceType eq `'$rtype`'&api-version=2022-09-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $sites = ($res.Content | convertfrom-json).value
    Write-Host "Replication Sites: $($sites)"
}

function getmigrationvmwaresites {
    # Get Microsoft.OffAzure/VMWareSites
    # Not needed for failover, but just to find the server site ID if needed for other calls
    $rtype = "Microsoft.OffAzure/vmwaresites"
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/resources?`$filter=resourceType eq `'$rtype`'&api-version=2022-09-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $sites = ($res.Content | convertfrom-json).value
    Write-Host "Replication Sites: $($sites)"
}

function getmigrationhypervsites {
    # Get Microsoft.OffAzure/HyperVSites
    # Not needed for failover, but just to find the server site ID if needed for other calls
    $rtype = "Microsoft.OffAzure/hypervsites"
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/resources?`$filter=resourceType eq `'$rtype`'&api-version=2022-09-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $sites = ($res.Content | convertfrom-json).value
    Write-Host "Replication Sites: $($sites)"
}

function getmigrationmastersites {
    # Get Microsoft.OffAzure/MasterSites
    # Not needed for failover, but just to find the server site ID if needed for other calls
    $rtype = "Microsoft.OffAzure/mastersites"
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/resources?`$filter=resourceType eq `'$rtype`'&api-version=2022-09-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $sites = ($res.Content | convertfrom-json).value
    Write-Host "Replication Sites: $($sites)"
}

function getmigrationfailoverjobs {
    # Get all failover job data
    $uri = "/subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$vault_name/replicationJobs?api-version=2025-08-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $jobs = ($res.Content | convertfrom-json).value
    $jobs | Select-Object -Property Name, 
        @{Name = 'friendlyName'; Expression = { $_.properties.friendlyName }},
        @{Name = 'state';     Expression = { $_.properties.state }}
}

function getsinglereplicationitem {
    # Test getting 1 repl item
    $uri = "/subscriptions/$sub_id/resourceGroups/$rg/providers/Microsoft.RecoveryServices/vaults/$vault_name/replicationFabrics/$fabric_name/replicationProtectionContainers/$container_name/replicationProtectedItems/$($protected_item_name)?api-version=2025-08-01"
    $res = Invoke-AzRestMethod -Method GET -Path $uri
    $res_obj = $res.Content|ConvertFrom-Json
    $name = $res_obj.properties.friendlyName
    Write-Host "Replication Item Name: $name"
}

function testfailover {
    # Test failover
    $response = Read-Host "Run Test Failover code? (y/n)"
    if ($response.Trim() -match "^y") {
        $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
        $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$vault_name/replicationFabrics/$fabric_name/replicationProtectionContainers/$container_name/replicationProtectedItems/$($protected_item_name)/"
        $uri = $uri + "testFailover?api-version=2025-08-01"
        Write-Host "Test Failover URI: $uri"

        $payload = @{
            properties= @{
                failoverDirection="PrimaryToRecovery"
                networkType="VmNetworkAsInput"
                networkId="$net_id"
                providerSpecificDetails=@{
                    instanceType="InMageRcm"
                    recoveryPointId = "" # Blank for latest
                    networkId="$net_id"
                }
            }
        }
        $body = $payload | ConvertTo-Json -Depth 10
        Write-Host "Test Failover Payload: $body"
        $res = Invoke-AzRestMethod -Method POST -Path $uri -Payload $body
        Write-Host "Test Failover initiated. Status code: $($res.StatusCode)"
    }
    Start-Sleep -Seconds 60

    # Get the failover operation status
    getstatus -Response $res
}

function cleanuptestfailover {
    # Clean up test failover job
    $response = Read-Host "Run Test Failover Cleanup code? (y/n)"
    if ($response.Trim() -match "^y") {
        $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
        $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$vault_name/replicationFabrics/$fabric_name/replicationProtectionContainers/$container_name/replicationProtectedItems/$($protected_item_name)/"
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
        Write-Host "Test Failover Cleanup initiated. Status code: $($res.StatusCode)"
    }
    Start-Sleep -Seconds 60

    # Get the failover operation status
    getstatus -Response $res
}

function plannedfailover {
    # Planned failover
    $uri = "/Subscriptions/$sub_id/resourceGroups/$rg/"
    $uri = $uri + "providers/Microsoft.RecoveryServices/vaults/$vault_name/replicationFabrics/$fabric_name/replicationProtectionContainers/$container_name/replicationProtectedItems/$($protected_item_name)/"
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
    Write-Host "Planned Failover initiated. Status code: $($res.StatusCode)"

    Start-Sleep -Seconds 60

    # Get the failover operation status
    getstatus -Response $res
}

# Start of script - display menu and prompt for action
$menu = @"
=================================
 Azure Migrate Agent-based Tests
=================================
1) Run Query All Jobs

2) Run Test Failover
    3) Clean up Test Failover

4) Run Planned Failover
    5) Clean up Planned Failover
6) Nothing
7) Get single Azure-AsyncOperation status via URI. Get in terminal with '`$global:AsyncOperation'
8) Get single replication item based on FullComputerName

9) Show ServerSites, not needed for failover
10) Show VMWareSites, not needed for failover
11) Show HyperVSites, not needed for failover
12) Show MasterSites, not needed for failover
13) Get Replication Sites, not needed for failover
999) Exit
=================================
"@

Write-Host $menu
$choice = Read-Host "Please select an option (1-999)"
switch ($choice) {
    "1" {
        Write-Host "Get all failover job data..." -ForegroundColor Cyan
        getmigrationparams
        getmigrationfailoverjobs
    }
    "2" {
        Write-Host "Test Failover..." -ForegroundColor Cyan
        getmigrationparams
        testfailover
    }
    "3" {
        Write-Host "Cleaning up Test Failover Job..." -ForegroundColor Cyan
        getmigrationparams
        cleanuptestfailover
    }
    "4" {
        Write-Host "Planned Failover..." -ForegroundColor Cyan
        getmigrationparams
    }
    "5" {
        Write-Host "Cleaning up Planned Failover Job..." -ForegroundColor Cyan
        getmigrationparams
    }
    "6" {
        Write-Host "Not implemented..." -ForegroundColor Cyan
    }
    "7" {
        $async_uri = Read-Host "Enter Azure-AsyncOperation URI to query status"
        $global:AsyncOperation = $async_uri
        $res = Invoke-AzRestMethod -Method GET -Uri $($global:AsyncOperation)
        $res | Format-List
    }
    "8" {
        Write-Host "Getting single replication item..." -ForegroundColor Cyan
        getmigrationparams
        getsinglereplicationitem
    }
    "9" {
        Write-Host "Getting ServerSites..." -ForegroundColor Cyan
        getmigrationserversites
    }
    "10" {
        Write-Host "Getting VMWareSites..." -ForegroundColor Cyan
        getmigrationvmwaresites
    }
    "11" {
        Write-Host "Getting HyperVSites..." -ForegroundColor Cyan
        getmigrationhypervsites
    }
    "12" {
        Write-Host "Getting MasterSites..." -ForegroundColor Cyan
        getmigrationmastersites
    }
    "13" {
        Write-Host "Getting replication sites..." -ForegroundColor Cyan
        getmigrationparams
        getmigrationsites
    }
    "999" {
        Write-Host "Exiting..." -ForegroundColor Yellow
        exit
    }
    Default {
        Write-Host "Invalid selection." -ForegroundColor Red
    }
}