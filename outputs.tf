output "resource_group_name" {
  value       = azurerm_resource_group.lab_rg.name
  description = "The name of the resource group."
}

output "storage_account_id" {
  value       = azurerm_storage_account.lab_storage.id
  description = "The ID of the storage account."
}

output "storage_primary_access_key" {
  value       = azurerm_storage_account.lab_storage.primary_access_key
  description = "The primary access key for the storage account."
  sensitive   = true
}