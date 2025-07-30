targetScope = 'subscription'

param resourceGroupName1 string = 'mgstackstorage_rg'
param resourceGroupLocation string = deployment().location

resource demorg1 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName1
  location: resourceGroupLocation
}

module firstStorage '../rg/rg-main.bicep' = if (resourceGroupName1 == 'mgstackstorage_rg') {
  name: uniqueString(resourceGroupName1)
  scope: demorg1
  params: {
    location: resourceGroupLocation
  }
}
