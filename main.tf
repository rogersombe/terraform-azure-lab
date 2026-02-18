# --- STAGE 1: RESOURCE GROUP ---
resource "azurerm_resource_group" "lab_rg" {
  name     = var.resource_group_name
  location = var.location
}

# --- STAGE 2: STORAGE ACCOUNT ---
resource "azurerm_storage_account" "lab_storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.lab_rg.name
  location                 = azurerm_resource_group.lab_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  # FIX: Updated deprecated argument
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  identity {
    type = "SystemAssigned"
  }

  queue_properties {
    logging {
      version               = "1.0"
      delete                = true
      read                  = true
      write                 = true
      retention_policy_days = 7
    }
  }

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }
}

# --- STAGE 3: NETWORKING ---
resource "azurerm_virtual_network" "main" {
  name                = "rogers-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints"
  resource_group_name  = azurerm_resource_group.lab_rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-security-group"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  security_rule {
    name                       = "AllowInternal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }
}

# --- STAGE 4: KEY VAULT ---
resource "azurerm_key_vault" "lab_kv" {
  name                = var.vault_name
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  # Ensure these point to the data source in providers.tf
  tenant_id = data.azurerm_client_config.current.tenant_id

  sku_name                      = "premium"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = true
  enabled_for_disk_encryption   = true
  public_network_access_enabled = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    key_permissions    = ["Get", "Create", "Delete", "List", "Restore", "Recover", "UnwrapKey", "WrapKey", "Purge"]
    secret_permissions = ["Get", "Set", "List", "Delete", "Purge"]
  }

  access_policy {
    tenant_id       = data.azurerm_client_config.current.tenant_id
    object_id       = azurerm_storage_account.lab_storage.identity[0].principal_id
    key_permissions = ["Get", "UnwrapKey", "WrapKey"]
  }
}

resource "azurerm_key_vault_key" "storage_key" {
  name            = "storage-encryption-key"
  key_vault_id    = azurerm_key_vault.lab_kv.id
  key_type        = "RSA-HSM"
  key_size        = 2048
  expiration_date = "2027-12-30T23:59:59Z"
  key_opts        = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

# --- STAGE 5: ENDPOINTS & ASSOCIATIONS ---
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-keyvault"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.lab_kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

resource "azurerm_private_endpoint" "storage_pe" {
  name                = "pe-storage"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "psc-storage"
    private_connection_resource_id = azurerm_storage_account.lab_storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

resource "azurerm_storage_account_customer_managed_key" "storage_cmk" {
  storage_account_id = azurerm_storage_account.lab_storage.id
  key_vault_id       = azurerm_key_vault.lab_kv.id
  key_name           = azurerm_key_vault_key.storage_key.name
}

resource "azurerm_subnet_network_security_group_association" "endpoints_assoc" {
  subnet_id                 = azurerm_subnet.endpoints.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}