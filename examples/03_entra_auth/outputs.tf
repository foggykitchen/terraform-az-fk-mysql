output "mysql_server_id" {
  description = "MySQL Flexible Server resource ID."
  value       = module.mysql.id
}

output "mysql_fqdn" {
  description = "MySQL Flexible Server FQDN."
  value       = module.mysql.fqdn
}

output "entra_auth_enabled" {
  description = "Whether Microsoft Entra ID authentication is enabled."
  value       = module.mysql.entra_auth_enabled
}

output "entra_admin_group_object_id" {
  description = "Created Microsoft Entra administrator group object ID."
  value       = module.entra_admin_group.object_id
}

output "entra_admin_user_principal_name" {
  description = "Created Microsoft Entra administrator user principal name."
  value       = module.entra_admin_user.user_principal_name
}

output "entra_admin_user_object_id" {
  description = "Created Microsoft Entra administrator user object ID."
  value       = module.entra_admin_user.object_id
}

output "entra_administrator_login" {
  description = "Configured Microsoft Entra ID administrator login."
  value       = module.mysql.entra_administrator_login
}

output "entra_identity_id" {
  description = "User-assigned managed identity resource ID used for MySQL Entra administration."
  value       = module.mysql_entra_identity.id
}

output "database_ids" {
  description = "Created MySQL database IDs."
  value       = module.mysql.database_ids
}
