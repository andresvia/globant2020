terraform {
  required_version = "=0.13.5"

  backend "azurerm" {
    resource_group_name  = "g20-ignition-centralus"
    storage_account_name = "g20ignitioncentralus"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  version = "=2.38.0"
  features {}
}