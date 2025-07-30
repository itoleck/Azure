targetScope = 'managementGroup'

param subscriptionID string

param deployLocation string = deployment().location

module subDeployModule '../sub/sub-main.bicep' = {
  name: 'deployToSub'
  params: { resourceGroupLocation: deployLocation }
  scope: subscription(subscriptionID)
}
