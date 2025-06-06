#!/bin/bash

source ./iac.tf.sh

pushd "${WORKSPACE_PATH}/IAC/Terraform/terraform" || exit

SAVEIFS=${IFS}
IFS=$'\n'
modules=($(find . -type f -name main.tf | sort -r | awk '$0 !~ last "/" {print last} {last=$0} END {print last}'))
IFS=${SAVEIFS}

# in case ENVIRONMENT_DIRECTORY is empty, we set it to ENVIRONMENT_NAME (for backwards compatibility)
if [[ -z "${ENVIRONMENT_DIRECTORY}" ]]; then
  ENVIRONMENT_DIRECTORY="${ENVIRONMENT_NAME}"
fi

export TF_VAR_env=$ENVIRONMENT_NAME

for deployment in "${modules[@]}"; do
  if [[ ${deployment} != *"01_init"* ]]; then
    tfPath=$(dirname "${deployment}")

    _information "Executing tf destroy: ${tfPath}"
    pushd "${tfPath}" || exit

    init true "${ENVIRONMENT_NAME}${tfPath}.tfstate" "${STATE_STORAGE_ACCOUNT}" "${STATE_CONTAINER}" "${STATE_RG}"

    envfile=${tfPath/'./'/''}
    envfile=${envfile/'/'/'_'}

    destroy "${WORKSPACE_PATH}/env/terraform/${ENVIRONMENT_DIRECTORY}/${envfile}.tfvars.json"
    exit_code=$?

    if [[ ${exit_code} != 0 ]]; then
      _error "tf destroy failed - returned code ${exit_code}"
      exit ${exit_code}
    fi
    popd || exit
  fi
done
popd || exit
