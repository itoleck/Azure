@description('Azure Migrate project name.')
@minLength(3)
@maxLength(24)
param name string

@description('Azure region for the Azure Migrate project.')
param location string

@allowed([
  'Public'
  'Private'
])
param connectivity string

@description('Existing subnet resource ID, required for Private connectivity.')
param privateEndpointSubnetId string

var subnetIdParts = split(privateEndpointSubnetId, '/')

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = if (connectivity == 'Private') {
  scope: resourceGroup(subnetIdParts[2], subnetIdParts[4])
  name: subnetIdParts[8]
}

resource migrateProject 'Microsoft.Migrate/migrateProjects@2023-01-01' = {
  name: name
  location: location
  properties: {
    publicNetworkAccess: connectivity == 'Private' ? 'Disabled' : 'Enabled'
  }
}

module privateConnectivity 'migrate-private-endpoint.bicep' = if (connectivity == 'Private') {
  name: '${name}-network'
  params: {
    projectName: migrateProject.name
    projectId: migrateProject.id
    subnetId: privateEndpointSubnetId
    location: connectivity == 'Private' ? virtualNetwork!.location : location
    virtualNetworkId: connectivity == 'Private' ? virtualNetwork!.id : ''
  }
}

output migrateProjectId string = migrateProject.id
@description('Private endpoint resource ID, or an empty string for Public connectivity.')
output privateEndpointId string = privateConnectivity.?outputs.privateEndpointId ?? ''
