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
