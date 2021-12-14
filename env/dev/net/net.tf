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
  depends_on = [
    azurerm_virtual_network.vnt
  ]
}

# 06.02 sql 
resource "azurerm_subnet" "sql_snt" {
  name = "${var.vnt.sql_sub_name_prefix}-${local.rnum}"
  virtual_network_name = "${var.resource_codes.prefix}-${var.resource_codes.vnet}-${local.rnum}"
  resource_group_name = var.rgp_name
  address_prefixes = ["${var.vnt.addr_space_prefix}.${local.rnum}.${var.vnt.sql_sub_range_suffix}"]
  depends_on = [
    azurerm_virtual_network.vnt
  ]
}

# 06.03 dev 
resource "azurerm_subnet" "dev_snt" {
  name = "${var.vnt.dev_sub_name_prefix}-${local.rnum}"
  virtual_network_name = "${var.resource_codes.prefix}-${var.resource_codes.vnet}-${local.rnum}"
  resource_group_name = var.rgp_name
  address_prefixes = ["${var.vnt.addr_space_prefix}.${local.rnum}.${var.vnt.dev_sub_range_suffix}"]
  depends_on = [
    azurerm_virtual_network.vnt
  ]
}

resource "azurerm_subnet" "bas_snt" {
  name = var.vnt.bas_sub_name
  virtual_network_name = "${var.resource_codes.prefix}-${var.resource_codes.vnet}-${local.rnum}"
  resource_group_name = var.rgp_name
  # TASK-ITEM: temporarily hard-coding 11 for subnet 3rd octet to avoid CIDR formatting error
  address_prefixes = ["${var.vnt.addr_space_prefix}.${local.bas3rdOctet}.${var.vnt.bas_sub_range_suffix}"]
  depends_on = [
    azurerm_virtual_network.vnt,
    azurerm_subnet.dev_snt
  ]
}

# 08. nsgs 

resource "azurerm_network_security_group" "nsg" {
  count = length(var.nsg_name_list)
  name = var.nsg_name_list[count.index]
  location = var.rgp_location
  resource_group_name = var.rgp_name
  tags = var.tags
}


resource "azurerm_network_security_rule" "nsr" {
  count = length(var.nsg_rules)
  name = var.nsg_rules[count.index].name 
  priority = tonumber(var.nsg_rules[count.index].priority)
  direction = var.nsg_rules[count.index].direction
  access = var.nsg_rules[count.index].access 
  protocol = var.nsg_rules[count.index].protocol
  source_port_range = var.nsg_rules[count.index].source_port_range 
  destination_port_range = var.nsg_rules[count.index].destination_port_range
  source_address_prefix = var.nsg_rules[count.index].source_address_prefix
  destination_address_prefix = var.nsg_rules[count.index].destination_address_prefix
  resource_group_name = azurerm_network_security_group.nsg[count.index].resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[count.index].name 
}
resource "azurerm_subnet_network_security_group_association" "sga" {
  count = length(local.subnet_id_list)
  subnet_id = local.subnet_id_list[count.index] 
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id 
}

# 09. nics

resource "azurerm_network_interface" "nic" {
  count = length(var.nics)
  name = var.nics[count.index].ipconfig.name 
  location = var.rgp_location 
  resource_group_name = var.rgp_name 
  ip_configuration {
    name = var.nics[count.index].ipconfig.name
    subnet_id = var.nics[count.index].ipconfig.sub_id
    private_ip_address_allocation = var.nics[count.index].ipconfig.prv_ip_alloc
  }
}

# 10. public-ips 
resource "azurerm_public_ip" "pip" {
  count = length(var.pips)
  name = var.pips[count.index].name 
  location = var.rgp_location 
  resource_group_name = var.rgp_name
  allocation_method = var.pips[count.index].alloc
  domain_name_label = "${var.pips[count.index].name}-${var.net_rnd_str}"
  sku = var.pips[count.index].sku
}

# 09. bastion

resource "azurerm_bastion_host" "bas" {
  name = "${var.resource_codes.prefix}-${var.bas_rnd_str}-${var.resource_codes.bastion}-${var.resource_number}"
  location = var.rgp_location 
  resource_group_name = var.rgp_name
  ip_configuration {
    name = "configuration"
    subnet_id = azurerm_subnet.bas_snt.id 
    public_ip_address_id = azurerm_public_ip.pip[1].id
  }
}