# --- STAGE 1: RESOURCE GROUP ---
resource "azurerm_resource_group" "lab_rg" {
  name     = var.resource_group_name
  location = var.location
}

# --- STAGE 2: STORAGE ACCOUNT ---
resource "azurerm_storage_account" "lab_storage" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.lab_rg.name
  location                        = azurerm_resource_group.lab_rg.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
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

# --- STAGE 4: KEY VAULT (RBAC authorization plane) ---
# Authorization is delegated to Azure RBAC, not Key Vault access policies.
# This brings the vault under the same identity control plane as the rest of
# Azure: same role definitions, same scope inheritance, PIM-eligible, and
# reviewable via Entra access reviews.
resource "azurerm_key_vault" "lab_kv" {
  name                = var.vault_name
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                    = "premium"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enabled_for_disk_encryption = true

  # RBAC instead of legacy access policies
  rbac_authorization_enabled = true

  # DESIGN NOTE - two routes to the vault's DATA plane.
  #
  # Setting public_network_access_enabled = false does NOT coexist with an IP
  # allowlist: it overrides network_acls entirely, and the ip_rules below are
  # never evaluated. A workstation-based deploy therefore cannot reach the
  # vault to create a key. That is not a bug - it is the vault refusing to
  # trust anything that did not arrive over private link.
  #
  # The posture chosen here: the public endpoint exists, but denies by default.
  # Exactly one IP is permitted, so the deploying workstation can create and
  # rotate keys. Key operations are DATA plane, so the firewall governs them.
  # The storage account reaches the vault over the PRIVATE ENDPOINT for its
  # own data plane operations (key wrap/unwrap).
  #
  # The firewall does not govern the CONTROL plane (creating or changing the
  # vault resource itself). Azure RBAC controls that.
  #
  # The production-correct pattern is a VNet-integrated build agent, which
  # removes the need for this allowlist entirely. See Roadmap.
  public_network_access_enabled = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = [var.deployment_ip]
  }
}

# --- STAGE 4a: RBAC ROLE ASSIGNMENTS ---

# Deploying principal: full key lifecycle management. Scoped to this vault only.
resource "azurerm_role_assignment" "kv_crypto_officer" {
  scope                = azurerm_key_vault.lab_kv.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Storage account's system-assigned identity: wrap/unwrap ONLY.
# The minimum viable permission for customer-managed key encryption. It cannot
# read, create, or delete keys. It can only use the one it has been given.
resource "azurerm_role_assignment" "storage_cmk_user" {
  scope                = azurerm_key_vault.lab_kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_storage_account.lab_storage.identity[0].principal_id
}

# --- STAGE 4b: ENCRYPTION KEY ---
# depends_on is required: RBAC role assignments propagate asynchronously and
# more slowly than legacy access policies. Without this, Terraform races the
# authorization plane and key creation fails with a 403.
resource "azurerm_key_vault_key" "storage_key" {
  name            = "storage-encryption-key"
  key_vault_id    = azurerm_key_vault.lab_kv.id
  key_type        = "RSA-HSM"
  key_size        = 2048
  expiration_date = "2027-12-30T23:59:59Z"
  key_opts        = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  depends_on = [azurerm_role_assignment.kv_crypto_officer]
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

  depends_on = [azurerm_role_assignment.storage_cmk_user]
}

resource "azurerm_subnet_network_security_group_association" "endpoints_assoc" {
  subnet_id                 = azurerm_subnet.endpoints.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}