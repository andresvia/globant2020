terraform {
  required_version = "=0.13.5"

  backend azurerm {
    resource_group_name  = "g20-ignition-centralus"
    storage_account_name = "g20ignition79a4bb602306"
    container_name       = "g20-terraform-state"
    key                  = "infra/orchestration-permissions.tfstate"
  }
}

provider azurerm {
  version = "=2.38.0"
  features {}
}

module centralus {
  source = "../orchestration-permissions-config"
  config = {
    group    = "g20-project-x-centralus"
    name     = "g20-project-x-public"
    registry = "g20projectxea6040498c9e"
  }
}

output orchestration {
  value = {
    centralus = module.centralus
  }
}