provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  # Corrected syntax: no underscore between azure and ad
  storage_use_azuread = true
}
data "azurerm_client_config" "current" {
}