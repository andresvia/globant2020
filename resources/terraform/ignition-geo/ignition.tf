variable config {
  type = object({
    name_prefix = list(string)
    geo         = string
  })
}

locals {
  length_name_prefix = length(var.config.name_prefix)
  range_name_prefix  = range(local.length_name_prefix)
  name_prefix_keys   = [for x in local.range_name_prefix : "name_prefix.${x}"]
  name_prefix_map    = zipmap(local.name_prefix_keys, var.config.name_prefix)
  tags = merge(local.name_prefix_map, {
    class = "ignition"
  })
}

resource azurerm_resource_group ignition {
  name     = join("-", concat(var.config.name_prefix, ["ignition", var.config.geo]))
  location = var.config.geo
  tags     = local.tags
}

resource random_id storage_account {
  byte_length = 6
}

resource azurerm_storage_account ignition {
  name = substr(join("", concat(var.config.name_prefix, [
    "ignition",
    random_id.storage_account.hex,
  ])), 0, 24)
  resource_group_name      = azurerm_resource_group.ignition.name
  location                 = azurerm_resource_group.ignition.location
  account_tier             = "Standard"
  account_replication_type = "LRS" // locally redundant storage
  tags = merge(local.tags, {
    name_generator = random_id.storage_account.b64_url
  })
}

resource azurerm_storage_container terraform_state {
  name                  = join("-", concat(var.config.name_prefix, ["terraform-state"]))
  storage_account_name  = azurerm_storage_account.ignition.name
  container_access_type = "private"
}

output resource_group {
  value = azurerm_resource_group.ignition.id
}

output name_generator {
  value = random_id.storage_account.b64_url
}

output storage_account {
  value = azurerm_storage_account.ignition.id
}

output storage_container {
  value = azurerm_storage_container.terraform_state.id
}
