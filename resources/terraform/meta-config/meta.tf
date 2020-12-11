variable "name_prefix" {
  type = list(string)
}

variable "location" {
  type = string
}

locals {
  sep              = "-"
  title            = ["project", "x"]
  base_name_parts  = concat(var.name_prefix, local.title)
  name_parts       = concat(local.base_name_parts, [var.location])
  nodes_name_parts = concat(local.base_name_parts, ["nodes", var.location])
  name             = join(local.sep, local.name_parts)
  nodes_name       = join(local.sep, local.nodes_name_parts)
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
    name       = azurerm_resource_group.meta.name
    nodes_name = local.nodes_name
    id         = azurerm_resource_group.meta.id
    nodes_id   = "pending"
  }
}