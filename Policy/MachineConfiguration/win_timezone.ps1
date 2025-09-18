
#Requires -module ComputerManagementDsc

Configuration TimeZone_SetTimeZone_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        TimeZone TimeZoneExample
        {
            IsSingleInstance = 'Yes'
            TimeZone         = 'Central Standard Time'
        }
    }
}
TimeZone_SetTimeZone_Config #Creates .\TimeZone_SetTimeZone_Config\localhost.mof