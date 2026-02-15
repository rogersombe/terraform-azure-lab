Modular Azure Baseline: Hardened Identity-First Landing Zone
📌 Project Overview
This repository serves as a Technical Proof of Concept (PoC) for deploying a secure, scalable, and automated Azure environment. Moving beyond manual "Click-Ops," this project utilizes Infrastructure-as-Code (IaC) to orchestrate core platform components with a focus on Identity-as-Code and Zero-Trust network principles.

The goal of this project is to provide a "Hardened Baseline" that can be deployed repeatedly while maintaining strict configuration consistency.

🏗️ Architectural Features
1. Identity-as-Code & Governance
Entra ID Integration: Declarative management of Security Groups and RBAC assignments.

Zero-Trust Guardrails: (In Development) Automated deployment of Conditional Access policies to enforce MFA and device compliance.

Least Privilege: Implementation of scoped Service Principals for Terraform execution.

2. Software-Defined Networking
Hub-and-Spoke Ready: Modular VNET architecture designed for traffic isolation.

Security Groups: Implementation of Network Security Groups (NSGs) with "Deny-All" default logic.

3. State & Lifecycle Management
Idempotency: Using Terraform to ensure the environment matches the defined code, preventing configuration drift.

Remote State Management: Configured for Azure Blob Storage backend with State Locking to support team-based collaboration.

Variable-Driven Design: Leveraging variables.tf and terraform.tfvars for environment abstraction (Dev/Prod parity).

🚀 Technical Stack
Orchestration: Terraform (HCL)

Cloud Provider: Microsoft Azure

Automation: PowerShell Core

Version Control: Git / GitHub

📂 Repository Structure
Bash
.
├── modules/                # Reusable architectural components (Storage, VNET, Identity)
├── environments/           # Environment-specific configurations
├── main.tf                 # Primary orchestration logic
├── variables.tf            # Input declarations for environment abstraction
├── outputs.tf              # Schema for exporting resource metadata
├── .gitignore              # Strict exclusion of .tfstate and secrets
└── README.md               # Project documentation
🛠️ Usage & Deployment
Clone the Repository:

Bash
git clone https://github.com/rogersombe/terraform-azure-lab.git
Initialize the Backend:

Bash
terraform init
Review the Plan:

Bash
terraform plan -out=main.tfplan
Execute Provisioning:

Bash
terraform apply "main.tfplan"
🔐 Security & Compliance
Secret Management: No credentials are stored in code. Utilizing environment variables and Azure Key Vault for sensitive data.

State Security: Local state files are ignored via .gitignore; remote state is encrypted at rest.

Author: Rogers Sombe

Role: Azure Cloud Engineer | Infrastructure & Identity Operations

Certification Path: AZ-104 (In Progress)