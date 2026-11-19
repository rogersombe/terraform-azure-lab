# CA002 - Require MFA for Finance (report-only)
# CA003 - Block legacy authentication, all users (report-only)
$breakGlass = Get-MgUser  -Filter "userPrincipalName eq 'lab-breakglass@rogersombegmail.onmicrosoft.com'"
$finance    = Get-MgGroup -Filter "displayName eq 'lab- Finance-Users'"

$ca002 = @{
    displayName = "CA002 - Require MFA - Finance"
    state       = "enabledForReportingButNotEnforced"
    conditions  = @{
        users          = @{
            includeGroups = @($finance.Id)
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

$ca003 = @{
    displayName = "CA003 - Block legacy authentication"
    state       = "enabledForReportingButNotEnforced"
    conditions  = @{
        users          = @{
            includeUsers = @("All")
            excludeUsers = @($breakGlass.Id)
        }
        applications   = @{ includeApplications = @("All") }
        clientAppTypes = @("exchangeActiveSync", "other")
    }
    grantControls = @{
        operator        = "OR"
        builtInControls = @("block")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $ca002 | Out-Null
New-MgIdentityConditionalAccessPolicy -BodyParameter $ca003 | Out-Null