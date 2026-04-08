targetScope = 'subscription'

param location string = deployment().location

param KVPrincipal string

param LogicAppName string

param LogicAppUniqueName string = '${LogicAppName}${uniqueString(deployment().name, location)}'

@maxLength(24)
param StorageAccountUniqueName string = '${LogicAppName}stor${uniqueString(deployment().name, location)}'

param KeyVaultUniqueName string = '${LogicAppName}-kv-${uniqueString(deployment().name, location)}'

resource appRG 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: '${LogicAppName}-rg'
  location: location
}

module serverFarm 'br/public:avm/res/web/serverfarm:0.6.0' = {
  scope: appRG
  name: '${LogicAppName}-asp'
  params: {
    name: '${LogicAppName}-asp'
    kind: 'elastic'
    maximumElasticWorkerCount:3
    skuName: 'WS1'
  }
}

module mgmtIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  scope: appRG
  name: '${LogicAppName}-mi'
  params: {
    name: '${LogicAppName}-mi'
  }
}

module keyvault 'br/public:avm/res/key-vault/vault:0.11.0' = {
  scope: appRG
  name: KeyVaultUniqueName
  params: {
    name: KeyVaultUniqueName
    sku: 'standard'
    roleAssignments: [
      { principalId: mgmtIdentity.outputs.principalId, roleDefinitionIdOrName: 'Key Vault Secrets User' }
      { principalId: KVPrincipal, roleDefinitionIdOrName: 'Key Vault Secrets User' } // Assign yourself access to Key Vault to create secrets (optional)
    ]
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.14.3' = {
  scope: appRG
  name: StorageAccountUniqueName
  params: {
    name: StorageAccountUniqueName
    secretsExportConfiguration: { //this exports the connectionstring to a keyvault secret
      keyVaultResourceId: keyvault.outputs.resourceId
      connectionString1: '${LogicAppName}-connectionstring'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    publicNetworkAccess: 'Enabled'
  }
}

module logicapp 'br/public:avm/res/web/site:0.11.1' = {
 scope: appRG
 name: LogicAppUniqueName
 params: {
 name: LogicAppUniqueName
 kind: 'functionapp,workflowapp'
 serverFarmResourceId: serverFarm.outputs.resourceId
 siteConfig: {
 alwaysOn: true
 netFrameworkVersion: 'v8.0'
 }
 managedIdentities: {
 userAssignedResourceIds: [
 mgmtIdentity.outputs.resourceId
 ]
 }
 keyVaultAccessIdentityResourceId: mgmtIdentity.outputs.resourceId
 appSettingsKeyValuePairs: {
 FUNCTIONS_EXTENSION_VERSION: '~4'
 FUNCTIONS_WORKER_RUNTIME: 'dotnet'
 WEBSITE_CONTENTSHARE: '${LogicAppName}-share'
 APP_KIND: 'workflowApp'
 WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(VaultName=${keyvault.outputs.name};SecretName=${LogicAppName}-connectionstring)'
 }
 }
}
