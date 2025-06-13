# PowerShell
$assignments = Get-AzPolicyAssignment
foreach ($assignment in $assignments) {
    $definition = Get-AzPolicyDefinition -Id $assignment.PolicyDefinitionId
    $effect = $definition.Properties.PolicyRule.then.effect
    [PSCustomObject]@{
        PolicyName  = $assignment.Name
        AssignedTo  = $assignment.Scope
        Effect      = $effect
    }
}


# Azure CLI
#az policy assignment list --query "[].{PolicyName:name, AssignedTo:scope, PolicyDefinitionId:policyDefinitionId}" -o table