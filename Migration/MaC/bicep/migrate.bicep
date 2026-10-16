targetScope = 'subscription'

@description('Azure Migrate project name. Use 3-24 letters, numbers, or hyphens.')
@minLength(3)
@maxLength(24)
param name string

@description('Resource group to create or use for the Azure Migrate project.')
@minLength(1)
@maxLength(90)
param resourceGroupName string

@description('Azure region for the resource group and Azure Migrate project.')
@minLength(1)
param location string

@description('Public enables public network access. Private disables it and creates a private endpoint and DNS resources.')
@allowed([
  'Public'
  'Private'
])
param connectivity string = 'Public'

@description('Existing subnet resource ID. Required for Private connectivity. The subnet must have available private IP addresses.')
param privateEndpointSubnetId string = ''

resource projectResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}

module project 'migrate-project.bicep' = {
  name: '${name}-project'
  scope: projectResourceGroup
  params: {
    name: name
    location: location
    connectivity: connectivity
    privateEndpointSubnetId: privateEndpointSubnetId
  }
}

output migrateProjectId string = project.outputs.migrateProjectId
output privateEndpointId string = project.outputs.privateEndpointId