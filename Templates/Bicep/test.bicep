

//This was imported from Azure
@description('Generated from /subscriptions/9258645e-d179-40b9-9eb2-27bf957d679a/resourceGroups/northcentralusrg/providers/Microsoft.Compute/virtualMachines/AzDC1')
resource AzDC 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'AzDC1'
  location: 'northcentralus'
  tags: {
    tag1: 'chaos'
  }
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/9258645e-d179-40b9-9eb2-27bf957d679a/resourceGroups/northcentralusRG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/chaosidentity': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    applicationProfile: {
      galleryApplications: [
        {
          manuallyManaged: false
          packageReferenceId: '/subscriptions/9258645e-d179-40b9-9eb2-27bf957d679a/resourceGroups/northcentralusRG/providers/Microsoft.Compute/galleries/northcentraluscomputegallery/applications/7-zip/versions/24.08.0'
          treatFailureAsDeploymentFailure: false
          enableAutomaticUpgrade: false
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-smalldisk'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: 'AzDC1_OsDisk_1_15252055871941afad29f83a55ed6f24'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          id: '/subscriptions/9258645e-d179-40b9-9eb2-27bf957d679a/resourceGroups/NORTHCENTRALUSRG/providers/Microsoft.Compute/disks/AzDC1_OsDisk_1_15252055871941afad29f83a55ed6f24'
        }
        deleteOption: 'Detach'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: 'AzDC1'
      adminUsername: 'chad'
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            bypassPlatformSafetyChecksOnUserSchedule: true
          }
          assessmentMode: 'AutomaticByPlatform'
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: '/subscriptions/9258645e-d179-40b9-9eb2-27bf957d679a/resourceGroups/northcentralusRG/providers/Microsoft.Network/networkInterfaces/azdc1386'
        }
      ]
    }
    licenseType: 'Windows_Server'
  }
}
