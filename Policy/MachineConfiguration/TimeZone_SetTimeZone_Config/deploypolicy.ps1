# Generate a unique GUID for the policy
$PolicyId = (New-Guid).Guid

# Create a new guest configuration policy. Creates/gets sha256 hash of the zip file.
New-GuestConfigurationPolicy -PolicyId $PolicyId `
                              -DisplayName "Set Central TimeZone" `
                              -Description "Sets Central TimeZone and autocorects if changed" `
                              -ContentUri "https://<sa>.blob.core.windows.net/config/TimeZone.zip" `
                              -Platform "Windows" `
                              -PolicyVersion "1.0.0" `
                              -Mode "ApplyAndAutoCorrect"

New-AzPolicyDefinition        -Name "Set-Central-TimeZone" `
                              -DisplayName "Set Central TimeZone" `
                            -Description "Sets Central TimeZone and autocorects if changed" `
                            -Policy '.\TimeZone_DeployIfNotExists.json' `
                              -Mode All
# Assign the policy to a scope (e.g., subscription or resource group)
#$scope = "/subscriptions/<subid>" # Change to your subscription ID or resource group
#New-AzPolicyAssignment -Name "Set-Central-TimeZone-Assignment" `
#                       -DisplayName "Set Central TimeZone Assignment" `
#                       -PolicyDefinition $PolicyId `
#                       -Scope $scope `
#                       -Location "southcentralus" `
#                       -IdentityType SystemAssigned