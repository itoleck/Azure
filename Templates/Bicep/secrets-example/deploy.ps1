az deployment group create `
--resource-group "northcentralusRG" `
--template-file ".\main.bicep" `
--parameters ".\secret.bicepparam"