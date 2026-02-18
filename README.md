# Modular Azure Baseline: Hardened Identity-First Landing Zone

## 📌 Project Overview
This repository serves as a Technical Proof of Concept (PoC) for deploying a secure, scalable, and automated Azure environment. Moving beyond manual "Click-Ops," this project utilizes Infrastructure-as-Code (IaC) to orchestrate core platform components with a focus on Identity-as-Code and Zero-Trust network principles.

The goal of this project is to provide a "Hardened Baseline" that can be deployed repeatedly while maintaining strict configuration consistency.

---

## 🏗️ Architectural Features

### 1. Identity-as-Code & Governance
* **Entra ID Integration:** Declarative management of Security Groups and RBAC assignments.
* **Zero-Trust Guardrails:** (In Development) Automated deployment of Conditional Access policies to enforce MFA and device compliance.
* **Least Privilege:** Implementation of scoped Service Principals and System-Assigned Managed Identities for resource interaction.

### 2. Software-Defined Networking
* **Hub-and-Spoke Ready:** Modular VNET architecture designed for traffic isolation.
* **Security Groups:** Implementation of Network Security Groups (NSGs) with "Deny-All" default logic.
* **Private Link Architecture:** Use of Private Endpoints to ensure sensitive storage and vault traffic never traverses the public internet.

### 3. State & Lifecycle Management
* **Idempotency:** Using Terraform to ensure the environment matches the defined code, preventing configuration drift.
* **Remote State Management:** Configured for Azure Blob Storage backend with State Locking to support team-based collaboration.
* **Variable-Driven Design:** Leveraging `variables.tf` and `terraform.tfvars` for environment abstraction (Dev/Prod parity).

---

## 🛡️ Current Milestone: Tier 3 Storage & Vault Hardening
*Successfully transitioned the landing zone from a baseline setup to a high-security audited environment.*

* **Customer-Managed Encryption (CMK):** Integrated **Azure Key Vault (Premium HSM)** with the Storage Account to manage encryption keys via RSA-2048.
* **Total Network Isolation:** Public Network Access is explicitly disabled; connectivity is restricted to internal VNet traffic via **Private Endpoints**.
* **Shared Key Suppression:** Disabled `shared_access_key_enabled` to enforce Entra ID/RBAC authentication only, mitigating the risk of leaked connection strings.
* **Automated Compliance:** Configuration validated against enterprise standards, passing **30/30** security checks via **Checkov (SAST)**.



---

## 🚀 Technical Stack
* **Orchestration:** Terraform (HCL)
* **Cloud Provider:** Microsoft Azure
* **Security Scanning:** Checkov (Static Analysis Security Testing)
* **Automation:** PowerShell Core
* **Version Control:** Git / GitHub

---

## 📂 Repository Structure
```bash
.
├── modules/                # Reusable architectural components (Storage, VNET, Identity)
├── environments/           # Environment-specific configurations
├── main.tf                 # Primary orchestration logic
├── providers.tf            # AzureRM provider & Identity data source configuration
├── variables.tf            # Input declarations for environment abstraction
├── outputs.tf              # Schema for exporting resource metadata and Private IPs
├── .gitignore              # Strict exclusion of .tfstate and secrets
└── README.md               # Project documentation