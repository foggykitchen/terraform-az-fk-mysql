output "mysql_server_id" {
  description = "MySQL Flexible Server resource ID."
  value       = module.mysql.id
}

output "mysql_fqdn" {
  description = "MySQL Flexible Server FQDN."
  value       = module.mysql.fqdn
}

output "database_ids" {
  description = "Created MySQL database IDs."
  value       = module.mysql.database_ids
}

output "vnet_id" {
  description = "VNet resource ID."
  value       = module.vnet.vnet_id
}

output "db_subnet_id" {
  description = "Delegated MySQL subnet ID."
  value       = module.vnet.subnet_ids["fk-subnet-db"]
}
