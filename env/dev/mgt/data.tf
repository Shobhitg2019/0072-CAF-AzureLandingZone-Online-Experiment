data "azurerm_key_vault_secret" "vm_pw" {
    name = "adminuser"
    key_vault_id = "/subscriptions/51bf817c-66af-4ca8-bcac-13d3df80171a/resourceGroups/azr-rgp-10/providers/Microsoft.KeyVault/vaults/azr-37509763-kvt-10"
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