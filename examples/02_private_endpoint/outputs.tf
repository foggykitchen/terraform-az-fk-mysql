output "mysql_server_id" {
  description = "MySQL Flexible Server resource ID."
  value       = module.mysql.id
}

output "mysql_fqdn" {
  description = "MySQL Flexible Server FQDN."
  value       = module.mysql.fqdn
}

output "private_endpoint_id" {
  description = "Private Endpoint resource ID."
  value       = module.mysql_private_endpoint.private_endpoint_id
}

output "private_endpoint_ip_addresses" {
  description = "Private Endpoint IP addresses."
  value       = module.mysql_private_endpoint.private_ip_addresses
}

output "database_ids" {
  description = "Created MySQL database IDs."
  value       = module.mysql.database_ids
}
