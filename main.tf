locals {
  public_network_access     = var.public_network_access_enabled ? "Enabled" : "Disabled"
  password_auth_enabled     = var.entra_authentication.enabled ? var.entra_authentication.password_auth_enabled : true
  entra_administrator_login = var.entra_authentication.enabled && var.entra_administrator != null ? var.entra_administrator.login : null
}

data "azurerm_monitor_diagnostic_categories" "this" {
  for_each = {
    for setting_key, setting in var.diagnostic_settings :
    setting_key => setting
    if setting.log_categories == null
  }

  resource_id = azurerm_mysql_flexible_server.this.id
}

resource "azurerm_mysql_flexible_server" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  version                           = var.mysql_version
  administrator_login               = var.administrator_login
  administrator_password            = var.administrator_password
  sku_name                          = var.sku_name
  backup_retention_days             = var.backup_retention_days
  geo_redundant_backup_enabled      = var.geo_redundant_backup_enabled
  zone                              = var.zone
  delegated_subnet_id               = var.delegated_subnet_id
  private_dns_zone_id               = var.private_dns_zone_id
  public_network_access             = local.public_network_access
  create_mode                       = var.create_mode
  source_server_id                  = var.source_server_id
  point_in_time_restore_time_in_utc = var.point_in_time_restore_time_in_utc
  replication_role                  = var.replication_role
  tags                              = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key == null ? [] : [var.customer_managed_key]

    content {
      key_vault_key_id                     = customer_managed_key.value.key_vault_key_id
      primary_user_assigned_identity_id    = customer_managed_key.value.primary_user_assigned_identity_id
      geo_backup_key_vault_key_id          = customer_managed_key.value.geo_backup_key_vault_key_id
      geo_backup_user_assigned_identity_id = customer_managed_key.value.geo_backup_user_assigned_identity_id
    }
  }

  storage {
    auto_grow_enabled   = var.storage.auto_grow_enabled
    io_scaling_enabled  = var.storage.io_scaling_enabled
    iops                = var.storage.iops
    log_on_disk_enabled = var.storage.log_on_disk_enabled
    size_gb             = var.storage.size_gb
  }

  dynamic "high_availability" {
    for_each = var.high_availability == null ? [] : [var.high_availability]

    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = try(high_availability.value.standby_availability_zone, null)
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window == null ? [] : [var.maintenance_window]

    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]

    precondition {
      condition     = var.delegated_subnet_id == null || var.private_dns_zone_id != null
      error_message = "private_dns_zone_id is required when delegated_subnet_id is set."
    }

    precondition {
      condition     = !(var.delegated_subnet_id != null && var.private_dns_zone_id != null && var.public_network_access_enabled)
      error_message = "public_network_access_enabled must be false when delegated_subnet_id and private_dns_zone_id are set."
    }

    precondition {
      condition     = var.entra_administrator == null || var.entra_authentication.enabled
      error_message = "entra_authentication.enabled must be true when entra_administrator is configured."
    }

    precondition {
      condition     = !var.entra_authentication.enabled || var.entra_administrator != null
      error_message = "entra_administrator is required when entra_authentication.enabled is true."
    }

    precondition {
      condition     = var.entra_administrator == null || (var.identity != null && var.identity.type == "UserAssigned" && contains(var.identity.identity_ids, var.entra_administrator.identity_id))
      error_message = "entra_administrator requires identity.type UserAssigned and identity.identity_ids must include entra_administrator.identity_id."
    }

    precondition {
      condition     = var.customer_managed_key == null || (var.identity != null && var.identity.type == "UserAssigned" && contains(var.identity.identity_ids, var.customer_managed_key.primary_user_assigned_identity_id))
      error_message = "customer_managed_key requires identity.type UserAssigned and identity.identity_ids must include customer_managed_key.primary_user_assigned_identity_id."
    }

    precondition {
      condition     = var.customer_managed_key == null || var.customer_managed_key.geo_backup_user_assigned_identity_id == null || (var.identity != null && contains(var.identity.identity_ids, var.customer_managed_key.geo_backup_user_assigned_identity_id))
      error_message = "identity.identity_ids must include customer_managed_key.geo_backup_user_assigned_identity_id when geo backup CMK identity is set."
    }
  }
}

resource "azurerm_mysql_flexible_server_active_directory_administrator" "this" {
  count = var.entra_authentication.enabled && var.entra_administrator != null ? 1 : 0

  server_id   = azurerm_mysql_flexible_server.this.id
  identity_id = var.entra_administrator.identity_id
  login       = var.entra_administrator.login
  object_id   = var.entra_administrator.object_id
  tenant_id   = var.entra_administrator.tenant_id
}

resource "azurerm_mysql_flexible_database" "this" {
  for_each = var.databases

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = each.value.charset
  collation           = each.value.collation
}

resource "azurerm_mysql_flexible_server_firewall_rule" "this" {
  for_each = var.public_network_access_enabled ? var.firewall_rules : {}

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  start_ip_address    = each.value.start_ip_address
  end_ip_address      = each.value.end_ip_address
}

resource "azurerm_mysql_flexible_server_configuration" "this" {
  for_each = var.configurations

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  value               = each.value
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name
  target_resource_id             = azurerm_mysql_flexible_server.this.id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  storage_account_id             = each.value.storage_account_id
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id
  eventhub_name                  = each.value.eventhub_name

  dynamic "enabled_log" {
    for_each = concat(
      [
        for category in each.value.log_categories == null && length(each.value.log_category_groups) == 0 ? data.azurerm_monitor_diagnostic_categories.this[each.key].log_category_types : coalesce(each.value.log_categories, []) : {
          category       = category
          category_group = null
        }
      ],
      [
        for category_group in each.value.log_category_groups : {
          category       = null
          category_group = category_group
        }
      ]
    )

    content {
      category       = enabled_log.value.category
      category_group = enabled_log.value.category_group
    }
  }

  dynamic "enabled_metric" {
    for_each = toset(each.value.metric_categories)

    content {
      category = enabled_metric.value
    }
  }
}
