param staticWebAppUrl string
param privateEndpointName string

resource privateDnsZoneGroup 'Microsoft.Network/privateDnsZoneGroups@2021-05-01' = {
  name: '${privateEndpointName}-dns'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'staticwebapp'
        properties: {
          // You can use staticWebAppUrl here if needed for custom logic
          // For standard Azure Static Web Apps, the DNS zone is usually privatelink.azurestaticapps.net
          privateDnsZoneId: '/subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Network/privateDnsZones/privatelink.azurestaticapps.net'
        }
      }
    ]
  }
}
