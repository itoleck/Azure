param staticSiteName string = 'myStaticWebApp'
param location string = resourceGroup().location
param skuName string = 'Standard'

resource staticSite 'Microsoft.Web/staticSites@2022-09-01' = {
  name: staticSiteName
  location: location
  sku: {
    name: skuName
    tier: skuName
  }
  properties: {
    deploymentAuthPolicy: 'DeploymentToken'
    enterpriseGradeCdnStatus: 'disabled'
  }
}
