terraform {
  required_version = "=0.13.5"

  backend "azurerm" {
    resource_group_name = "g20-ignition-centralus"
    // storage_account_name will be set with partial config
    container_name = "g20-terraform-state"
    key            = "infra/storage.tfstate"
  }
}

provider "azurerm" {
  version = "=2.38.0"
  features {}
}

provider "random" {
  version = "=3.0.0"
}

variable "registry_access_from_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks to allow docker registry pull/push, for production should be an empty list. Login with 'az acr login --name <registry server>'"
}

module "centralus" {
  source      = "../storage-config"
  name_prefix = ["g20"]
  // while testing should be true (taken log analytics workspaces names can't be re-used after 7 days of deletion)
  randomize_suffix           = false
  registry_access_from_cidrs = var.registry_access_from_cidrs
  config = {
    group           = "g20-project-x-centralus"
    compute_subnet  = "g20-project-x-compute"
    virtual_network = "g20-project-x"
  }
}

output "storage" {
  value = {
    centralus = module.centralus
  }
}