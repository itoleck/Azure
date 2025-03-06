
@description('Generated from /subscriptions/6394c202-ce34-4741-90ce-c4be54bf9cb3/resourceGroups/scus_rg/providers/Microsoft.Network/networkSecurityGroups/testdcr2-nsg')
resource testdcrnsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'testdcr2-nsg'
  location: 'southcentralus'
  tags: {
    rgtag1: 'rgtagvalue2'
    Env: 'Production'
  }
  properties: {
    securityRules: [
      {
        name: 'RDP'
        id: '/subscriptions/6394c202-ce34-4741-90ce-c4be54bf9cb3/resourceGroups/scus_rg/providers/Microsoft.Network/networkSecurityGroups/testdcr2-nsg/securityRules/RDP'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'blocksshrdp-denyrule22-3389'
        id: '/subscriptions/6394c202-ce34-4741-90ce-c4be54bf9cb3/resourceGroups/scus_rg/providers/Microsoft.Network/networkSecurityGroups/testdcr2-nsg/securityRules/blocksshrdp-denyrule22-3389'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '22'
            '3389'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}
