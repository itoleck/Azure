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
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$DenySettingsExcludedActions,   #Space separated list of actions to exclude from deny settings, e.g. "Microsoft.Compute/virtualMachines/write Microsoft.Compute/virtualMachines/delete" #200 Maximum

    [Parameter(Mandatory=$true)]
    [string]$DenySettingsExcludedPrincipals,   #Space separated list of principals to exclude from deny settings, e.g. "user1 user2"    #5 Maximum

    [Parameter(Mandatory=$true)]
    [ValidateSet("none", "denyDelete", "denyWriteAndDelete")]
    [string]$DenySettingsMode, #Can only be 'none' for Management Group deployment stacks {"code": "DeploymentStackInvalidDeploymentStackDefinition", "message": "The deployment stack '' is invalid, because deny assignments are only supported for deployments at subscription scope."}
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("detachAll", "deleteAll", "deleteResources")]
    [string]$ActionOnUnmanage = 'detachAll'
)

# Create a resource group deployment stack
az stack group create `
    -m $($StackName) `
    -f $($TemplatePath) `
    --resource-group $($ResourceGroupName) `
    --parameters denySettingsExcludedActions=$($DenySettingsExcludedActions) `
    --parameters denySettingsExcludedPrincipals=$($DenySettingsExcludedPrincipals) `
    --deny-settings-mode $($DenySettingsMode) `
    --action-on-unmanage $($ActionOnUnmanage)