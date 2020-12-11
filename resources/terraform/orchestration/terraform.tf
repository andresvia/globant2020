terraform {
  required_version = "=0.13.5"

  backend azurerm {
    resource_group_name = "g20-ignition-centralus"
    // storage_account_name will be set with partial config
    container_name = "g20-terraform-state"
    key            = "infra/orchestration.tfstate"
  }
}

provider azurerm {
  version = "=2.38.0"
  features {}
}

module centralus {
  source      = "../orchestration-config"
  name_prefix = ["g20"]
  config = {
    group                = "g20-project-x-centralus"
    nodes_group          = "g20-project-x-nodes-centralus"
    compute_subnet       = "g20-project-x-compute"
    orchestration_subnet = "g20-project-x-orchestration"
    virtual_network      = "g20-project-x"
    log_workspace        = "g20-project-x-1928a747f450"
    registry             = "g20projectxea6040498c9e"
  }
}

output orchestration {
  value = {
    centralus = module.centralus
  }
}