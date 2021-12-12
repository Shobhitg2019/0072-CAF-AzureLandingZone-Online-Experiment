# references
# 1. https://stackoverflow.com/questions/67012478/locals-tf-file-parsing-jsonencode-body

# glb

resource "random_string" "rnd" {
  length  = 8
  special = false
  number  = true
  lower   = false
  upper   = false
}

# mgt
# 01. resource group 
resource "azurerm_resource_group" "rgp" {
  name     = "${var.resource_codes.prefix}-${var.resource_codes.resource_group}-${local.res_num}"
  location = var.region
  tags     = var.tags
}

# 02. storage account
resource "azurerm_storage_account" "sta" {
  name                     = "1${var.resource_codes.storage}${local.rnd_string}"
  resource_group_name      = azurerm_resource_group.rgp.name
  location                 = azurerm_resource_group.rgp.location
  account_tier             = var.sta.tier
  account_replication_type = var.sta.replication
  tags                     = var.tags
}

# 03. key vault
resource "azurerm_key_vault" "kvt" {
  name                        = "${var.resource_codes.prefix}-${local.rnd_string}-${var.resource_codes.key_vault}-${local.res_num}"
  location                    = azurerm_resource_group.rgp.location
  resource_group_name         = azurerm_resource_group.rgp.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = var.kvt_retention_days
  purge_protection_enabled    = false
  sku_name                    = var.kvt_sku
  tags                        = var.tags
}

# 04. recovery services vault
resource "azurerm_recovery_services_vault" "rsv" {
  name                = "${var.resource_codes.prefix}-${local.rnd_string}-${var.resource_codes.recovery_vault}-${local.res_num}"
  location            = azurerm_resource_group.rgp.location
  resource_group_name = azurerm_resource_group.rgp.name
  sku                 = var.rsv_sku
  soft_delete_enabled = true
  tags                = var.tags
}

# net
module "net" {
  source          = "../../../modules/modules/net"
  resource_number = var.resource_number
  rgp_location  = azurerm_resource_group.rgp.location
  rgp_name      = azurerm_resource_group.rgp.name
  #  series_suffix = "01"
  vnt = {
    addr_space_prefix    = "10.20"
    addr_space_suffix    = "0/26"
    web_sub_name_prefix  = "web-snt"
    web_sub_range_suffix = "0/29"
    sql_sub_name_prefix  = "sql-snt"
    sql_sub_range_suffix = "8/29"
    dev_sub_name_prefix  = "dev-snt"
    dev_sub_range_suffix = "16/29"
    bas_sub_name         = "AzureBastionSubnet"
    bas_sub_range_suffix = "32/27"
  }
  resource_codes = {
    prefix            = "azr"
    resource_group    = "rgp"
    key_vault         = "kvt"
    recovery_vault    = "rsv"
    storage           = "sta"
    ext_load_balancer = "elb"
    web               = "web"
    development       = "dev"
    subnet            = "snt"
    sql               = "sql"
    vnet              = "vnt"
    net_sec_grp       = "nsg"
    public_ip         = "pip"
    bastion           = "bas"
    availaiblity_set  = "avs"
  }
  tags = {
    "environment" = "dev"
  }

  nsg_objects = [
    {
      name = "web-nsg-${var.resource_number}",
      rule = {
        http = {
          name = "http"
          priority = 100
          direction = "Inbound"
          access = "Allow"
          protocol = "Tcp"
          source_port_range = "*"
          destination_port_range = "80"
          source_address_prefix = "Internet"
          destination_address_prefix = module.net.web_snt_prefix[0]
        }
      },
      tags = var.tags
    },
    {
      name = "sql-nsg-${var.resource_number}",
      rule = {
        http = {
          name = "sql"
          priority = 110
          direction = "Inbound"
          access = "Allow"
          protocol = "Tcp"
          source_port_range = "*"
          destination_port_range = "1443"
          source_address_prefixes = [module.net.web_snt_prefix[0],module.net.dev_snt_prefix[0]]
          destination_address_prefix = module.net.sql_snt_prefix[0]
        }
      },
      tags = var.tags
    },
    {
      name = "dev-nsg-${var.resource_number}",
      rule = {
        http = {
          name = "dev"
          priority = 110
          direction = "Inbound"
          access = "Allow"
          protocol = "Tcp"
          source_port_range = "*"
          destination_port_range = "3389"
          source_address_prefixes = [module.net.web_snt_prefix[0],module.net.sql_snt_prefix[0]]
          destination_address_prefix = module.net.sql_snt_prefix[0]
        }
      },
      tags = var.tags
    }
  ]
}


# 05. mgt vm

# web
# 10. public-ip
# 11. avset
# 12. scale set
# 13. alb

# data
# 14. sql server
