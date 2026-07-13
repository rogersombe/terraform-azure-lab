variable "resource_group_name" {
  type    = string
  default = "rg-hardened-lab"
}

variable "location" {
  type    = string
  default = "uksouth"
}

variable "storage_account_name" {
  type    = string
  default = "rogstlab001"
}

variable "vault_name" {
  description = "The name of the Key Vault"
  type        = string
  default     = "rog-lab-vault-001"
}

variable "deployment_ip" {
  description = "Public IP of the deploying workstation. Permitted through the Key Vault firewall for MANAGEMENT PLANE operations only (creating and rotating keys). The DATA PLANE (storage account to vault, key unwrap) routes exclusively over the private endpoint."
  type        = string
}