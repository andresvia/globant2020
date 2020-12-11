variable name_prefix {
  type = list(string)
}

variable config {
  type = object({
    group           = string
    compute_subnet  = string
    virtual_network = string
  })
}

variable randomize_suffix {
  type = bool
}

variable registry_access_from_cidrs {
  type = list(string)
}

locals {
  sep            = "-"
  title          = ["project", "x"]
  prefixed_title = concat(var.name_prefix, local.title)
  random_suffix  = var.randomize_suffix ? [random_id.suffix.hex] : []
  name_parts     = concat(local.prefixed_title, local.random_suffix)
  name           = join(local.sep, local.name_parts)
  registry_parts = concat(local.prefixed_title, [random_id.registry.hex])
  registry       = join("", local.registry_parts)
}

data azurerm_resource_group group {
  name = var.config.group
}

resource random_id suffix {
  byte_length = 6
  keepers = {
    randomize_suffix = var.randomize_suffix
  }
}

resource azurerm_log_analytics_workspace workspace {
  name                = local.name
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name
  sku                 = "Standard"
  retention_in_days   = 30
  tags = {
    title = join(local.sep, local.title)
  }
}

resource random_id registry {
  byte_length = 6
}

data azurerm_subnet compute {
  name                 = var.config.compute_subnet
  virtual_network_name = var.config.virtual_network
  resource_group_name  = var.config.group
}

resource azurerm_container_registry registry {
  name                = local.registry
  resource_group_name = data.azurerm_resource_group.group.name
  location            = data.azurerm_resource_group.group.location
  sku                 = "Premium"
  admin_enabled       = false
  network_rule_set {
    default_action = "Deny"
    virtual_network {
      action    = "Allow"
      subnet_id = data.azurerm_subnet.compute.id
    }
    ip_rule = [for cidr in var.registry_access_from_cidrs : {
      action   = "Allow"
      ip_range = cidr
    }]
  }

  tags = {
    title = join(local.sep, local.title)
  }
}

output log_analytics_workspace {
  value = {
    name = azurerm_log_analytics_workspace.workspace.name
    id   = azurerm_log_analytics_workspace.workspace.workspace_id
  }
}

output registry {
  value = {
    name   = azurerm_container_registry.registry.name
    id     = azurerm_container_registry.registry.id
    server = azurerm_container_registry.registry.login_server
  }
}