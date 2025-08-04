targetScope = 'subscription'

param resourceGroupName1 string = 'mgstackstoragesub_rg'
param resourceGroupLocation string = deployment().location

resource demorg1 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName1
  location: resourceGroupLocation
}

module firstStorage '../rg/rg_main.bicep' = if (resourceGroupName1 == 'mgstackstoragesub_rg') {
  name: uniqueString(resourceGroupName1)
  scope: demorg1
  params: {
    location: resourceGroupLocation
  }
}
