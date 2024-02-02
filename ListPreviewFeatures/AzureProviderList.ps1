$finalfile="C:\temp\providers.csv"
$mappingfile="C:\temp\providermapping.csv"
$providerdebugfile="C:\temp\providers-api.json"

#Step 1.
#Get the provider to service mappings from https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-services-resource-providers
#Manually select all text in HTML table including header and paste into Excel and save as .csv
$raw=Get-Content -Path $mappingfile
$map=ConvertFrom-Csv -InputObject $raw

#Step 2.
#Get the providers debug information. Copy-pasted from terminal window json into C:\temp\providers-api.json from running 'Get-AzResourceProvider -ListAvailable -Debug'
$json=Get-Content -Path $providerdebugfile -Raw
$json=$json.replace(" - registered","")
$pobj=$json|ConvertFrom-Json

#Step 3.
#Run this PowerShell script which will write the provider list to the path in $finalfile variable


#Start script
#$pobj.value[0].resourceTypes[0]
if(Test-Path -Path $finalfile) { Remove-Item -Path $finalfile }

"""Provider Name"",""Service Name"",""Preview"""|Out-File -FilePath $finalfile -Force

foreach($provider in $pobj.value) {

    foreach($m in $map) {
        if($m.'Resource provider namespace' -ieq $provider.namespace.Split("/")[0]) {
        $asvc = $m.'Azure service'
        }
    }

    $f="""{0}/*"",""{1}""" -f $provider.namespace,$asvc
    $f|Out-File -FilePath $finalfile -Append
    foreach($resourcetype in $provider.resourceTypes) {
        
        $pre=$true;foreach($api in $resourcetype.apiVersions) { try {$d=[DateTime]$api;$pre=$false} catch {} }

        foreach($m in $map) {
            if($m.'Resource provider namespace' -ieq $provider.namespace.Split("/")[0]) {
            $asvc = $m.'Azure service'
            }
        }

        $f="""{0}/{1}"",""{3}"",""{2}""" -f $provider.namespace,$resourcetype.resourceType,$pre,$asvc

        $f|Out-File -FilePath $finalfile -Append
        $asvc = ""
    }
}
