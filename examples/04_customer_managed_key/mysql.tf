module "mysql" {
  source = "../../"

  name                = "${var.name_prefix}-server"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  mysql_version          = "8.0.21"
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  sku_name               = "GP_Standard_D2ds_v4"

  storage = {
    size_gb = 32
  }

  delegated_subnet_id           = module.vnet.subnet_ids["fk-subnet-db"]
  private_dns_zone_id           = module.private_dns.private_dns_zone_ids["${var.name_prefix}.mysql.database.azure.com"]
  public_network_access_enabled = false

  identity = {
    type = "UserAssigned"
    identity_ids = [
      module.mysql_cmk_identity.id
    ]
    principal_ids = {
      (module.mysql_cmk_identity.id) = module.mysql_cmk_identity.principal_id
    }
    client_ids = {
      (module.mysql_cmk_identity.id) = module.mysql_cmk_identity.client_id
    }
  }

  customer_managed_key = {
    key_vault_key_id                  = module.mysql_cmk_key.id
    primary_user_assigned_identity_id = module.mysql_cmk_identity.id
  }

  databases = {
    foggydb = {}
  }

  tags = var.tags

  depends_on = [
    module.private_dns,
    module.mysql_cmk_key,
    module.mysql_cmk_rbac
  ]
}
