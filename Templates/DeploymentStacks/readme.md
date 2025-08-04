# Deployment Stacks

## Commands

**Create MG Stack:**

.\mg-deploy.ps1 -ManagementGroupID 'mg id' -SubscriptionID 'sub id' -TemplatePath .\mg-sqldb\mg\mg-main.bicep -Location 'location' -DenySettingsMode none -ActionOnUnmanage detachAll -StackName 'stack name' -DenySettingsExcludedActions 'microsoft.sql/servers/databases/backuplongtermretentionpolicies/write Microsoft.Sql/servers/databases/restorePoints/delete' -DenySettingsExcludedPrincipals 'principal id'

**Create MG Stack:**

.\mg-deploy.ps1 -ManagementGroupID 'mg id' -SubscriptionID 'sub id' -TemplatePath .\mg-storageaccount\mg\mg-main.bicep -Location 'location' -DenySettingsMode none -ActionOnUnmanage detachAll -StackName 'stack name'

**Create Sub Stack:**

.\sub-deploy.ps1 -StackName SubStorage1 -TemplatePath .\sub-storageaccount\sub\sub-main.bicep -Location 'location'

**Delete MG Stack:**
az stack mg delete --name 'stack name' --action-on-unmanage 'deleteResources' --management-group-id 'mg id'

**List All Stacks:**

```bash
    - az stack mg list --management-group-id 'mg id'

    - Get-AzManagementGroupDeploymentStack -ManagementGroupId 'mg id'
```

**Show Stack:**

```bash
    - az stack mg show --name 'stack name' --management-group-id 'mg id' --output 'json'

    - Get-AzManagementGroupDeploymentStack -ManagementGroupId 'mg id' -name 'stack name'
```

## Links

<https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks?tabs=azure-cli>

<https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/quickstart-create-deployment-stacks?tabs=azure-cli%2CCLI>
