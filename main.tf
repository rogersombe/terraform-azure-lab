# 1. Terraform & Provider Settings
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. THE RESOURCE GROUP (This was missing!)
resource "azurerm_resource_group" "lab_rg" {
  name     = var.resource_group_name
  location = var.location
}

# 3. THE STORAGE ACCOUNT
resource "azurerm_storage_account" "lab_storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.lab_rg.name
  location                 = azurerm_resource_group.lab_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "lab"
    owner       = "rog"
  }
}