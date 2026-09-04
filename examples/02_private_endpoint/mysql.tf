module "mysql" {
  source = "../../"

  name                = "${var.name_prefix}-server"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  mysql_version                 = "8.0.21"
  administrator_login           = var.mysql_admin_username
  administrator_password        = var.mysql_admin_password
  sku_name                      = "GP_Standard_D2ds_v4"
  public_network_access_enabled = true
  storage = {
    size_gb = 32
  }

  databases = {
    foggydb = {}
  }

  tags = var.tags
}

module "mysql_private_endpoint" {
  source = "github.com/foggykitchen/terraform-az-fk-private-endpoint"

  name                = "${var.name_prefix}-pe"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  subnet_id                      = module.vnet.subnet_ids["fk-subnet-private-endpoint"]
  private_connection_resource_id = module.mysql.id
  subresource_names              = ["mysqlServer"]
  private_dns_zone_group_name    = "default"
  private_dns_zone_ids = [
    module.private_dns.private_dns_zone_ids["privatelink.mysql.database.azure.com"]
  ]

  tags = var.tags

  depends_on = [
    module.private_dns
  ]
}
