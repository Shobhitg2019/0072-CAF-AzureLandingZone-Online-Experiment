output "web_snt_prefix" {
    value = azurerm_subnet.web_snt.address_prefixes
    description = "Web subnet prefix."
}
output "sql_snt_prefix" {
  value = azurerm_subnet.sql_snt.address_prefixes
  description = "SQL subnet prefix."
}
output "dev_snt_prefix" {
  value = azurerm_subnet.dev_snt.address_prefixes
  description = "Dev subnet prefix."
}
output "bas_snt_prefix" {
  value = azurerm_subnet.bas_snt.address_prefixes 
  description = "Bastion subnet prefix."
}

output "web_snt_id" {
  value = azurerm_subnet.web_snt.id 
  description = "Web subnet ID."
}

output "sql_snt_id" {
  value = azurerm_subnet.sql_snt.id 
  description = "SQL subnet ID."
}

output "dev_snt_id" {
  value = azurerm_subnet.dev_snt.id
  description = "DEV subnet ID."
}

output "bas_snt_id" {
  value = azurerm_subnet.bas_snt.id
  description = "Bastion subnet ID."
}

output "ip_config_list" {
  value = azurerm_network_interface.nic
  description = "List of NIC configurations."
}