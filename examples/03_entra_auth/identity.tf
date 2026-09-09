module "entra_admin_user" {
  source = "github.com/foggykitchen/terraform-az-fk-entra-user"

  user_principal_name = var.entra_admin_user_principal_name
  display_name        = var.entra_admin_user_display_name
  mail_nickname       = var.entra_admin_user_mail_nickname
  password            = var.entra_admin_user_password

  force_password_change = true

  tags = var.tags
}

module "entra_admin_group" {
  source = "github.com/foggykitchen/terraform-az-fk-entra-group"

  display_name = var.entra_admin_group_name
  description  = "MySQL Flexible Server administrators for ${var.name_prefix}."
  members      = [module.entra_admin_user.object_id]

  tags = var.tags
}

module "mysql_entra_identity" {
  source = "github.com/foggykitchen/terraform-az-fk-managed-identity"

  name                = "${var.name_prefix}-entra-uai"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  tags                = var.tags
}
