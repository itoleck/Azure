@description('Azure Migrate project name.')
param projectName string

@description('Azure Migrate project resource ID.')
param projectId string

@description('Existing subnet resource ID in the format /subscriptions/{id}/resourceGroups/{group}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}.')
@minLength(1)
param subnetId string

@description('Azure region of the existing virtual network.')
param location string

@description('Resource ID of the existing virtual network containing the subnet.')
param virtualNetworkId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${projectName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${projectName}-connection'
        properties: {
          privateLinkServiceId: projectId
          groupIds: [
            'Default'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.prod.migration.windowsazure.com'
  location: 'global'
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: 'migrate-${uniqueString(virtualNetworkId)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'migrate'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id
