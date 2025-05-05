param vmName string
param domainToJoin string
param domainUsername string
param ouPath string
param domainJoinOptions int = 3 // Modify as needed
param keyVaultName string
param secretName string

resource kv 'Microsoft.KeyVault/vaults@2021-06-01' existing = {
  name: keyVaultName
}

resource domainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  name: '${vmName}/joindomain'
  location: location
  parent: vm
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainToJoin
      OUPath: ouPath
      User: '${domainToJoin}\\${domainUsername}'
      Restart: true
      Options: domainJoinOptions
    }
    protectedSettings: {
      Password: kv.getSecret(secretName)
    }
  }
}
