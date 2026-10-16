# Detailed Azure Site Recovery (ASR) Appliance Info

**Note:** ASR Appliance requires 16GB RAM and 8 non-HyperThreaded cores, so 16 vCores if using on Hyper-V.

ASR Appliance Processes and Services

[tutorial-migrate-physical-virtual-machines](https://docs.azure.cn/en-us/migrate/tutorial-migrate-physical-virtual-machines?view=migrate)

[Site Recovery REST API](https://learn.microsoft.com/en-us/rest/api/site-recovery/?view=rest-site-recovery-2025-08-01)

![ASR Appliance](/Migration/ASRAppliance.png)

|**Azure Service Name**|**Local Path on Appliance**|**Local Service on Appliance**|
|----------------------|---------------------------|------------------------------|
|Process Server|C:\Program Files\Microsoft Azure Site Recovery Process Server\home\svsystems\bin\ProcessServer.exe|Cxprocessserver - InMage CX Process Server|
|Replication service|C:\Program Files\Microsoft On-Premise to Azure Replication agent\RcmReplicationAgent.exe|Rcmreplicationagent - Microsoft On-Premise to Azure Replication agent|
|Recovery services agent|C:\Program Files\Microsoft Azure Recovery Services Agent\bin\CBEngine.exe|Obengine - Microsoft Azure Recovery Services Agent|
|Site Recovery provider|C:\Program Files\Microsoft Azure Site Recovery Provider\DraService.exe|Dra - Microsoft Azure Site Recovery Service|
|Re-protection server|C:\Program Files\Microsoft Azure to On-Premise Reprotect agent\RcmReprotectAgent.exe|Rcmreprotectagent - Microsoft Azure to On-Premise Reprotect agent|

## Azure Migrate project deployment

[MaC\bicep\migrate.bicep](MaC/bicep/migrate.bicep) creates a resource group and an
Azure Migrate project. Run [MaC\bicep\deploy.ps1](MaC/bicep/deploy.ps1) with
Azure PowerShell (`Az.Resources`) and the Bicep CLI installed and available on
`PATH`. Sign in with `Connect-AzAccount` and select the target subscription with
`Set-AzContext` before deploying.

Use an identity with Azure Migrate Owner or higher permissions and permission to
deploy at subscription scope and create the resource group. Choose a region
[supported by Azure Migrate](https://learn.microsoft.com/azure/migrate/supported-geographies).
If reusing a resource group, specify its existing location.

From the repository root, deploy a project with public connectivity:

```powershell
.\Migration\MaC\bicep\deploy.ps1 `
    -Name 'migrate-demo' `
    -ResourceGroupName 'migrate-rg' `
    -Location 'centralus' `
    -Connectivity Public
```

For private connectivity, supply an existing subnet resource ID:

```powershell
.\Migration\MaC\bicep\deploy.ps1 `
    -Name 'migrate-private' `
    -ResourceGroupName 'migrate-private-rg' `
    -Location 'centralus' `
    -Connectivity Private `
    -PrivateEndpointSubnetId '/subscriptions/<subscription-id>/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/migrate-vnet/subnets/private-endpoints'
```

Private mode disables public network access and creates a private endpoint in
the virtual network's region, the
`privatelink.prod.migration.windowsazure.com` private DNS zone, a virtual network
link, and a private DNS zone group. The subnet must have available IP addresses,
and the deploying identity needs permission to read the virtual network, join
the subnet, and link the private DNS zone to the virtual network. The network
may be in a different resource group or subscription.

The appliance needs connectivity to this network through peering, VPN, or
ExpressRoute. Configure DNS forwarding for on-premises/custom DNS as needed.
This template provisions the project and its connectivity, not appliances,
assessment/discovery tools, or their additional private endpoints. Add tools and
register appliances separately through Azure Migrate. Plan connectivity when
creating the project; Azure Migrate does not support converting an existing
public project to private endpoint connectivity.

The deployment returns `migrateProjectId` and `privateEndpointId`; the latter is
empty for public deployments.

Run the deployment script's isolated regression tests with the Windows
PowerShell 5.1 bundled Pester 3.4 runner. These tests mock Azure deployment calls
and do not provision resources:

```powershell
powershell.exe -NoProfile -Command "Import-Module Pester -RequiredVersion 3.4.0; Invoke-Pester -Script '.\Migration\MaC\bicep\tests\deploy.Tests.ps1'"
```
