param name string = 'swa-gpt-central'
param location string = 'centralus'
param sku string = 'Standard'
param skuCode string = 'Standard'
param enterpriseGradeCdnStatus string = 'disabled'

resource staticSite 'Microsoft.Web/staticSites@2022-09-01' = {
  name: name
  location: location
  tags: {}
  sku: {
    tier: sku
    name: skuCode
  }
  properties: {
    deploymentAuthPolicy: 'DeploymentToken'
    enterpriseGradeCdnStatus: enterpriseGradeCdnStatus
  }
}
