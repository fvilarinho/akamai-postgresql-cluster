#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the operator replacing the placeholders with the correspondent environment variable value.
function applyOperator() {
  NAMESPACE=cnpg-system

  $HELM_CMD upgrade --install cnpg \
            --namespace "$NAMESPACE" \
            --create-namespace \
            cnpg/cloudnative-pg
}

# Waits until the deployment completes.
function waitUntilCompletes() {
  while true; do
    sleep 15

    IS_READY=$($KUBECTL_CMD get crds -A | grep "clusters.postgresql.cnpg.io")

    if [ -n "$IS_READY" ]; then
      IS_READY=$($KUBECTL_CMD get pods -A | grep cnpg-cloudnative-pg | grep Running)

      if [ -n "$IS_READY" ]; then
        break
      fi
    fi

    echo "Waiting until the operator gets ready.."

    sleep 15
  done

  echo "The operator is now ready!"
}

# Main function.
function main() {
  checkDependencies
  applyOperator
  waitUntilCompletes
}

main