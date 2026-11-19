# ADR: P2 Conditional Access as Code

Status: Accepted, 18 Nov 2026

## Context

The lab tenant had no access controls beyond Microsoft's Security Defaults (blanket MFA, no per-persona rules). The goal was persona-based Conditional Access that can be versioned in Git, tested safely before enforcement, and cannot lock the tenant owner out.

## Decisions

1. **Target groups, not individuals.** Policies include a persona group (IT Admins, Finance). Access rules then follow group membership, so onboarding someone is a group change, not a policy edit.
2. **Dedicated break-glass account, excluded from every policy.** A cloud-only Global Admin with a random 32-character password, kept in a password manager. It is permanent and deliberately not PIM-eligible, because an emergency account cannot depend on an approval flow. Its sign-in was tested before any policy was enforced.
3. **Report-only first, enforce second.** Every policy ran in report-only mode and was checked against a real sign-in before being switched on.
4. **Disable Security Defaults.** It cannot coexist with Conditional Access. The gap between disabling it and enforcing policies was accepted for a lab tenant, and kept to under three hours.
5. **Block legacy authentication for everyone.** Legacy protocols cannot perform MFA, so they bypass the other two policies.
6. **Policies created by script.** Graph PowerShell scripts live in `conditional-access/scripts/`, so the configuration is reviewable and repeatable.

## Alternatives considered

- **Target Entra admin roles instead of a group.** Closer to real-world admin protection, but it needs a role-based design and more test accounts than this lab had. Group targeting was enough to prove the pattern.
- **Keep Security Defaults.** Simpler, but gives one rule for everyone and no way to exclude an emergency account.
- **Entra ID P2 licence.** Used here only because a 30-day trial was running. P1 is sufficient for these three policies. P2 adds risk-based rules, which this lab did not use.

## Consequences

- Conditional Access depends on a paid licence. The trial ended at 00:00 on 19 Nov 2026, and behaviour of the existing policies after expiry was not tested here.
- Policy scope depends on group membership being correct. One group name contains a stray space, so lookups must match it exactly.
- The break-glass account is a standing high-privilege credential. It should be monitored and its sign-ins alerted on, which this lab did not implement.
- One test user showed "Previously satisfied" MFA on first enforced sign-in, so the "stopped at an MFA wall" case was not captured. The README records this honestly.
- CA001 was promoted in the portal, not by script, because of a PowerShell module version conflict. The audit log records the change.