variable name_prefix {
  type = list(string)
}

variable config {
  type = object({
    group                = string
    nodes_group          = string
    compute_subnet       = string
    orchestration_subnet = string
    virtual_network      = string
    log_workspace        = string
  })
}

data azurerm_resource_group group {
  name = var.config.group
}

data azurerm_subnet compute {
  name                 = var.config.compute_subnet
  virtual_network_name = var.config.virtual_network
  resource_group_name  = var.config.group
}

data azurerm_subnet orchestration {
  name                 = var.config.orchestration_subnet
  virtual_network_name = var.config.virtual_network
  resource_group_name  = var.config.group
}

data azurerm_log_analytics_workspace workspace {
  name                = var.config.log_workspace
  resource_group_name = var.config.group
}

locals {
  sep               = "-"
  title             = ["project", "x"]
  name_parts        = concat(var.name_prefix, local.title)
  public_name_parts = concat(local.name_parts, ["public"])
  public_name       = join(local.sep, local.public_name_parts)
  public_dns_name   = join("", local.public_name_parts)
}

resource azurerm_kubernetes_cluster public {
  dns_prefix              = local.public_dns_name
  kubernetes_version      = "1.18.10"
  name                    = local.public_name
  node_resource_group     = var.config.nodes_group
  private_cluster_enabled = false
  resource_group_name     = data.azurerm_resource_group.group.name
  location                = data.azurerm_resource_group.group.location

  addon_profile {
    aci_connector_linux {
      enabled     = true
      subnet_name = data.azurerm_subnet.compute.name
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = true
    }

    kube_dashboard {
      enabled = true
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = data.azurerm_log_analytics_workspace.workspace.id
    }
  }

  default_node_pool {
    availability_zones = ["1", "2", "3"]
    name               = "agentpool"
    node_count         = 1
    vm_size            = "Standard_D4s_v4"
    vnet_subnet_id     = data.azurerm_subnet.orchestration.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    dns_service_ip     = "10.2.16.53"
    docker_bridge_cidr = "172.17.0.1/16"
    load_balancer_sku  = "Standard"
    network_plugin     = "azure"
    network_policy     = "azure"
    outbound_type      = "loadBalancer"
    service_cidr       = "10.2.16.0/20"
    load_balancer_profile {
      idle_timeout_in_minutes   = 30
      managed_outbound_ip_count = 1
    }
  }

  tags = {
    title = join(local.sep, local.title)
  }

  lifecycle {
    ignore_changes = [
      default_node_pool["node_count"],
    ]
  }
}

data azurerm_virtual_network network {
  name                = var.config.virtual_network
  resource_group_name = var.config.group
}

data azurerm_user_assigned_identity aciconnectorlinux {
  name                = join("-", ["aciconnectorlinux", azurerm_kubernetes_cluster.public.name])
  resource_group_name = var.config.nodes_group
  depends_on = [
    azurerm_kubernetes_cluster.public
  ]
}

resource azurerm_role_assignment aciconnectorlinux_access_to_network {
  scope                = data.azurerm_virtual_network.network.id
  role_definition_name = "Network Contributor"
  principal_id         = data.azurerm_user_assigned_identity.aciconnectorlinux.principal_id
}

data azurerm_subscription current {}

output public_cluster {
  value = {
    cli_connect = <<SHELL
az account set --subscription ${data.azurerm_subscription.current.subscription_id}
az aks get-credentials --resource-group ${data.azurerm_resource_group.group.name} --name ${azurerm_kubernetes_cluster.public.name}
kubectl get deployments --all-namespaces=true
SHELL
    id          = azurerm_kubernetes_cluster.public.id
    identities = {
      kubelet = azurerm_kubernetes_cluster.public.kubelet_identity
      oms_agent = flatten([for profile in azurerm_kubernetes_cluster.public.addon_profile :
        [for agent in profile["oms_agent"] : agent["oms_agent_identity"]]
      ])
    }
  }
}