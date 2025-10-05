#This script will query Azure for compute images in a GUI
#Chad Schultz https://github.com/itoleck/VariousScripts/tree/main/Azure

$loc = (Get-AzLocation | Sort-Object -Property Location | Select-Object Location | Out-GridView -PassThru)

#$loc = (Read-Host -Prompt "Enter Location ")
$pub = (Get-AzVMImagePublisher -Location $loc.Location | Sort-Object -Property PublisherName | Select-Object PublisherName | Out-GridView -PassThru)

#$pub = (Read-Host -Prompt "Enter Publisher ")
$offer = (Get-AzVMImageOffer -PublisherName $pub.PublisherName -Location $loc.Location | Sort-Object -Property Offer | Select-Object Offer | Out-GridView -PassThru)

#$offer = (Read-Host -Prompt "Enter Offer ")
$sku = (Get-AzVMImageSku -Offer $offer.Offer -PublisherName $pub.PublisherName -Location $loc.Location | Sort-Object -Property Skus | Select-Object Skus | Out-GridView -PassThru)

#$sku = (Read-Host -Prompt "Enter SKU ")
Get-AzVMImage -Location $loc.Location -PublisherName $pub.PublisherName -Offer $offer.Offer -Skus $sku.Skus | Select-Object PublisherName, Offer, Skus, Version

#Output a table based on offer
#az vm image list --offer Redhat --all --output table