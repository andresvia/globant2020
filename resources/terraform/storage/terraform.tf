terraform {
  required_version = "=0.13.5"

  backend azurerm {
    resource_group_name = "g20-ignition-centralus"
    // storage_account_name will be set with partial config
    container_name = "g20-terraform-state"
    key            = "infra/storage.tfstate"
  }
}

provider azurerm {
  version = "=2.38.0"
  features {}
}

provider random {
  version = "=3.0.0"
}

variable registry_access_from_cidrs {
  type        = list(string)
  description = "List of CIDR blocks to allow docker registry pull/push."
}

module centralus {
  source                     = "../storage-config"
  name_prefix                = ["g20"]
  randomize_suffix           = true
  registry_access_from_cidrs = var.registry_access_from_cidrs
  config = {
    group = "g20-project-x-centralus"
  }
}

output storage {
  value = {
    centralus = module.centralus
  }
}