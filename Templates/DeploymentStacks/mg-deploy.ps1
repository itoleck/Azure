param(
    
    [Parameter(Mandatory=$true)]
    [string]$StackName,
    
    [Parameter(Mandatory=$true)]
    [string]$ManagementGroupID,
    
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        $subscriptions = (Get-AzSubscription).Id
        if ($subscriptions -notcontains $_) {
            throw "SubscriptionID '$_' is not a valid subscription."
        }
        return $true
    })]
    [string]$SubscriptionID,
    
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if( -Not ($_ | Test-Path) ){
            throw "Bicep file does not exist"
        }
        return $true
    })]
    [System.IO.FileInfo]$TemplatePath,
    
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        $locations = (Get-AzLocation).Location

        if ($locations -notcontains $_) {
            throw "Location '$_' is not a valid Azure location."
        }
        return $true
    })]
    [string]$Location,
    
    [Parameter(Mandatory=$true)]
    [string]$DenySettingsExcludedActions,   #Space separated list of actions to exclude from deny settings, e.g. "Microsoft.Compute/virtualMachines/write Microsoft.Compute/virtualMachines/delete" #200 Maximum

    [Parameter(Mandatory=$true)]
    [string]$DenySettingsExcludedPrincipals,   #Space separated list of principals to exclude from deny settings, e.g. "user1 user2"    #5 Maximum

    [Parameter(Mandatory=$true)]
    [ValidateSet("none")]   #, "denyDelete", "denyWriteAndDelete"
    [string]$DenySettingsMode, #Can only be 'none' for Management Group deployment stacks {"code": "DeploymentStackInvalidDeploymentStackDefinition", "message": "The deployment stack '' is invalid, because deny assignments are only supported for deployments at subscription scope."}
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("detachAll", "deleteAll", "deleteResources")]
    [string]$ActionOnUnmanage = 'detachAll'
)

# Create a management group deployment stack
az stack mg create `
    -m $($ManagementGroupID) `
    -n $StackName `
    -f $($TemplatePath) `
    --location $($Location) `
    --parameters subscriptionID=$($SubscriptionID) `
    --deny-settings-mode $($DenySettingsMode) `
    --aou $($ActionOnUnmanage) `
    --deny-settings-excluded-actions $($DenySettingsExcludedActions) `
    --deny-settings-excluded-principals $($DenySettingsExcludedPrincipals) `
    --deny-settings-apply-to-child-scopes
