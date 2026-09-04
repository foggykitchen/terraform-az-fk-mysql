variable "name" {
  description = "MySQL Flexible Server name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "mysql_version" {
  description = "MySQL engine version."
  type        = string
  default     = "8.0.21"

  validation {
    condition     = contains(["5.7", "8.0.21", "8.4"], var.mysql_version)
    error_message = "mysql_version must be one of: 5.7, 8.0.21, 8.4."
  }
}

variable "administrator_login" {
  description = "MySQL administrator login."
  type        = string
  default     = "mysqladmin"
}

variable "administrator_password" {
  description = "MySQL administrator password. Required when create_mode is Default."
  type        = string
  sensitive   = true
  default     = null
}

variable "sku_name" {
  description = "MySQL Flexible Server SKU name."
  type        = string
  default     = "GP_Standard_D2ds_v4"
}

variable "storage" {
  description = "MySQL Flexible Server storage settings."
  type = object({
    auto_grow_enabled   = optional(bool, true)
    io_scaling_enabled  = optional(bool, false)
    iops                = optional(number)
    log_on_disk_enabled = optional(bool, false)
    size_gb             = optional(number, 32)
  })
  default = {}
}

variable "backup_retention_days" {
  description = "Backup retention in days."
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup."
  type        = bool
  default     = false
}

variable "zone" {
  description = "Availability zone for the primary server. Null lets Azure choose."
  type        = string
  default     = null
}

variable "delegated_subnet_id" {
  description = "Delegated subnet ID for private access mode. Leave null for public or Private Endpoint mode."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID used with delegated_subnet_id."
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable approved public traffic through firewall rules. Must be false for delegated subnet private access."
  type        = bool
  default     = true
}

variable "create_mode" {
  description = "MySQL Flexible Server create mode."
  type        = string
  default     = "Default"

  validation {
    condition     = contains(["Default", "PointInTimeRestore", "GeoRestore", "Replica"], var.create_mode)
    error_message = "create_mode must be one of: Default, PointInTimeRestore, GeoRestore, Replica."
  }
}

variable "source_server_id" {
  description = "Source server ID for restore or replica create modes."
  type        = string
  default     = null
}

variable "point_in_time_restore_time_in_utc" {
  description = "Point-in-time restore timestamp in UTC for restore scenarios."
  type        = string
  default     = null
}

variable "replication_role" {
  description = "Optional replication role. Azure currently supports updating replicas to None."
  type        = string
  default     = null
}

variable "high_availability" {
  description = "Optional high availability settings."
  type = object({
    mode                      = string
    standby_availability_zone = optional(string)
  })
  default = null
}

variable "maintenance_window" {
  description = "Optional maintenance window."
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = {
    day_of_week  = 0
    start_hour   = 22
    start_minute = 0
  }
}

variable "databases" {
  description = "Map of MySQL databases to create."
  type = map(object({
    charset   = optional(string, "utf8")
    collation = optional(string, "utf8_unicode_ci")
  }))
  default = {}
}

variable "firewall_rules" {
  description = "Map of firewall rules. Use only when public_network_access_enabled is true."
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "configurations" {
  description = "Map of MySQL server parameters."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
