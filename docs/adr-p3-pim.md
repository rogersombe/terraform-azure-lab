# P3: Temporary admin access (PIM) - decisions

## What changes
Rog's permanent Owner role on the subscription becomes "eligible":
he can request it, someone else approves, and it expires on its own.

## What stays permanent, and why
- terraform-lab-sp (Contributor): a robot cannot click "request access",
  so making it temporary would just break the pipeline.
- Storage account identity (Key Vault wrap/unwrap): same reason.

## Who approves
lab-it.admin approves Rog's requests. Approving your own request
proves nothing, so a second person is required.

## Safety net
lab-it.admin keeps its permanent Global Administrator until the loop
is proven end to end. If Owner is ever lost, a Global Admin can
restore it from Entra settings. The net is removed last, not first.

## Order of work
Create the eligible assignment first, prove it works, and only then
remove the permanent one.

## Deliberately out of scope
Key Vault role assignments: the lab is torn down. They get
retrofitted when the lab is rebuilt.