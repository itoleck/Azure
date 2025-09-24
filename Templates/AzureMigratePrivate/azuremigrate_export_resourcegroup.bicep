param virtualNetworks_AzMigrateVNet_name string = 'AzMigrateVNet'
param migrateProjects_azmigrateCentralProject1_name string = 'azmigrateCentralProject1'
param privateEndpoints_azmigratecentralproject11004pe_name string = 'azmigratecentralproject11004pe'
param privateDnsZones_privatelink_prod_migration_windowsazure_com_name string = 'privatelink.prod.migration.windowsazure.com'
param location string = 'centralus'

resource migrateProjects_azmigrateCentralProject1_name_resource 'Microsoft.Migrate/migrateProjects@2020-05-01' = {
  name: migrateProjects_azmigrateCentralProject1_name
  location: location
  tags: {
    'Migrate Project': 'azmigrateCentralProject1'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    registeredTools: [
      'ServerAssessment'
      'ServerDiscovery'
      'ServerMigration'
    ]
    publicNetworkAccess: 'Disabled'
    serviceEndpoint: 'https://6f40b3b3-12f5-4b90-acb0-da01addc92b5-isv.wus2.hub.privatelink.prod.migration.windowsazure.com/resources/6f40b3b3-12f5-4b90-acb0-da01addc92b5'
  }
}

resource privateDnsZones_privatelink_prod_migration_windowsazure_com_name_resource 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDnsZones_privatelink_prod_migration_windowsazure_com_name
  location: 'global'
  properties: {}
}

resource virtualNetworks_AzMigrateVNet_name_resource 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: virtualNetworks_AzMigrateVNet_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    privateEndpointVNetPolicies: 'Disabled'
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefixes: [
            '10.20.0.0/24'
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'privendpoint'
        properties: {
          addressPrefixes: [
            '10.20.1.0/24'
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource migrateProjects_azmigrateCentralProject1_name_Servers_Assessment_ServerAssessment 'Microsoft.Migrate/MigrateProjects/Solutions@2018-09-01-preview' = {
  parent: migrateProjects_azmigrateCentralProject1_name_resource
  name: 'Servers-Assessment-ServerAssessment'
  properties: {
    tool: 'ServerAssessment'
    purpose: 'Assessment'
    goal: 'Servers'
    status: 'Active'
    cleanupState: 'None'
    summary: {
      instanceType: 'Servers'
      discoveredCount: 0
      assessedCount: 0
      replicatingCount: 0
      testMigratedCount: 0
      migratedCount: 0
    }
    details: {
      groupCount: 0
      assessmentCount: 0
      extendedDetails: {}
    }
  }
}

resource migrateProjects_azmigrateCentralProject1_name_Servers_Discovery_ServerDiscovery 'Microsoft.Migrate/MigrateProjects/Solutions@2018-09-01-preview' = {
  parent: migrateProjects_azmigrateCentralProject1_name_resource
  name: 'Servers-Discovery-ServerDiscovery'
  properties: {
    tool: 'ServerDiscovery'
    purpose: 'Discovery'
    goal: 'Servers'
    status: 'Inactive'
    cleanupState: 'None'
    summary: {
      instanceType: 'Servers'
      discoveredCount: 0
      assessedCount: 0
      replicatingCount: 0
      testMigratedCount: 0
      migratedCount: 0
    }
    details: {
      groupCount: 0
      assessmentCount: 0
      extendedDetails: {
        privateEndpointDetails: '{"subnetId":"/subscriptions/6394c202-ce34-4741-90ce-c4be54bf9cb3/resourceGroups/AzMigrateCentralTest/providers/Microsoft.Network/virtualNetworks/AzMigrateVNet/subnets/privendpoint","virtualNetworkLocation":"centralus","skipPrivateDnsZoneCreation":false}'
      }
    }
  }
}

resource migrateProjects_azmigrateCentralProject1_name_Servers_Migration_ServerMigration 'Microsoft.Migrate/MigrateProjects/Solutions@2018-09-01-preview' = {
  parent: migrateProjects_azmigrateCentralProject1_name_resource
  name: 'Servers-Migration-ServerMigration'
  properties: {
    tool: 'ServerMigration'
    purpose: 'Migration'
    goal: 'Servers'
    status: 'Active'
    cleanupState: 'None'
    summary: {
      instanceType: 'Servers'
      discoveredCount: 0
      assessedCount: 0
      replicatingCount: 0
      testMigratedCount: 0
      migratedCount: 0
    }
    details: {
      groupCount: 0
      assessmentCount: 0
      extendedDetails: {}
    }
  }
}

resource migrateProjects_azmigrateCentralProject1_name_Servers_Migration_ServerMigration_DataReplication 'Microsoft.Migrate/MigrateProjects/Solutions@2018-09-01-preview' = {
  parent: migrateProjects_azmigrateCentralProject1_name_resource
  name: 'Servers-Migration-ServerMigration_DataReplication'
  properties: {
    tool: 'ServerMigration_DataReplication'
    purpose: 'Migration'
    goal: 'Servers'
    status: 'Inactive'
    cleanupState: 'None'
    summary: {
      instanceType: 'Servers'
      discoveredCount: 0
      assessedCount: 0
      replicatingCount: 0
      testMigratedCount: 0
      migratedCount: 0
    }
    details: {
      groupCount: 0
      assessmentCount: 0
      extendedDetails: {}
    }
  }
}

resource privateDnsZones_privatelink_prod_migration_windowsazure_com_name_A 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  parent: privateDnsZones_privatelink_prod_migration_windowsazure_com_name_resource
  name: migrateProjects_azmigrateCentralProject1_name
  properties: {
    metadata: {
      creator: 'Azure Migration'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.20.1.4'
      }
    ]
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_privatelink_prod_migration_windowsazure_com_name 'Microsoft.Network/privateDnsZones/SOA@2024-06-01' = {
  parent: privateDnsZones_privatelink_prod_migration_windowsazure_com_name_resource
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}



resource privateDnsZones_privatelink_prod_migration_windowsazure_com_name_azmigratevnet1113vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZones_privatelink_prod_migration_windowsazure_com_name_resource
  name: 'azmigratevnet1113vnetlink'
  location: 'global'
  properties: {
    registrationEnabled: false
    resolutionPolicy: 'Default'
    virtualNetwork: {
      id: virtualNetworks_AzMigrateVNet_name_resource.id
    }
  }
}

resource privateEndpoints_azmigratecentralproject11004pe_name_resource 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: privateEndpoints_azmigratecentralproject11004pe_name
  location: location
  tags: {
    MigrateProject: 'azmigrateCentralProject1'
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpoints_azmigratecentralproject11004pe_name
        properties: {
          privateLinkServiceId: migrateProjects_azmigrateCentralProject1_name_resource.id
          groupIds: [
            'Default'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '${virtualNetworks_AzMigrateVNet_name_resource.id}/subnets/privendpoint'
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource privateEndpoints_azmigratecentralproject11004pe_name_azmigratecentralproject11004dnszonegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = {
  parent: privateEndpoints_azmigratecentralproject11004pe_name_resource
  name: 'azmigratecentralproject11004dnszonegroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.prod.migration.windowsazure.com'
        properties: {
          privateDnsZoneId: privateDnsZones_privatelink_prod_migration_windowsazure_com_name_resource.id
        }
      }
    ]
  }
}
