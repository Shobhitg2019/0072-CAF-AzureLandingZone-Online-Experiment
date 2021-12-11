resource "azurerm_virtual_network" "vnt" {
  name = "${var.resource_codes.prefix}-${var.resource_codes.vnet}-${local.rnum}"
  location = var.rgp_location
  resource_group_name = var.rgp_name
  address_space = ["${var.vnt.addr_space_prefix}.${local.rnum}.${var.vnt.addr_space_suffix}"] 
}
# 06. subnets

# 06.01 web
resource "azurerm_subnet" "web_snt" {
  name = "${var.vnt.web_sub_name_prefix}-${local.rnum}"
  virtual_network_name = "${var.resource_codes.prefix}-${var.resource_codes.vnet}-${local.rnum}"
  resource_group_name = var.rgp_name
  address_prefixes = ["${var.vnt.addr_space_prefix}.${local.rnum}.${var.vnt.web_sub_range_suffix}"]
}

# 06.02 sql 
resource "azurerm_subnet" "sql_snt" {
  name = "${var.vnt.sql_sub_name_prefix}-${local.rnum}"
  virtual_network_name = "${var.resource_codes.prefix}-${var.resource_codes.vnet}-${local.rnum}"
  resource_group_name = var.rgp_name
  address_prefixes = ["${var.vnt.addr_space_prefix}.${local.rnum}.${var.vnt.sql_sub_range_suffix}"]
}

# 06.03 dev 
resource "azurerm_subnet" "dev_snt" {
  name = "${var.vnt.dev_sub_name_prefix}-${local.rnum}"
  virtual_network_name = "${var.resource_codes.prefix}-${var.resource_codes.vnet}-${local.rnum}"
  resource_group_name = var.rgp_name
  address_prefixes = ["${var.vnt.addr_space_prefix}.${local.rnum}.${var.vnt.dev_sub_range_suffix}"]
}

resource "azurerm_subnet" "bas_snt" {
  name = var.vnt.bas_sub_name
  virtual_network_name = "${var.resource_codes.prefix}-${var.resource_codes.vnet}-${local.rnum}"
  resource_group_name = var.rgp_name
  address_prefixes = ["${var.vnt.addr_space_prefix}.${local.rnum}.${var.vnt.bas_sub_range_suffix}"]
}

# 08. nsgs 
# 09. bastion