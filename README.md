# terraform-az-fk-mysql

This repository contains a reusable **Terraform/OpenTofu module** and progressive examples for deploying **Azure Database for MySQL Flexible Server**, including private VNet access and Private Endpoint integration patterns.

It is part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses/azure-fundamentals-terraform-course/)** and is designed as a clean, composable database layer that integrates with existing Azure networking foundations such as VNets, delegated subnets, Private DNS Zones, and Private Endpoints.

This module is also part of the **Azure Fundamentals with Terraform/OpenTofu** learning path, where database services are composed with reusable networking and private connectivity modules.

Support expectations are documented in [SUPPORT.md](SUPPORT.md).

---

## Used By

This module is intended to be used as a building block by higher-level FoggyKitchen examples and landing zone patterns where MySQL is consumed privately by application workloads.

## 🎯 Purpose

The goal of this module is to provide a **clean, composable, and educational reference implementation** for Azure MySQL:

- Focused only on **Azure Database for MySQL Flexible Server**
- No hidden networking resources or implicit assumptions
- Designed to integrate cleanly with:
  - Azure VNets
  - Delegated database subnets
  - Private DNS Zones
  - Private Endpoints
  - Firewall rules for controlled public access scenarios

This is **not** a full Landing Zone or opinionated platform module.
It is a **learning-first, architecture-aware module**.

---

## ✨ What the module does

Depending on configuration and example used, the module can create:

- MySQL Flexible Server
- Optional databases
- Optional MySQL server configurations
- Optional firewall rules when public access is enabled
- Optional Microsoft Entra ID administrator
- Optional user-assigned managed identity
- Optional customer-managed key encryption
- Optional Azure Monitor diagnostic settings
- Private access through delegated subnet and Private DNS
- Public or Private Endpoint integration patterns when composed with other FoggyKitchen modules

The module intentionally does not create:

- Resource groups
- Virtual Networks or subnets
- Private DNS Zones
- Private Endpoints
- Network Security Groups
- Bastion hosts or validation clients
- Application schemas or seed data

Each of those concerns belongs in its own dedicated module or example layer.

---

## 📂 Repository Structure

```text
terraform-az-fk-mysql/
├── examples/
│   ├── 01_private_access_delegated_subnet/
│   ├── 02_private_endpoint/
│   ├── 03_entra_auth/
│   ├── 04_customer_managed_key/
│   ├── 05_diagnostics/
│   └── README.md
├── main.tf
├── inputs.tf
├── outputs.tf
├── versions.tf
├── LICENSE
├── SUPPORT.md
└── README.md
```

All examples are runnable and demonstrate **incremental private database design**, from delegated subnet private access to Private Endpoint integration.

---

## 🚀 Example Usage

```hcl
module "mysql" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-mysql.git?ref=v0.1.0"

  name                = "fk-mysql-dev"
  location            = "westeurope"
  resource_group_name = "fk-rg-dev"

  administrator_login    = "mysqladmin"
  administrator_password = var.mysql_admin_password

  delegated_subnet_id           = module.vnet.subnet_ids["fk-subnet-db"]
  private_dns_zone_id           = module.private_dns.private_dns_zone_ids["fk-mysql-dev.mysql.database.azure.com"]
  public_network_access_enabled = false

  databases = {
    foggydb = {}
  }

  tags = {
    project = "foggykitchen"
    env     = "dev"
  }
}
```

For Azure private access through delegated subnets, the target subnet must be delegated to `Microsoft.DBforMySQL/flexibleServers` and the Private DNS Zone must be linked to the VNet before the server is created. For Private Endpoint patterns, use `privatelink.mysql.database.azure.com`.

---

## Microsoft Entra ID Authentication

Microsoft Entra ID authentication is disabled by default. Enable it by setting `entra_authentication.enabled = true` and configure `entra_administrator`.

MySQL Flexible Server requires a user-assigned managed identity for the Entra administrator, so the identity must also be assigned to the server through `identity.identity_ids`.

```hcl
identity = {
  type         = "UserAssigned"
  identity_ids = [azurerm_user_assigned_identity.mysql_entra.id]
}

entra_authentication = {
  enabled               = true
  password_auth_enabled = true
}

entra_administrator = {
  login       = "fk-mysql-admins"
  object_id   = var.entra_admin_group_object_id
  tenant_id   = var.tenant_id
  identity_id = azurerm_user_assigned_identity.mysql_entra.id
}
```

