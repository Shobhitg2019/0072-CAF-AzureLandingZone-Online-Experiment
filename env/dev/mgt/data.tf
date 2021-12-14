data "azurerm_key_vault_secret" "vm_pw" {
    name = "adminuser"
    vault_uri = "https://azr-37509763-kvt-10.vault.azure.net/"
    resource_group_name = azurerm_resource_group.rgp.name
    depends_on = [
      azurerm_key_vault.kvt
    ]
}

/*
PS: 12/14/2021 07:46:27>terraform plan
╷
│ Error: "vault_uri": this field cannot be set
│ 
│   with data.azurerm_key_vault.kvt,
│   on data.tf line 1, in data "azurerm_key_vault" "kvt":
│    1: data "azurerm_key_vault" "kvt" {
│ 
╵
PS: 12/14/2021 07:47:05>
*/