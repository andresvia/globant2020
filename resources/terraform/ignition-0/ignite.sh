#!/usr/bin/env bash

set -u -x

subscription="${subscription:?missing subscription}"
name_prefix="${name_prefix:?missing name_prefix}"

export TF_VAR_name_prefix="${name_prefix}"

terraform init

terraform import module.us_central.azurerm_resource_group.ignition  "/subscriptions/${subscription}/resourceGroups/${name_prefix}-ignition-centralus"
terraform import module.us_central.azurerm_storage_account.ignition "/subscriptions/${subscription}/resourceGroups/${name_prefix}-ignition-centralus/providers/Microsoft.Storage/storageAccounts/${name_prefix}ignitioncentralus"
