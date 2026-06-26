# Modular Azure Baseline: Hardened Identity-First Landing Zone

## Project Overview
A Technical Proof of Concept for a secure, automated Azure baseline, built with Infrastructure-as-Code. Moving beyond manual "Click-Ops," it orchestrates core platform components with a focus on identity-first authentication and Zero-Trust network principles.

The design is **statically verified** — every resource passes Checkov security analysis (31/31, zero failures) before any deployment. This is a *validated design*, hardened by default and built to be deployed repeatedly with strict configuration consistency.

---

## System Architecture

Identity proves who it is → trust grants one specific permission → encryption follows from that trust → and everything sits behind a private network boundary.

```mermaid
flowchart TD
    subgraph IDENTITY["IDENTITY - who am I?"]
        SA_ID["Storage Account<br/>System-Assigned Identity<br/>no keys, no passwords"]
    end

    subgraph TRUST["TRUST - what am I allowed to do?"]
        KV["Key Vault Premium<br/>purge protection + HSM key<br/>grants the identity rights to ONE key"]
    end

    subgraph ENCRYPT["ENCRYPTION - proven by trust"]
        STORAGE["Storage Account<br/>encrypted with customer-managed key<br/>shared keys disabled"]
    end

    subgraph BOUNDARY["NETWORK BOUNDARY - private only"]
        PE["Private Endpoints<br/>Key Vault + Storage<br/>no public internet path"]
    end

    SA_ID -->|"authenticates as itself"| KV
    KV -->|"unwraps the encryption key for"| STORAGE
    STORAGE -.->|"reachable only via"| PE
    KV -.->|"reachable only via"| PE

    classDef identity fill:#0b3d91,stroke:#0a2540,color:#fff
    classDef trust fill:#1b6ec2,stroke:#0a2540,color:#fff
    classDef encrypt fill:#107c10,stroke:#0a2540,color:#fff
    classDef boundary fill:#2d2d2d,stroke:#555,color:#fff
    class SA_ID identity
    class KV trust
    class STORAGE encrypt
    class PE boundary
```

---

## Architecture Diagrams (Graphviz)

Detailed architecture diagrams live in [`/docs`](./docs/). Each answers one question:

| Diagram | Question |
|---------|----------|
| [Infrastructure](./docs/infrastructure.svg) | What Azure resources exist? |
| [Identity Flow](./docs/identity-flow.svg) | How does trust move through the system? |
| [Zero Trust](./docs/zero-trust.svg) | Where are the network boundaries? |
| [Dependency](./docs/dependency.svg) | In what order does Terraform build this? |

Diagrams are derived from Terraform source and verified against `main.tf`. Re-render with:
`dot -Tsvg docs/<name>.dot -o docs/<name>.svg`

---

## What This Deploys (verified)

### Identity-First Authentication
* **System-Assigned Managed Identity** on the storage account — no stored keys or passwords.
* **Entra ID authentication enforced** (`storage_use_azuread = true`) — Azure AD identity, not shared keys.
* **Shared Key authentication disabled** (`shared_access_key_enabled = false`) — eliminates leaked-connection-string risk.

### Customer-Managed Encryption
* **Azure Key Vault (Premium / HSM)** with purge protection and soft-delete.
* **RSA-HSM encryption key** with a set expiration date, used to encrypt storage via Customer-Managed Key (CMK).
* The vault grants the storage account's identity rights to **one key only** — least privilege in practice.

### Zero-Trust Networking
* **Public network access disabled** on both Key Vault and Storage.
* **Private Endpoints** for vault and storage — traffic never traverses the public internet.
* **Network Security Group** with internal-only inbound rules, associated to the endpoints subnet.

### Verified by Static Analysis
* **31/31 Checkov security checks passing, zero failures** — covering encryption, network isolation, TLS, key management, and identity. Re-runnable with `checkov -d .`

---

## Roadmap (next iterations)
*Honestly scoped — designed for, not yet implemented in this repository:*

* **RBAC migration** — move Key Vault from access policies to Azure RBAC role assignments.
* **Conditional Access** — automated MFA and device-compliance policies.
* **Remote state backend** — Azure Blob Storage backend with state locking for team collaboration.
* **Queue properties refactor** — migrate to the `azurerm_storage_account_queue_properties` resource ahead of AzureRM v5.0.
* **CMK resource refactor** — migrate `key_vault_id` and `key_name` to updated argument syntax ahead of AzureRM v5.0.

---

## Technical Stack
* **Orchestration:** Terraform (HCL)
* **Cloud Provider:** Microsoft Azure
* **Security Scanning:** Checkov (Static Analysis Security Testing)
* **Automation:** PowerShell Core
* **Version Control:** Git / GitHub

---

## Deploy
```bash
terraform init
terraform validate
terraform plan
terraform apply
```
> Requires an authenticated Azure CLI session (`az login`) and Terraform ≥ 1.x.

---

## Repository Structure
```bash
.
├── docs/
│   ├── infrastructure.dot   # Physical resource graph (source)
│   ├── infrastructure.svg   # Physical resource graph (rendered)
│   ├── identity-flow.dot    # Identity & trust chain (source)
│   ├── identity-flow.svg    # Identity & trust chain (rendered)
│   ├── zero-trust.dot       # Network boundary flow (source)
│   ├── zero-trust.svg       # Network boundary flow (rendered)
│   ├── dependency.dot       # Terraform creation order (source)
│   └── dependency.svg       # Terraform creation order (rendered)
├── main.tf          # Primary orchestration logic (RG, Storage, VNET, Key Vault, Endpoints)
├── providers.tf     # AzureRM provider + Entra identity data source
├── variables.tf     # Input declarations for environment abstraction
├── outputs.tf       # Exported resource metadata
├── .gitignore       # Excludes .tfstate and secrets
└── README.md        # Project documentation
```