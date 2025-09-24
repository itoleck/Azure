New-AzResourceGroupDeployment `
  -Name "azmigprivDeploymentbicep" `
  -ResourceGroupName "azmigbiceptcentRG" `
  -TemplateFile ".\azuremigrate_export_resourcegroup.bicep"