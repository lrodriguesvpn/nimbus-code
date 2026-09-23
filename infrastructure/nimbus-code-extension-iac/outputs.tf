output "resource_group_name" {
  description = "Nome do Resource Group criado."
  value       = azurerm_resource_group.rg.name
}

output "entitlement_api_fqdn" {
  description = "FQDN público da API de Entitlement e Telemetria no Azure Container Apps."
  value       = azurerm_container_app.entitlement_api.latest_revision_fqdn
}

output "key_vault_uri" {
  description = "URI do Azure Key Vault contendo a chave mestra Ed25519."
  value       = azurerm_key_vault.kv.vault_uri
}

output "audit_storage_account_name" {
  description = "Nome da Storage Account com Ledger WORM Imutável por 5 anos."
  value       = azurerm_storage_account.audit_storage.name
}

output "database_fqdn" {
  description = "FQDN do Azure PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.db.fqdn
}
