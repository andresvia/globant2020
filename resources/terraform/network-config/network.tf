variable name_prefix {
  type = list(string)
}

variable group {
  type = string
}

data azurerm_resource_group group {
  name = var.group
}

locals {
  sep                      = "-"
  title                    = ["project", "x"]
  name_parts               = concat(var.name_prefix, local.title)
  compute_name_parts       = concat(local.name_parts, ["compute"])
  orchestration_name_parts = concat(local.name_parts, ["orchestration"])
  storage_name_parts       = concat(local.name_parts, ["storage"])
  name                     = join(local.sep, local.name_parts)
}

resource azurerm_virtual_network network {
  name                = local.name
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name
  address_space = [
    "10.0.16.0/20",
  ]
  vm_protection_enabled = true

  tags = {
    title = join(local.sep, local.title)
  }
}

resource azurerm_subnet compute {
  name                 = join(local.sep, local.compute_name_parts)
  resource_group_name  = data.azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes = [
    "10.0.18.0/23",
  ]
  service_endpoints = [
    "Microsoft.ContainerRegistry"
  ]
}

resource azurerm_subnet orchestration {
  name                 = join(local.sep, local.orchestration_name_parts)
  resource_group_name  = data.azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes = [
    "10.0.22.0/23",
  ]
}

resource azurerm_subnet storage {
  name                 = join(local.sep, local.storage_name_parts)
  resource_group_name  = data.azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes = [
    "10.0.26.0/23",
  ]
}

output compute {
  value = {
    name = azurerm_subnet.compute.name
    id   = azurerm_subnet.compute.id
  }
}

output orchestration {
  value = {
    name = azurerm_subnet.orchestration.name
    id   = azurerm_subnet.orchestration.id
  }
}

output storage {
  value = {
    name = azurerm_subnet.storage.name
    id   = azurerm_subnet.storage.id
  }
}