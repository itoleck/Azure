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

module dnsZoneGroup 'dnsZoneGroup.bicep' = {
  name: 'dnsZoneGroupDeployment'
  params: {
    staticWebAppUrl: staticSite.properties.defaultHostname
    privateEndpointName: privateEndpoint.name
    // ... other params
  }
}
