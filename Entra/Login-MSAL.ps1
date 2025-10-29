param (
    [String]$TenantId = "",
    [String]$SubscriptionId = "",
    [String]$ClientId = ""
)

# Import the module
Import-Module MSAL.PS -Scope local

# Define your Azure AD app details
$Scopes   = "https://graph.microsoft.com/User.Read"  # Or specific scopes like "User.Read"

try {
    # Get an access token interactively
    $Token = Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Interactive -Scopes $Scopes

    # Display token info
    Write-Host "Access Token acquired successfully."
    Write-Host "Expires On: $($Token.ExpiresOn)"
    Write-Host "Token (truncated): $($Token.AccessToken.Substring(0,40))..."
}
catch {
    Write-Error "Failed to acquire token: $_"
}

$Headers = @{
    Authorization = "Bearer $($Token.AccessToken)"
}

# Example: Get signed-in user's profile
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me" -Headers $Headers