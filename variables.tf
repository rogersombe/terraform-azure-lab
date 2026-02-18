variable "resource_group_name" {
  type    = string
  default = "rg-hardened-lab"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "storage_account_name" {
  type    = string
  default = "rogstlab001"
}

# THIS IS THE MISSING PIECE
variable "vault_name" {
  description = "The name of the Key Vault"
  type        = string
  default     = "rog-lab-vault-001"
}