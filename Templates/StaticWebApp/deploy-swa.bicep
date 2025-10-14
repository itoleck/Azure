param subid string = ''
param staticSiteName string = 'myStaticWebApp'
param swalocation string = 'centralus'
param location string = 'northcentralus'
param skuName string = 'Standard'
param vnetResourceId string = ''
param subnetName string = 'Default'

resource staticSite 'Microsoft.Web/staticSites@2022-03-01' = {
  name: staticSiteName
  location: swalocation
  sku: {
    name: skuName
    tier: skuName
  }
  properties: {
    repositoryUrl: ''
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${staticSiteName}-pe'
  location: location
  properties: {
    subnet: {
      id: '${vnetResourceId}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${staticSiteName}-plsc'
        properties: {
          privateLinkServiceId: staticSite.id
          groupIds: ['staticSites']
          requestMessage: 'Please approve this connection.'
        }
      }
    ]
  }
}

resource privateDnsZone1 'Microsoft.Network/privateDnsZones@2018-09-01' ={
  name: 'privatelink.1.azurestaticapps.net'
  location: 'global'
}

resource privateDnsZone2 'Microsoft.Network/privateDnsZones@2018-09-01' ={
  name: 'privatelink.2.azurestaticapps.net'
  location: 'global'
}

resource privateDnsZone3 'Microsoft.Network/privateDnsZones@2018-09-01' ={
  name: 'privatelink.3.azurestaticapps.net'
  location: 'global'
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  parent: privateEndpoint
  name: '${privateEndpoint.name}-dns'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${staticSiteName}-zoneconfig'
        properties: {
          privateDnsZoneId: '/subscriptions/${subid}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/privateDnsZones/privatelink.1.azurestaticapps.net'
        }
      }
    ]
  }
}
