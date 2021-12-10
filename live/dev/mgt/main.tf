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
    name = "${var.resource_codes.prefix}-${var.resource_codes.resource_group}-${var.resource_number}"
    location = var.region
    tags = var.tags
}

# 02. storage account
resource "azurerm_storage_account" "sta" {
  name = "1${var.resource_codes.storage}${local.rnd_string}"
  resource_group_name = azurerm_resource_group.rgp.name 
  location = azurerm_resource_group.rgp.location
  account_tier = var.sta.tier 
  account_replication_type = var.sta.replication
  tags = var.tags
}

# 03. key vault
resource "azurerm_key_vault" "kvt" {
  name = "${var.resource_codes.prefix}-${local.rnd_string}-${var.resource_codes.key_vault}-${var.resource_number}"
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
  name = "${var.resource_codes.prefix}-${local.rnd_string}-${var.resource_codes.recovery_vault}-${var.resource_number}"
  location = azurerm_resource_group.rgp.location
  resource_group_name = azurerm_resource_group.rgp.name 
  sku = var.rsv_sku
  soft_delete_enabled = true
  tags = var.tags
}

# net
# 05. vnet 
resource "azurerm_virtual_network" "vnt" {
  name = "${var.resource_codes.prefix}-${var.resource_codes.vnet}-${var.resource_number}"
  location = azurerm_resource_group.rgp.location
  resource_group_name = azurerm_resource_group.rgp.name 

}
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