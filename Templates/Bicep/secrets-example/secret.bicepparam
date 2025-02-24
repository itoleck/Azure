using './main.bicep'

param notSecret = 'This is not secret.'
param mySecret = az.getSecret('SubID', 'RG', 'KV', 'secret', 'VersionID')
