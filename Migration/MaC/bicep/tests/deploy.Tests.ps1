#Requires -Modules Az.Resources, Pester

Describe 'Azure Migrate deployment' {
    # Avoid Azure's dynamic Bicep parameter discovery when mocking the alias target.
    function New-AzDeployment {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'The static signature is used by Pester mocks.')]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This test stub never changes Azure resources.')]
        [CmdletBinding()]
        param(
            [string] $Name,
            [string] $TemplateFile,
            [string] $Location,
            [hashtable] $TemplateParameterObject
        )

        throw 'Azure deployments must be mocked in these tests.'
    }

    BeforeEach {
        $script:deployScript = Join-Path $PSScriptRoot '..\deploy.ps1'
        $script:parameters = @{
            Name = 'migrate-test'
            ResourceGroupName = 'migrate-test-rg'
            Location = 'centralus'
        }
        $script:subnetId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/migrate-vnet/subnets/private-endpoints'

        Mock New-AzDeployment {
            [pscustomobject]@{
                DeploymentName = $Name
                TemplateFile = $TemplateFile
                Location = $Location
                Parameters = $TemplateParameterObject
            }
        }
    }

    It 'passes the project settings and defaults to public connectivity' {
        $result = & $script:deployScript @script:parameters

        $result.DeploymentName | Should Be 'migrate-test-deployment'
        $result.Location | Should Be 'centralus'
        $result.Parameters.name | Should Be 'migrate-test'
        $result.Parameters.resourceGroupName | Should Be 'migrate-test-rg'
        $result.Parameters.location | Should Be 'centralus'
        $result.Parameters.connectivity | Should Be 'Public'
        $result.Parameters.privateEndpointSubnetId | Should Be ''
        Assert-MockCalled New-AzDeployment -Times 1 -Exactly -Scope It
    }

    It 'passes the subnet and normalizes private connectivity casing' {
        $result = & $script:deployScript @script:parameters -Connectivity private -PrivateEndpointSubnetId $script:subnetId

        $result.Parameters.connectivity | Should Be 'Private'
        $result.Parameters.privateEndpointSubnetId | Should Be $script:subnetId
    }

    It 'resolves the template independently of the working directory' {
        Push-Location $TestDrive
        try {
            $result = & $script:deployScript @script:parameters
            $expectedPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\migrate.bicep'))
            $result.TemplateFile | Should Be $expectedPath
            Test-Path -LiteralPath $result.TemplateFile | Should Be $true
        }
        finally {
            Pop-Location
        }
    }

    It 'rejects private connectivity without a subnet before deployment' {
        { & $script:deployScript @script:parameters -Connectivity Private } |
            Should Throw 'PrivateEndpointSubnetId is required'
        Assert-MockCalled New-AzDeployment -Times 0 -Exactly -Scope It
    }

    It 'rejects a subnet for public connectivity before deployment' {
        { & $script:deployScript @script:parameters -PrivateEndpointSubnetId $script:subnetId } |
            Should Throw 'PrivateEndpointSubnetId can only be specified'
        Assert-MockCalled New-AzDeployment -Times 0 -Exactly -Scope It
    }

    It 'rejects invalid connectivity values' {
        { & $script:deployScript @script:parameters -Connectivity Invalid -ErrorAction Stop } | Should Throw
        Assert-MockCalled New-AzDeployment -Times 0 -Exactly -Scope It
    }

    It 'rejects malformed subnet IDs' {
        { & $script:deployScript @script:parameters -Connectivity Private -PrivateEndpointSubnetId 'not-a-subnet' -ErrorAction Stop } |
            Should Throw
        Assert-MockCalled New-AzDeployment -Times 0 -Exactly -Scope It
    }

    It 'rejects project names outside the resource naming constraints' {
        foreach ($invalidName in @('ab', ('a' * 25), 'invalid_name')) {
            $script:parameters.Name = $invalidName
            { & $script:deployScript @script:parameters -ErrorAction Stop } | Should Throw
        }
        Assert-MockCalled New-AzDeployment -Times 0 -Exactly -Scope It
    }

    It 'propagates deployment failures' {
        Mock New-AzDeployment { throw 'Deployment failed' }

        { & $script:deployScript @script:parameters } | Should Throw 'Deployment failed'
    }
}
