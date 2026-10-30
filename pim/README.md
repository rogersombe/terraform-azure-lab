# P3: PIM as Code (admin access that expires)

Nobody holds standing admin access. To get it, you ask, someone else approves, it works for an hour, and then it stops on its own. The rules for all of this are written as Terraform code.

## The problem this solves

Permanent admin rights pile up. Someone needs access for a job, gets it, and nobody remembers to take it away. If that account is ever stolen, the thief inherits all of it.

PIM (Privileged Identity Management, Microsoft's "admin access on request" feature) fixes this by making powerful roles something you switch on when needed, not something you carry all day.

## What this lab does

| Before | After |
|---|---|
| Rog held **Owner** on the subscription permanently | Rog is **eligible** for Owner: he can ask for it, but doesn't hold it |
| No approval, no reason, no end time | A reason is required, a second person must approve, and it ends after 1 hour |
| Nothing recorded about why access was used | Every request, approval and expiry is logged |

**Who does what**

- **Rog Sombe** requests Owner when needed.
- **lab-it.admin** approves. Approving your own request proves nothing, so a second person is built in.
- **terraform-lab-sp** (the robot account Terraform uses) stays permanent. A robot can't click "request access", so making it temporary would only break the pipeline. This decision is recorded in `../docs/adr-p3-pim.md`.

## What the code creates

Two things, in `main.tf`:

1. **A rule set for the Owner role** (`azurerm_role_management_policy`): maximum 1 hour, a reason is required, and lab-it.admin must approve.
2. **An eligibility** (`azurerm_pim_eligible_role_assignment`): Rog may request Owner. It runs for 30 days, then needs renewing.

Your own subscription and people IDs go in `terraform.tfvars`, which is git-ignored and not in this repo.

## Evidence

| # | Screenshot | What it proves |
|---|---|---|
| 1 | `01-before-permanent-owner.png` | Rog held permanent Owner |
| 2 | `02-permissions-error.png` | Permanent Owner removed; Rog can no longer view the assignments page |
| 3 | `03-pending-approval.png` | The request was held for approval, not granted |
| 4 | `04-audit-trail.png` | The full record: request, approval by lab-it.admin, activation, and the system ending it after one hour |
| 5 | `05-activated-with-end-time.png` | Owner granted with an end time about an hour away |
| 6 | `06-active-empty.png` | After the end time, Rog holds no active roles |
| 7 | `07-subscription-hidden.png` | With no rights left, Azure hides the subscription from Rog entirely |

## What the audit trail shows

All times are 19-20 Oct 2026 (the log shows them as written; the activation ran from just after midnight).

| Time | Who | What happened |
|---|---|---|
| 19 Oct 11:57 pm | Rog | Rules for Owner set (1 hour, reason, approval) and eligibility created, both from Terraform |
| 20 Oct 12:06 am | Rog | Permanent Owner removed |
| 12:07 am | Rog | Two early requests for Owner, which Azure refused while the removal was still settling |
| 12:08 am | Rog | Request made, then held for approval |
| 12:10:12 am | lab-it.admin | Request approved |
| 12:10:20 am | Rog | Owner activated |
| 1:10:20 am | Azure AD PIM | Owner removed automatically: "PIM activation expired" |

That last row is the point of the lab: exactly one hour after activation, the system took the access away and nobody had to remember.

## The safety net

Removing your own admin rights is the one step that can lock you out, so it was done last, not first:

1. The eligibility was created while permanent Owner was still in place.
2. Before removing anything, I confirmed that lab-it.admin (a Global Administrator) can switch on "Access management for Azure resources", which lets it give itself rights over the subscription and hand Owner back.
3. Only then was permanent Owner removed.

lab-it.admin keeps its permanent Global Administrator role. This is a deliberate gap, covered under limits below.

## Problems hit along the way

- **PIM needs a paid licence.** The tenant had none, so the first attempt failed with "AadPremiumLicenseRequired". The 30-day Entra ID P2 trial fixed it.
- **A personal Microsoft account can't start that trial.** My Gmail sign-in was an outside user in the tenant. The trial and the Microsoft 365 admin centre both refused it. I used a native account (lab-it.admin) with the Global Administrator role instead.
- **I doubled a path in my own code.** The first plan showed the subscription path twice in the role ID. Terraform's plan caught it before anything was created, so nothing broke.
- **Removals take a few minutes to settle.** My first attempt to request Owner failed with "The Role assignment already exists", because Azure hadn't finished processing the removal. It worked after waiting.

## Limits (what this does not do)

- **Permanent Owner was removed by hand in the portal, not by Terraform.** The code creates the eligibility, but the removal is a manual step.
- **lab-it.admin's Global Administrator is still permanent.** It is the safety net for this lab. A full version would make that eligible too, using PIM for Microsoft Entra roles.
- **Key Vault role assignments are not covered.** The main lab was torn down to save cost, so there were no Key Vault permissions to convert. They get retrofitted when the lab is rebuilt.
- **One approver, no backup.** If lab-it.admin is unavailable, no request can be approved.
- **This all depends on a trial licence.** PIM stops working when the Entra ID P2 trial ends (around 18 Nov 2026), and the eligibility ends the same day.
- **Terraform runs as Rog.** `terraform apply` in this folder only works while Owner is activated.

## How to run it

```powershell
cd pim
terraform init
terraform plan
terraform apply
```

You need `terraform.tfvars` with `subscription_id`, `requester_object_id` and `approver_object_id`, and Owner activated if the permanent version has been removed.
