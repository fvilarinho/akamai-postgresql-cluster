#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The cluster configuration file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$MANIFEST_FILENAME" ]; then
    echo "The cluster manifest file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NAMESPACE" ]; then
    echo "The cluster namespace is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$LABEL" ]; then
    echo "The cluster label is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NODES_COUNT" ]; then
    echo "The nodes count is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$STORAGE_DATA_SIZE" ]; then
    echo "The nodes storages data size is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the stack namespaces replacing the placeholders with the correspondent environment variable value.
function applyStackNamespaces() {
  $KUBECTL_CMD create namespace "$NAMESPACE" -o yaml --dry-run=client | $KUBECTL_CMD apply -f -
}

# Applies the stack manifest replacing the placeholders with the correspondent environment variable value.
function applyStackManifest() {
  manifestFilename="$MANIFEST_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp

  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${LABEL}|'"$LABEL"'|g' "$manifestFilename".tmp
  sed -i -e 's|${NODES_COUNT}|'"$NODES_COUNT"'|g' "$manifestFilename".tmp
  sed -i -e 's|${STORAGE_DATA_SIZE}|'"$STORAGE_DATA_SIZE"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Main function.
function main() {
  checkDependencies
  applyStackNamespaces
  applyStackManifest
}

main