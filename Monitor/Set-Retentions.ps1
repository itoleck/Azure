param (
    [Parameter(Mandatory=$true, HelpMessage = "Resource Group name")][string] $RGName,
    [Parameter(Mandatory=$true, HelpMessage = "Log Analytics Workspace name")][string] $WorkspaceName,
    [Parameter(Mandatory=$false, HelpMessage = "Retention in days, use -1 to set to default for workspace")][int] $RetentionDays = 30,
    [Parameter(Mandatory=$false, HelpMessage = "Show the current table retention settings only")][boolean] $ShowOnly = $false
)

#https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-retention-archive?tabs=PowerShell-1%2CPowerShell-2
$90dayfreetables = 'Usage','AzureActivity','AppAvailabilityResults','AppBrowserTimings','AppDependencies','AppExceptions','AppEvents','AppMetrics','AppPageViews','AppPerformanceCounters','AppRequests','AppSystemEvents','AppTraces'

$tbls = Get-AzOperationalInsightsTable -ResourceGroupName $RGName -WorkspaceName $WorkspaceName

if ($ShowOnly) {
    $tbls | Select-Object Name, RetentionInDays, TotalRetentionInDays | Sort-Object Name
} else {
    foreach ($tbl in $tbls) {
        #Just set these tables to 90 days in the retention set to < 90 b/c it's free
        if (($tbl -in $90dayfreetables) -and ($RetentionDays -lt 90)) {
            Update-AzOperationalInsightsTable -ResourceGroupName $RGName -WorkspaceName $WorkspaceName -RetentionInDays 90 -TotalRetentionInDays 90 -TableName $tbl
        } else {
            Update-AzOperationalInsightsTable -ResourceGroupName $RGName -WorkspaceName $WorkspaceName -RetentionInDays $RetentionDays -TotalRetentionInDays $RetentionDays -TableName $tbl
        }
    }
}