variable "name_prefix" {
  type = list(string)
}

variable "group" {
  type = string
}

data "azurerm_resource_group" "group" {
  name = var.group
}

locals {
  sep                = "-"
  title              = ["project", "x"]
  name_parts         = concat(var.name_prefix, local.title)
  compute_name_parts = concat(local.name_parts, ["compute"])
  name               = join(local.sep, local.name_parts)
}

resource "azurerm_virtual_network" "network" {
  name                  = local.name
  location              = data.azurerm_resource_group.group.location
  resource_group_name   = data.azurerm_resource_group.group.name
  address_space         = ["10.0.0.64/26"]
  vm_protection_enabled = true

  tags = {
    title = join(local.sep, local.title)
  }
}

resource "azurerm_subnet" "compute" {
  name                 = join(local.sep, local.compute_name_parts)
  resource_group_name  = data.azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.0.72/29"]
}

output "compute" {
  value = {
    name = azurerm_subnet.compute.name
    id   = azurerm_subnet.compute.id
  }
}