AzureRM `4.x` exposes the MySQL Entra administrator as `azurerm_mysql_flexible_server_active_directory_administrator`. Unlike PostgreSQL Flexible Server, the current MySQL server resource does not expose an `authentication` block for toggling password authentication, so `password_auth_enabled` is accepted for contract compatibility but is not sent to `azurerm_mysql_flexible_server`.

---

## Customer-Managed Key Encryption

Customer-managed key encryption is disabled by default. To enable it, pass a Key Vault key ID and a user-assigned identity that has access to the key.

```hcl
identity = {
  type         = "UserAssigned"
  identity_ids = [azurerm_user_assigned_identity.mysql_cmk.id]
}

customer_managed_key = {
  key_vault_key_id                  = var.key_vault_key_id
  primary_user_assigned_identity_id = azurerm_user_assigned_identity.mysql_cmk.id
}
```

The module references Key Vault keys by ID only and does not create or manage key material. In composed examples, use `terraform-az-fk-managed-identity` for the user-assigned identity, `terraform-az-fk-rbac` for Key Vault crypto access, `terraform-az-fk-key-vault` for the Key Vault layer, and `terraform-az-fk-key-vault-key` for the key.

---

## Diagnostic Settings

Diagnostic settings are disabled by default. Configure one or more entries in `diagnostic_settings` to send MySQL logs and metrics to Log Analytics, Storage, or Event Hubs.

```hcl
diagnostic_settings = {
  log_analytics = {
    name                       = "fk-mysql-diag"
    log_analytics_workspace_id = var.log_analytics_workspace_id
    log_category_groups        = ["allLogs"]
    metric_categories          = ["AllMetrics"]
  }
}
```

By default, examples use the Azure Monitor `allLogs` category group. If you need explicit categories instead, set `log_category_groups = []` and provide `log_categories`; when `log_categories = null` and `log_category_groups = []`, the module discovers and enables all currently available MySQL Flexible Server log categories.

Azure Database for MySQL Flexible Server exposes these diagnostic log categories:

| Category | Description |
|----------|-------------|
| `MySqlAuditLogs` | MySQL audit logs |
| `MySqlSlowLogs` | MySQL slow query logs |

Metrics use `AllMetrics`.

Use `terraform-az-fk-log-analytics` v1.x to create or reference the Log Analytics workspace in an upstream composition layer, then pass the workspace resource ID to `diagnostic_settings[*].log_analytics_workspace_id`.

---

## ⚙️ Module Inputs

### Core inputs

| Variable | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | `string` | ✅ | MySQL Flexible Server name |
| `location` | `string` | ✅ | Azure region |
| `resource_group_name` | `string` | ✅ | Resource Group name |
| `administrator_password` | `string` | ✅ for `Default` create mode | MySQL administrator password |
| `entra_authentication` | `object` | ❌ | Optional Microsoft Entra ID authentication settings |
| `entra_administrator` | `object` | ❌ | Optional Microsoft Entra ID administrator |
| `mysql_version` | `string` | ❌ | MySQL engine version |
| `administrator_login` | `string` | ❌ | MySQL administrator login |
| `sku_name` | `string` | ❌ | MySQL Flexible Server SKU |
| `storage` | `object` | ❌ | Storage size, auto-grow, IOPS, and log-on-disk settings |
| `backup_retention_days` | `number` | ❌ | Backup retention in days |
| `geo_redundant_backup_enabled` | `bool` | ❌ | Enable geo-redundant backup |
| `zone` | `string` | ❌ | Availability zone for the primary server |
| `delegated_subnet_id` | `string` | ❌ | Delegated subnet ID for private access mode |
| `private_dns_zone_id` | `string` | ❌ | Private DNS Zone ID used with delegated subnet private access |
| `public_network_access_enabled` | `bool` | ❌ | Enable public network access for firewall-rule scenarios |
| `create_mode` | `string` | ❌ | Create mode: `Default`, `PointInTimeRestore`, `GeoRestore`, or `Replica` |
| `source_server_id` | `string` | ❌ | Source server ID for restore or replica modes |
| `point_in_time_restore_time_in_utc` | `string` | ❌ | UTC timestamp for point-in-time restore |
| `replication_role` | `string` | ❌ | Optional replication role |
| `high_availability` | `object` | ❌ | High availability settings |
| `maintenance_window` | `object` | ❌ | Maintenance window settings |
| `identity` | `object` | ❌ | Optional user-assigned managed identity configuration |
| `customer_managed_key` | `object` | ❌ | Optional customer-managed key encryption settings |
| `databases` | `map(object)` | ❌ | MySQL databases to create |
| `firewall_rules` | `map(object)` | ❌ | Firewall rules used when public network access is enabled |
| `configurations` | `map(string)` | ❌ | MySQL server parameters |
| `diagnostic_settings` | `map(object)` | ❌ | Azure Monitor diagnostic settings |
| `tags` | `map(string)` | ❌ | Resource tags |

