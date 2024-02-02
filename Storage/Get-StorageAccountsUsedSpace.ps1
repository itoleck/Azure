Param(
    [Parameter(Mandatory=$true)][string] $SubscriptionID,
    [Parameter(Mandatory=$true)][string] $ResourceGroups
)

$AzContextPath = "$($env:TEMP)\$(Get-Date -Format yyyyMMdd)AzEnv.json"
$maxsizetoreport = (1024)

$azcontext = Set-AzContext -SubscriptionId $SubscriptionID
Save-AzContext -Path $AzContextPath -Force

Write-Output ('Getting Azure Storage Account capacity metrics')
Write-Output ('Subscription: {0}' -f $azcontext.Name)
Write-Output ('Resource groups: {0}' -f $ResourceGroups)
Write-Output ('Current Used Capacity Assessment >= {0:N0} bytes' -f $maxsizetoreport)

$storagetypes = @('','/blobServices/default','/fileServices/default','/queueServices/default','/tableServices/default')
$usedcapacities = @('UsedCapacity','BlobCapacity','FileCapacity','QueueCapacity','TableCapacity')

#($ResourceGroups.Split(',')) | ForEach-Object  {
    ($ResourceGroups.Split(',')) | ForEach-Object -Parallel {
    Import-AzContext -Path $using:AzContextPath

    Write-Host ($using:AzContextPath)
    Write-Host (Get-AzContext).SubscriptionId

    $sas = Get-AzStorageAccount -ResourceGroupName $_

    $TimeGrain = [timespan]::FromMinutes(60)
    $Start = [datetime]::Now.AddMinutes(-240)
    $End = [datetime]::Now.AddMinutes(-0)
    $storageinfo = New-Object System.Collections.ArrayList

    if($sas.count -gt 0) {
        foreach($sa in $sas){
            foreach($storagetype in $using:storagetypes) {
                $StorAcc=New-Object MyStorageMetricsUsed

                $ResourceID = $sa.Id + $storagetype
                $MetricName = $using:usedcapacities[($using:storagetypes.IndexOf($storagetype))]
                
                $Splat = @{
                    ResourceId = $ResourceID
                    MetricName = $MetricName
                    TimeGrain = $TimeGrain
                    StartTime = $Start
                    EndTime = $End
                }
                
                $data=Get-AzMetric @Splat -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                
                try {
                    if($data.Data[0].Average -gt 0) {
                        $StorAcc.KbUsed = (($data.Data[0].Average) / $using:maxsizetoreport)
                    } else {
                        $StorAcc.KbUsed = 0
                    }
                    #if($StorAcc.KbUsed -gt 1) {
                        $StorAcc.AccountName = $ResourceID
                        $StorAcc.UsedPercent = $StorAcc.KbUsed / $StorAcc.AccountKbMAX
                        $null=$storageinfo.Add($StorAcc)
                    #}
                }
                catch {
                    
                }
            }
        }
    }
    $storageinfo | Select-Object KbUsed, UsedPercent, AccountName | Format-Table -AutoSize
}

Class MyStorageMetricsUsed {
    [String]$AccountName
    [Double]$KbUsed
    [Double]$AccountKbMAX = 5497558138880
    [Double]$BlobKbMAX = 5497558138880
    [Double]$FilesKbMAX = 107374182400
    [Double]$TablesKbMAX = 107374182400
    [Double]$QueuesKbMAX = 107374182400
    [Double]$UsedPercent
}