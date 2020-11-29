variable "name_prefix" {
  type = list(string)
}

locals {
  us_central = "centralus"
}

terraform {
  required_version = "=0.13.5"
}

provider "azurerm" {
  version = "=2.38.0"
  features {}
}

provider "random" {
  version = "=3.0.0"
}

module "us_central" {
  source = "../ignition-geo"
  config = {
    name_prefix = var.name_prefix
    geo         = local.us_central
  }
}

output "ignition" {
  value = {
    (local.us_central) = module.us_central
  }
}