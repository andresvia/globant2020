variable "name_prefix" {
  type = list(string)
}

variable "location" {
  type = string
}

locals {
  sep        = "-"
  title      = ["project", "x"]
  name_parts = concat(var.name_prefix, local.title, [var.location])
  name       = join(local.sep, local.name_parts)
}

resource "azurerm_resource_group" "meta" {
  name     = local.name
  location = var.location
  tags = {
    title = join(local.sep, local.title)
  }
}

output "meta" {
  value = {
    name = azurerm_resource_group.meta.name
    id   = azurerm_resource_group.meta.id
  }
}