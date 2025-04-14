#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$MANIFEST_FILENAME" ]; then
    echo "The manifest file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NAMESPACE" ]; then
    echo "The namespace is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the cluster config maps replacing the placeholders with the correspondent environment variable value.
function applyConfigMaps() {
  manifestFilename="$MANIFEST_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp

  sed -i -e 's|${IDENTIFIER}|'"$IDENTIFIER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Main function.
function main() {
  checkDependencies
  applyConfigMaps
}

main