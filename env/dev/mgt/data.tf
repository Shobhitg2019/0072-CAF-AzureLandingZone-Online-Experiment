data "azurerm_key_vault_secret" "vm_pw" {
    name = var.kvt.name
    key_vault_id = var.kvt.id
    depends_on = [
      azurerm_key_vault.kvt
    ]
}