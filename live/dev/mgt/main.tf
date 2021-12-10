# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 2.46.0"
    }
    random = {
        source = "hashicorp/random"
        version = "~> 3.1.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

provider "random" {

}

resource "random_string" "rnd" {
  length = 8
  special = false 
  number = true
  lower = false
  upper = false
}

# local parameters
locals {
  rnd_string = random_string.rnd.result
}
# mgt
# 01. resource group 
resource "azurerm_resource_group" "rgp" {
    name = "${var.resource_prefix}-${var.resource_group_code}-${var.resource_number}"
    location = var.region
    tags = var.tags
}

# 02. storage account
resource "azurerm_storage_account" "sta" {
  name = "1${var.storage_infix}${local.rnd_string}"
  resource_group_name = azurerm_resource_group.rgp.name 
  location = azurerm_resource_group.rgp.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  tags = var.tags
}

# 03. key vault
resource "azurerm_key_vault" "kvt" {
  name = "${var.resource_prefix}-${local.rnd_string}-${var.kvt_code}-${var.resource_number}"
  location = azurerm_resource_group.rgp.location 
  resource_group_name = azurerm_resource_group.rgp.name 
  enabled_for_disk_encryption = true
  tenant_id = var.tenant_id
  soft_delete_retention_days = var.kvt_retention_days
  purge_protection_enabled = false
  sku_name = var.kvt_sku
  tags = var.tags
}

# 04. recovery services vault
resource "azurerm_recovery_services_vault" "rsv" {
  name = "${var.resource_prefix}-${local.rnd_string}-${var.rsv_code}-${var.resource_number}"
  location = azurerm_resource_group.rgp.location
  resource_group_name = azurerm_resource_group.rgp.name 
  sku = var.rsv_sku
  soft_delete_enabled = true
  tags = var.tags
}

# net
# 05. vnet 
# 06. subnets
# 08. nsgs 
# 09. bastion

# 05. mgt vm

# web
# 10. public-ip
# 11. avset
# 12. scale set
# 13. alb

# data
# 14. sql server






