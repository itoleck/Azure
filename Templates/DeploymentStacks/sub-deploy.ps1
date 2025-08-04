param(
    
    [Parameter(Mandatory=$true)]
    [string]$StackName,

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
    
    [Parameter(Mandatory=$false)]
    [string]$DenySettingsExcludedActions,   #Space separated list of actions to exclude from deny settings, e.g. "Microsoft.Compute/virtualMachines/write Microsoft.Compute/virtualMachines/delete" #200 Maximum

    [Parameter(Mandatory=$false)]
    [string]$DenySettingsExcludedPrincipals,   #Space separated list of principals to exclude from deny settings, e.g. "user1 user2"    #5 Maximum

    [Parameter(Mandatory=$false)]
    [ValidateSet("none", "denyDelete", "denyWriteAndDelete")]
    [string]$DenySettingsMode = 'none', #Can only be 'none' for Management Group deployment stacks {"code": "DeploymentStackInvalidDeploymentStackDefinition", "message": "The deployment stack '' is invalid, because deny assignments are only supported for deployments at subscription scope."}
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("detachAll", "deleteAll", "deleteResources")]
    [string]$ActionOnUnmanage = 'detachAll'
)

# Create a subscription deployment stack
az stack sub create `
    -n $($StackName) `
    -f $($TemplatePath) `
    --location $($Location) `
    --deny-settings-excluded-actions=$($DenySettingsExcludedActions) `
    --deny-settings-excluded-principals=$($DenySettingsExcludedPrincipals) `
    --deny-settings-mode $($DenySettingsMode) `
    --action-on-unmanage $($ActionOnUnmanage)