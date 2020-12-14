variable config {
  type = object({
    name     = string
    group    = string
    registry = string
  })
}

data azurerm_kubernetes_cluster public {
  name                = var.config.name
  resource_group_name = var.config.group
}


data azurerm_container_registry registry {
  name                = var.config.registry
  resource_group_name = var.config.group
}

resource azurerm_role_assignment kube_access_to_registry {
  for_each             = toset([for identity in data.azurerm_kubernetes_cluster.public.kubelet_identity : identity.object_id])
  scope                = data.azurerm_container_registry.registry.id
  role_definition_name = "AcrPull"
  principal_id         = each.value
}

output registry {
  value = azurerm_role_assignment.kube_access_to_registry
}

output cli_test {
  value = <<SHELL
kubectl create deployment hello-world --image=${data.azurerm_container_registry.registry.login_server}/hello-world
SHELL
}
