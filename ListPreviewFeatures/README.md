Newest list of Azure resources and preview status in providers.csv.


#Step 1.
Get the provider to service mappings from https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-services-resource-providers
Manually select all text in HTML table including header and paste into Excel and save as .\providermapping.csv

#Step 2.
Update .\DumpProviderInfo.ps1 with login information.
Get the providers debug information.
Start-Process -FilePath pwsh.exe -ArgumentList "-File .\DumpProviderInfo.ps1" -RedirectStandardOutput ".\providers-api.json"

#Step 3.
Run .\AzureProviderList.ps1 which will write the provider list to the path in $finalfile variable(.\providers.csv)
