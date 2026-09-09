variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "name_prefix" {
  description = "Name prefix for example resources."
  type        = string
  default     = "fk-mysql04"
}

variable "vnet_address_space" {
  description = "VNet address space."
  type        = string
  default     = "10.80.0.0/16"
}

variable "mysql_admin_username" {
  description = "MySQL administrator login."
  type        = string
  default     = "mysqladmin"
}

variable "mysql_admin_password" {
  description = "MySQL administrator password."
  type        = string
  sensitive   = true
}

variable "key_vault_key_name" {
  description = "Key Vault key name used for MySQL customer-managed encryption."
  type        = string
  default     = "mysql-cmk"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default = {
    project     = "foggykitchen"
    environment = "dev"
    managed_by  = "opentofu"
  }
}
