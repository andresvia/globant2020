variable "config" {
  type = object({
    name_prefix = string
    geo         = string
  })
}

locals {
  tags = {
    name_prefix = var.config.name_prefix
  }
}

resource "azurerm_resource_group" "ignition" {
  name     = join("-", [var.config.name_prefix, "ignition", var.config.geo])
  location = var.config.geo
  tags     = local.tags
}

resource "azurerm_storage_account" "ignition" {
  name                     = join("", [var.config.name_prefix, "ignition", var.config.geo])
  resource_group_name      = azurerm_resource_group.ignition.name
  location                 = azurerm_resource_group.ignition.location
  account_tier             = "Standard"
  account_replication_type = "LRS" // locally redundant storage
  tags                     = local.tags
}

output "resource_group" {
  value = azurerm_resource_group.ignition.id
}

output "storage_account" {
  value = azurerm_storage_account.ignition.id
}
