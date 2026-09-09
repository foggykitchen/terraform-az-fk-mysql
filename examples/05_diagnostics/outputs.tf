output "mysql_server_id" {
  description = "MySQL Flexible Server resource ID."
  value       = module.mysql.id
}

output "mysql_fqdn" {
  description = "MySQL Flexible Server FQDN."
  value       = module.mysql.fqdn
}

output "diagnostic_setting_ids" {
  description = "Diagnostic setting resource IDs."
  value       = module.mysql.diagnostic_setting_ids
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID."
  value       = module.log_analytics.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace name."
  value       = module.log_analytics.name
}

output "database_ids" {
  description = "Created MySQL database IDs."
  value       = module.mysql.database_ids
}
