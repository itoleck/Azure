param(
    # Resource Group Name
    [Parameter(Mandatory=$true)][string] $ResourceGroupName,
    [Parameter(Mandatory=$false)][hashtable] $myObject = @{
        tag1 = "deploydefault1"
        tag2 = "deploydefault2"
        tag3 = "deploydefault3"
    }
)

New-AzResourceGroupDeployment `
  -Name "VNetBicepDeployment" `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile ".\main.bicep" `
  -myObject $myObject
#  -TemplateParameterFile ".\object.bicepparam"

#AzureCLI can also be used within PowerShell
#az deployment group create `
#--resource-group $ResourceGroupName `
#--template-file ".\main.bicep" `
#--parameters ".\object.bicepparam"