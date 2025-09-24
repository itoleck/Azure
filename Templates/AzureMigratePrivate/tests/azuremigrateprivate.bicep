@description('The name of the Azure Migrate project')
param migrateProjectName string = 'migrate-project-${uniqueString(resourceGroup().id)}'

@description('The location for all resources')
param location string = resourceGroup().location

@description('The name of the virtual network')
param vnetName string = 'migrate-vnet'

@description('The address prefix for the virtual network')
param vnetAddressPrefix string = '10.10.0.0/16'

@description('The name of the subnet for private endpoints')
param privateEndpointSubnetName string = 'PrivateEndpointSubnet'

@description('The address prefix for the private endpoint subnet')
param privateEndpointSubnetPrefix string = '10.10.1.0/24'

@description('The name of the subnet for compute resources')
param computeSubnetName string = 'migrate-subnet'

@description('The address prefix for the compute subnet')
param computeSubnetPrefix string = '10.10.2.0/24'

@description('Tags to apply to all resources')
param tags object = {
  Purpose: 'Azure Migrate Private Connectivity'
}

// Create Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: computeSubnetName
        properties: {
          addressPrefix: computeSubnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Create Private DNS Zone for Azure Migrate
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.prod.migration.windowsazure.com'
  location: 'global'
  tags: tags
}

// Link Private DNS Zone to Virtual Network
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${vnetName}-link'
  parent: privateDnsZone
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

// Create Private Endpoint for Azure Migrate
resource migratePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${migrateProjectName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '${virtualNetwork.id}/subnets/${privateEndpointSubnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${migrateProjectName}-connection'
        properties: {
          privateLinkServiceId: migrateProject.id
          groupIds: [
            'migrateProjects'
          ]
        }
      }
    ]
  }
}

// Create Private DNS Zone Group for the Private Endpoint
resource privateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  name: 'default'
  parent: migratePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'migrate-config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// Create Azure Migrate Project
resource migrateProject 'Microsoft.Migrate/migrateProjects@2023-01-01' = {
  name: '${migrateProjectName}-migrateProjectName'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource assessmentsolution 'Microsoft.Migrate/MigrateProjects/Solutions@2023-01-01' = {
  name: '${migrateProjectName}-assessment'
  parent: migrateProject
  location: location
  tags: tags
  properties: {
    tool: ServerAssessment
    purpose: Assessment
    goal: 'Servers'
  }
}

resource discoverysolution 'Microsoft.Migrate/MigrateProjects/Solutions@2023-01-01' = {
  name: '${migrateProjectName}-discovery'
  parent: migrateProject
  location: location
  tags: tags
  properties: {
    tool: ServerDiscovery
    purpose: Discovery
    goal: 'Servers'
  }
}

resource migrationsolution 'Microsoft.Migrate/MigrateProjects/Solutions@2023-01-01' = {
  name: '${migrateProjectName}-migration'
  parent: migrateProject
  location: location
  tags: tags
  properties: {
    tool: ServerMigration
    purpose: Migration
    goal: 'Servers'
  }
}

resource migration_DataReplicationsolution 'Microsoft.Migrate/MigrateProjects/Solutions@2023-01-01' = {
  name: '${migrateProjectName}-migration_DataReplication'
  parent: migrateProject
  location: location
  tags: tags
  properties: {
    tool: ServerMigration_DataReplication
    purpose: Migration
    goal: 'Servers'
  }
}

// Outputs
@description('The resource ID of the Azure Migrate project')
output migrateProjectId string = migrateProject.id

@description('The name of the Azure Migrate project')
output migrateProjectName string = migrateProject.name

@description('The resource ID of the virtual network')
output virtualNetworkId string = virtualNetwork.id

@description('The private endpoint FQDN')
output privateEndpointFqdn string = '${migrateProjectName}.privatelink.prod.migration.windowsazure.com'

@description('The private endpoint IP address')
output privateEndpointIp string = migratePrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]

@description('The resource ID of the private endpoint')
output privateEndpointId string = migratePrivateEndpoint.id
