terraform {
  required_version = "=0.13.5"

  backend "azurerm" {
    resource_group_name  = "g20-ignition-centralus"
    storage_account_name = "g20ignition79a4bb602306"
    container_name       = "g20-terraform-state"
    key                  = "infra/network.tfstate"
  }
}

provider azurerm {
  version = "=2.38.0"
  features {}
}

module centralus {
  source      = "../network-config"
  group       = "g20-project-x-centralus"
  name_prefix = ["g20"]
}

output network {
  value = {
    centralus = module.centralus
  }
}