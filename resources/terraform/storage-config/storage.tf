variable name_prefix {
  type = list(string)
}

variable config {
  type = object({
    group = string
  })
}

variable randomize_suffix {
  type = bool
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
  sku                 = "Standard" // should be Premium
  retention_in_days   = 30
  tags = {
    title = join(local.sep, local.title)
  }
}

resource random_id registry {
  byte_length = 6
}

resource azurerm_container_registry registry {
  name                = local.registry
  resource_group_name = data.azurerm_resource_group.group.name
  location            = data.azurerm_resource_group.group.location
  sku                 = "Standard" // should be Premium
  admin_enabled       = true       // should be false
  // network_rule_set { default_action = "Allow" } // should be Deny

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

data azurerm_subscription current {}

output registry {
  value = {
    name     = azurerm_container_registry.registry.name
    id       = azurerm_container_registry.registry.id
    server   = azurerm_container_registry.registry.login_server
    cli_test = <<SHELL
az account set --subscription ${data.azurerm_subscription.current.subscription_id}
az acr login --name ${azurerm_container_registry.registry.name}
docker pull hello-world
docker tag hello-world ${azurerm_container_registry.registry.login_server}/hello-world
docker push ${azurerm_container_registry.registry.login_server}/hello-world
docker pull ${azurerm_container_registry.registry.login_server}/hello-world
docker run ${azurerm_container_registry.registry.login_server}/hello-world
SHELL
  }
}