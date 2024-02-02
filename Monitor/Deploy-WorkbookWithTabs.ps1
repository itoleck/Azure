param (
    [Parameter(Mandatory=$true)][string] $ResourceGroup
)

az deployment group create --resource-group $ResourceGroup --template-file '.\WorkbookWithTabs.json'