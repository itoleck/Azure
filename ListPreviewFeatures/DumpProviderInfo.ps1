Add-AzAccount `
    -ServicePrincipal `
    -TenantId "" `
    -ApplicationId "" `
    -CertificateThumbprint ""

Get-AzResourceProvider -ListAvailable -Debug