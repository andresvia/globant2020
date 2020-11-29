#!/usr/bin/env bash

set -u -x

subscription="${subscription:?missing subscription}"
name_prefix="${name_prefix:?missing name_prefix}"
ignition_b64_name="${ignition_b64_name}"

read -r ignition_hex_name _ <<< "$(echo -n "${ignition_b64_name}" | base64 --decode | hexdump -e '16/1 "%02x"')"

export TF_VAR_name_prefix='["'"${name_prefix}"'"]'

terraform init

terraform import module.us_central.azurerm_resource_group.ignition  "/subscriptions/${subscription}/resourceGroups/${name_prefix}-ignition-centralus"

terraform import module.us_central.random_id.storage_account "${ignition_b64_name}"

terraform import module.us_central.azurerm_storage_account.ignition "/subscriptions/${subscription}/resourceGroups/${name_prefix}-ignition-centralus/providers/Microsoft.Storage/storageAccounts/${name_prefix}ignition${ignition_hex_name}"

terraform import module.us_central.azurerm_storage_container.terraform_state "https://${name_prefix}ignition${ignition_hex_name}.blob.core.windows.net/${name_prefix}-terraform-state"

terraform apply