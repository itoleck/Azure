param servers_ptlp7w6h5f_name string = 'ptlp7w6h5f'
param location string = resourceGroup().location

resource servers_ptlp7w6h5f_name_backupltrtst 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  name: '${servers_ptlp7w6h5f_name}/backupltrtst'
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  kind: 'v12.0,user,vcore,serverless'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    autoPauseDelay: -1
    requestedBackupStorageRedundancy: 'Local'
    minCapacity: json('0.5')
    maintenanceConfigurationId: '/subscriptions/6394c202-ce34-4741-90ce-c4be54bf9cb3/providers/Microsoft.Maintenance/publicMaintenanceConfigurations/SQL_Default'
    isLedgerOn: false
    availabilityZone: 'NoPreference'
  }
}
