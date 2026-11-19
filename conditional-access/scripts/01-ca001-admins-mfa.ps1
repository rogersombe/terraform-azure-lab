# CA001 - Require MFA for IT Admins (report-only)
$breakGlass = Get-MgUser -Filter "userPrincipalName eq 'lab-breakglass@rogersombegmail.onmicrosoft.com'"
$itAdmins   = Get-MgGroup -Filter "displayName eq 'lab-IT-Admins'"

$params = @{
    displayName = "CA001 - Require MFA - IT Admins"
    state       = "enabledForReportingButNotEnforced"
    conditions  = @{
        users          = @{
            includeGroups = @($itAdmins.Id)
            excludeUsers  = @($breakGlass.Id)
        }
        applications   = @{ includeApplications = @("All") }
        clientAppTypes = @("all")
    }
    grantControls = @{
        operator        = "OR"
        builtInControls = @("mfa")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params