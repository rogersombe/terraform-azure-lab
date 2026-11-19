# Promote named policies from report-only to enforced
param([string[]]$Names)

foreach ($n in $Names) {
    $p = Get-MgIdentityConditionalAccessPolicy | Where-Object DisplayName -like "$n*"
    Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $p.Id -State "enabled"
    Write-Host "Enforced: $($p.DisplayName)"
}