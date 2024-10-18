#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The cluster configuration file is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the stack operator replacing the placeholders with the correspondent environment variable value.
function applyStackOperator() {
  $KUBECTL_CMD apply --server-side -f \
               https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.24/releases/cnpg-1.24.1.yaml

  NAMESPACE=cnpg-system

  while true; do
    sleep 5

    OPERATOR_IS_RUNNING=$($KUBECTL_CMD get pods -n "$NAMESPACE" | grep Running)

    if [ -n "$OPERATOR_IS_RUNNING" ]; then
      echo "The cluster operator is now running!"

      break
    fi
  done
}

# Main function.
function main() {
  checkDependencies
  applyStackOperator
}

main