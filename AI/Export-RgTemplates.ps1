<#
.SYNOPSIS
    Exports the ARM template of every resource in an Azure Resource Group to individual .json files.

.DESCRIPTION
    Enumerates all resources in the given resource group and runs Export-AzResourceGroup
    once per resource, saving each template as <ResourceType>_<ResourceName>.json in the
    output folder. Also exports one full resource-group template (_full-resource-group.json).

.PARAMETER ResourceGroupName
    Name of the resource group to export.

.PARAMETER OutputFolder
    Folder to save the .json files to. Created if it doesn't exist. Defaults to
    .\<ResourceGroupName>-templates under the current directory.

.PARAMETER SubscriptionId
    Optional subscription to switch to before exporting.

.EXAMPLE
    .\Export-RgTemplates.ps1 -ResourceGroupName lalabel-rg-cus

.EXAMPLE
    .\Export-RgTemplates.ps1 -ResourceGroupName lalabel-rg-cus -OutputFolder C:\exports\lalabel -SubscriptionId 0000000-0000-0000-0000-000000000000

.NOTES
    Requires the Az PowerShell module (Install-Module Az) and an active login (Connect-AzAccount).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = (Join-Path (Get-Location) "$ResourceGroupName-templates"),

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId
)

$ErrorActionPreference = 'Stop'

# --- Prerequisites -----------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    throw "The Az.Resources module is not installed. Run: Install-Module Az -Scope CurrentUser"
}

if (-not (Get-AzContext)) {
    Write-Host "Not logged in to Azure. Launching Connect-AzAccount..." -ForegroundColor Yellow
    Connect-AzAccount | Out-Null
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

$context = Get-AzContext
Write-Host "Subscription : $($context.Subscription.Name) ($($context.Subscription.Id))"
Write-Host "ResourceGroup: $ResourceGroupName"

# Verify the resource group exists before doing anything else
Get-AzResourceGroup -Name $ResourceGroupName | Out-Null

if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}
Write-Host "OutputFolder : $OutputFolder`n"

# --- Helper: make a safe file name from resource type + name ------------------
function Get-SafeFileName {
    param([string]$ResourceType, [string]$ResourceName)
    # e.g. "Microsoft.Network/applicationGateways" -> "Microsoft.Network_applicationGateways"
    $raw = ($ResourceType -replace '/', '_') + '_' + $ResourceName
    $invalid = [System.IO.Path]::GetInvalidFileNameChars() -join ''
    $safe = $raw -replace "[$([regex]::Escape($invalid))]", '-'
    return "$safe.json"
}

# --- Export each resource individually ----------------------------------------
$resources = Get-AzResource -ResourceGroupName $ResourceGroupName
Write-Host "Found $($resources.Count) resources.`n"

$succeeded = 0
$failed = @()

foreach ($resource in $resources) {
    $fileName = Get-SafeFileName -ResourceType $resource.ResourceType -ResourceName $resource.Name
    $filePath = Join-Path $OutputFolder $fileName

    Write-Host "Exporting $($resource.ResourceType) / $($resource.Name) ..." -NoNewline
    try {
        # Export-AzResourceGroup writes the file itself via -Path
        Export-AzResourceGroup -ResourceGroupName $ResourceGroupName `
                               -Resource $resource.ResourceId `
                               -Path $filePath `
                               -IncludeParameterDefaultValue `
                               -Force `
                               -WarningAction SilentlyContinue | Out-Null
        Write-Host " OK -> $fileName" -ForegroundColor Green
        $succeeded++
    }
    catch {
        Write-Host " FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $failed += [pscustomobject]@{
            Name  = $resource.Name
            Type  = $resource.ResourceType
            Error = $_.Exception.Message
        }
    }
}

# --- Export the whole resource group as one template ---------------------------
Write-Host "`nExporting full resource-group template ..." -NoNewline
try {
    $fullPath = Join-Path $OutputFolder '_full-resource-group.json'
    Export-AzResourceGroup -ResourceGroupName $ResourceGroupName `
                           -Path $fullPath `
                           -IncludeParameterDefaultValue `
                           -Force `
                           -WarningAction SilentlyContinue | Out-Null
    Write-Host " OK -> _full-resource-group.json" -ForegroundColor Green
}
catch {
    Write-Host " FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# --- Summary -------------------------------------------------------------------
Write-Host "`n===== Summary ====="
Write-Host "Exported: $succeeded of $($resources.Count) resources"
if ($failed.Count -gt 0) {
    Write-Host "Failed  : $($failed.Count)" -ForegroundColor Red
    $failed | Format-Table -AutoSize
    exit 1
}
