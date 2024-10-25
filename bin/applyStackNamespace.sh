#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The cluster configuration file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NAMESPACE" ]; then
    echo "The stack namespace is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the stack namespace replacing the placeholders with the correspondent environment variable value.
function applyStackNamespace() {
  $KUBECTL_CMD create namespace "$NAMESPACE" \
               -o yaml \
               --dry-run=client | $KUBECTL_CMD apply -f -
}

# Main function.
function main() {
  checkDependencies
  applyStackNamespace
}

main