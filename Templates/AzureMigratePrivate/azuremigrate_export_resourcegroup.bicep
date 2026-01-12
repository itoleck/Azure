// https://learn.microsoft.com/en-us/azure/templates/microsoft.migrate/allversions?view=migrate

param AzMigrateVNetID string = '/subscriptions/<subid>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Network/virtualNetworks/<VirtualNetworkName>'
param AzMigrateVNetSubnetName string = '<Subnet Name>'
param virtualNetworkLocation string = '<VNet Location>'
param migrateProjects_azmigrateCentralProject1_name string = 'AzMigratePrivate1'
param privateEndpoints_azmigratecentralproject11004pe_name string = 'AzMigratePrivate1-PE'
param privateDnsZones_privatelink string = 'AzMigratePrivate1-PL'
param privateDnsZones_privatelink_prod_migration_windowsazure_com_name string = 'privatelink.prod.migration.windowsazure.com'
param location string = '<MigrateProjectLocation i.e. centralus>'

resource migrateProjects_azmigrateCentralProject1_name_resource 'Microsoft.Migrate/migrateProjects@2020-05-01' = {
  name: migrateProjects_azmigrateCentralProject1_name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    MigrateProject: migrateProjects_azmigrateCentralProject1_name
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    serviceEndpoint: ''
  }
}

resource migrateProjects_azmigrateCentralProject1_name_Servers_Assessment_ServerAssessment 'Microsoft.Migrate/MigrateProjects/Solutions@2020-05-01' = {
  parent: migrateProjects_azmigrateCentralProject1_name_resource
  name: 'ServersAssessment'
  properties: {
    tool: 'ServerAssessment'
    purpose: 'Assessment'
    goal: 'Servers'
    status: 'Active'
    cleanupState: 'None'
  }
}

resource migrateProjects_azmigrateCentralProject1_name_Servers_Discovery_ServerDiscovery 'Microsoft.Migrate/MigrateProjects/Solutions@2020-05-01' = {
  parent: migrateProjects_azmigrateCentralProject1_name_resource
  name: 'ServersDiscovery'
  properties: {
    tool: 'ServerDiscovery'
    purpose: 'Discovery'
    goal: 'Servers'
    status: 'Active'
    cleanupState: 'None'
    details: {
      extendedDetails: {
        privateEndpointDetails: '{"subnetId":"${AzMigrateVNetID}/subnets/${AzMigrateVNetSubnetName}","virtualNetworkLocation":"${virtualNetworkLocation}","skipPrivateDnsZoneCreation":false}'
      }
    }
  }
}

resource migrateProjects_azmigrateCentralProject1_name_Servers_Migration_ServerMigration 'Microsoft.Migrate/MigrateProjects/Solutions@2020-05-01' = {
  parent: migrateProjects_azmigrateCentralProject1_name_resource
  name: 'ServersMigration'
  properties: {
    tool: 'ServerMigration'
    purpose: 'Migration'
    goal: 'Servers'
    status: 'Active'
    cleanupState: 'None'
  }
}

resource migrateProjects_azmigrateCentralProject1_name_Servers_Migration_ServerMigration_Replication 'Microsoft.Migrate/MigrateProjects/Solutions@2020-05-01' = {
  parent: migrateProjects_azmigrateCentralProject1_name_resource
  name: 'ServerMigrationRepl'
  properties: {
    tool: 'ServerMigration_Replication'
    purpose: 'Migration'
    goal: 'Servers'
    status: 'Active'
    cleanupState: 'None'
  }
}

/* resource privateDnsZones_privatelink_prod_migration_windowsazure_com_name_A 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
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
} */

resource privateDnsZones_privatelink_prod_migration_windowsazure_com_name_resource 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDnsZones_privatelink_prod_migration_windowsazure_com_name
  location: 'global'
  properties: {}
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
  name: privateDnsZones_privatelink
  location: 'global'
  properties: {
    registrationEnabled: false
    resolutionPolicy: 'Default'
    virtualNetwork: {
      id: AzMigrateVNetID
    }
  }
}

resource privateEndpoints_azmigratecentralproject11004pe_name_resource 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: privateEndpoints_azmigratecentralproject11004pe_name
  location: virtualNetworkLocation
  tags: {
    MigrateProject: migrateProjects_azmigrateCentralProject1_name
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
      id: '${AzMigrateVNetID}/subnets/${AzMigrateVNetSubnetName}'
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource privateEndpoints_azmigratecentralproject11004pe_name_azmigratecentralproject11004dnszonegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = {
  parent: privateEndpoints_azmigratecentralproject11004pe_name_resource
  name: '${privateEndpoints_azmigratecentralproject11004pe_name}dnszonegroup'
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

output privateEndpointDetails string = '{"subnetId":"${AzMigrateVNetID}/subnets/${AzMigrateVNetSubnetName}","virtualNetworkLocation":"${virtualNetworkLocation}","skipPrivateDnsZoneCreation":false}'
