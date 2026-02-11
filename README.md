Terraform Azure Foundations: From Static to Structured IaC
📜 Overview
This project demonstrates a multi-stage evolution of Infrastructure as Code (IaC) maturity using Terraform and Azure. Rather than a simple one-time deployment, this repository tracks the transition from basic resource provisioning to a structured, variable-driven, and security-conscious architecture.

🏗️ Deployed Infrastructure
Azure Resource Group: The logical container for all lab assets.

Azure Storage Account: A Standard_LRS account configured with environment-specific metadata.

🚀 Project Evolution
Stage 1: Basic Deployment
Initial proof of concept focused on the core Terraform workflow (init → plan → apply).

Goal: Successful communication with the AzureRM provider and state file generation.

Key Outcome: Understanding the provider-resource relationship.

Stage 2: Structured IaC (Current)
Refactored the codebase to adhere to industry "Best Practices" for reusability and security.

Separation of Concerns: Split configuration into main.tf, variables.tf, and outputs.tf.

Parameterization: Utilized variables.tf and terraform.tfvars to remove hardcoded values, allowing for environment parity.

Secrets Management: Implemented Sensitive Outputs to ensure that Storage Access Keys are protected from accidental exposure in terminal logs and CI/CD pipelines.

🧠 Key Engineering Concepts Demonstrated
State & Idempotency: Verified that Terraform identifies "Configuration Drift." I successfully demonstrated that if a resource is modified manually in the Azure Portal, Terraform will detect the change and propose a plan to restore the "Source of Truth" defined in the code.

Implicit Dependencies: Configured the Storage Account to dynamically reference the Resource Group object. This ensures Terraform calculates the correct order of operations (building the "house" before the "furniture").

Lifecycle Awareness: Identified which attribute changes (such as location or name) force a "Destroy and Recreate" action versus a "Modify In-Place" action.

🛠️ Technologies Used
Terraform (HashiCorp)

Azure Cloud Platform

Azure CLI (Authentication)

HCL (HashiCorp Configuration Language)

Git/GitHub (Version Control)

🏁 How to Run
Login: az login

Initialize: terraform init

Plan: terraform plan

Deploy: terraform apply -auto-approve

Clean up: terraform destroy

🔮 Future Improvements (Stage 3 & Beyond)
[ ] Remote State: Migrating from local .tfstate to an Azure Backend (Blob Storage with Locking).

[ ] Network Hardening: Implementing Virtual Network rules and Private Endpoints for the Storage Account.

[ ] Modularization: Abstracting the Storage Account into a reusable module.

Author
Rogers Sombe Aspiring Azure Cloud / DevSecOps Engineer