### Storage object schema

```hcl
storage = object({
  auto_grow_enabled   = optional(bool, true)
  io_scaling_enabled  = optional(bool, false)
  iops                = optional(number)
  log_on_disk_enabled = optional(bool, false)
  size_gb             = optional(number, 32)
})
```

### Database object schema

```hcl
databases = map(object({
  charset   = optional(string, "utf8")
  collation = optional(string, "utf8_unicode_ci")
}))
```

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `id` | MySQL Flexible Server resource ID |
| `name` | MySQL Flexible Server name |
| `fqdn` | MySQL Flexible Server FQDN |
| `version` | MySQL engine version |
| `administrator_login` | MySQL administrator login |
| `delegated_subnet_id` | Delegated subnet ID used by the server |
| `private_dns_zone_id` | Private DNS Zone ID used by the server |
| `public_network_access_enabled` | Whether public network access is enabled |
| `entra_auth_enabled` | Whether Microsoft Entra ID authentication is enabled |
| `entra_administrator_login` | Configured Microsoft Entra ID administrator login |
| `entra_password_auth_enabled` | Requested password authentication setting for Microsoft Entra ID authentication |
| `cmk_enabled` | Whether customer-managed key encryption is enabled |
| `identity_ids` | User-assigned identity resource IDs assigned to the MySQL Flexible Server |
| `identity_principal_ids` | User-assigned identity principal IDs keyed by identity resource ID |
| `identity_client_ids` | User-assigned identity client IDs keyed by identity resource ID |
| `replica_capacity` | Maximum number of replicas supported by the primary server |
| `database_ids` | Map of database resource IDs keyed by database name |
| `diagnostic_setting_ids` | Map of diagnostic setting resource IDs keyed by diagnostic setting key |

---

## 🧩 Examples Overview

| Example | Description |
|-------|-------------|
| `01_private_access_delegated_subnet` | MySQL Flexible Server with delegated subnet private access and Private DNS integration |
| `02_private_endpoint` | MySQL Flexible Server composed with Azure Private Endpoint and Private DNS Zone Group |
| `03_entra_auth` | MySQL Flexible Server with Microsoft Entra ID administrator and user-assigned identity |
| `04_customer_managed_key` | MySQL Flexible Server with customer-managed key encryption |
| `05_diagnostics` | MySQL Flexible Server with Azure Monitor diagnostic settings to Log Analytics |

See [`examples/`](examples) for details.

---

## 🧠 Design Philosophy

- MySQL is a data service, not a networking module
- Private connectivity is explicit and composed from separate FoggyKitchen modules
- Delegated subnet private access and Private Endpoint patterns are both supported
- Outputs expose IDs and FQDNs needed by higher-level application modules
- Defaults are suitable for training and development, not production policy enforcement

---

## 🧩 Related Modules & Training

- [terraform-az-fk-vnet](https://github.com/foggykitchen/terraform-az-fk-vnet)
- [terraform-az-fk-private-dns](https://github.com/foggykitchen/terraform-az-fk-private-dns)
- [terraform-az-fk-private-endpoint](https://github.com/foggykitchen/terraform-az-fk-private-endpoint)
- [terraform-az-fk-compute](https://github.com/foggykitchen/terraform-az-fk-compute)
- [terraform-az-fk-nsg](https://github.com/foggykitchen/terraform-az-fk-nsg)

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
