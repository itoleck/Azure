# Detailed Azure Site Recovery (ASR) Appliance Info

ASR Appliance Processes and Services

![ASR Appliance](/Migration/ASRAppliance.png)

|**Azure Service Name**|**Local Path on Appliance**|**Local Service on Appliance**|
|----------------------|---------------------------|------------------------------|
|Process Server|C:\Program Files\Microsoft Azure Site Recovery Process Server\home\svsystems\bin\ProcessServer.exe|Cxprocessserver - InMage CX Process Server|
|Replication service|C:\Program Files\Microsoft On-Premise to Azure Replication agent\RcmReplicationAgent.exe|Rcmreplicationagent - Microsoft On-Premise to Azure Replication agent|
|Recovery services agent|C:\Program Files\Microsoft Azure Recovery Services Agent\bin\CBEngine.exe|Obengine - Microsoft Azure Recovery Services Agent|
|Site Recovery provider|C:\Program Files\Microsoft Azure Site Recovery Provider\DraService.exe|Dra - Microsoft Azure Site Recovery Service|
|Re-protection server|C:\Program Files\Microsoft Azure to On-Premise Reprotect agent\RcmReprotectAgent.exe|Rcmreprotectagent - Microsoft Azure to On-Premise Reprotect agent|
