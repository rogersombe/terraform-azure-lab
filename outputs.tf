output "resource_group_name" {
  value       = azurerm_resource_group.lab_rg.name
  description = "The name of the resource group."
}

output "storage_account_id" {
  value       = azurerm_storage_account.lab_storage.id
  description = "The ID of the storage account."
}

# The "Tier 3" Output: Showing where the data actually lives in the VNet
output "storage_private_ip" {
  description = "The private IP address of the Storage Account Endpoint"
  value       = azurerm_private_endpoint.storage_pe.private_service_connection[0].private_ip_address
}

# The "IAM Specialist" Output: The URI needed for Managed Identity handshakes
output "keyvault_uri" {
  description = "The URI of the Key Vault for application use"
  value       = azurerm_key_vault.lab_kv.vault_uri
}