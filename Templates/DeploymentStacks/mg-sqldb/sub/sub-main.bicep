targetScope = 'subscription'

param resourceGroupName1 string = 'eaus_rg'
param resourceGroupLocation string = 'eastus'

resource demorg1 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName1
  location: resourceGroupLocation
}

module sql1 '../rg/rg-main.bicep' = if (resourceGroupName1 == 'eaus_rg') {
  name: uniqueString(resourceGroupName1)
  scope: demorg1
  params: {
    location: resourceGroupLocation
  }
}
