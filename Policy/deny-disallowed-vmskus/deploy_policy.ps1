param ( 
    [Parameter(Mandatory=$true)][string]$subscriptionId
)

# Variables
$definitionName = "Deny-Disallowed-VM-SKUs"
$displayName    = "Deny creation of disallowed VM SKUs across VM, VMSS, AKS, and Batch"
$description    = "Prevents creation of disallowed VM sizes across multiple compute resource types."

# Create the policy definition
New-AzPolicyDefinition `
  -Name $definitionName `
  -DisplayName $displayName `
  -Description $description `
  -Policy 'deny-disallowed-vmskus.json' `
  -Mode All `
  -SubscriptionId $subscriptionId

# Variables
$assignmentName = "Deny-Disallowed-VM-SKUs-Assignment"
$scope          = "/subscriptions/$subscriptionId"

# Assign the policy
New-AzPolicyAssignment `
  -Name $assignmentName `
  -DisplayName "Deny disallowed VM SKUs" `
  -Scope $scope `
  -PolicyDefinition (Get-AzPolicyDefinition -Name $definitionName)
