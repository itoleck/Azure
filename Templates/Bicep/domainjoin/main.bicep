
param vmName string
param domainToJoin string
param domainUsername string
param ouPath string
param domainJoinOptions string = '3'

@secure()
param domainJoinPassword string

resource domainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  name: '${vmName}/joindomain'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainToJoin
      OUPath: ouPath
      User: domainUsername
      Password: ''
      Restart: 'true'
      Options: domainJoinOptions
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
}
