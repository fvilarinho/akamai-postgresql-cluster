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

  if [ -z "$IDENTIFIER" ]; then
    echo "The cluster identifier is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_VERSION" ]; then
    echo "The database version is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_NAME" ]; then
    echo "The database name is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_USER" ]; then
    echo "The database user is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_PASSWORD" ]; then
    echo "The database password is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NODES_COUNT" ]; then
    echo "The nodes count is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$STORAGE_SIZE" ]; then
    echo "The storage size is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the stack namespaces replacing the placeholders with the correspondent environment variable value.
function applyStackNamespaces() {
  $KUBECTL_CMD create namespace "$NAMESPACE" \
               -o yaml \
               --dry-run=client | $KUBECTL_CMD apply -f -
}

# Applies the stack manifest replacing the placeholders with the correspondent environment variable value.
function applyStackManifest() {
  manifestFilename="$MANIFEST_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp

  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${IDENTIFIER}|'"$IDENTIFIER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_VERSION}|'"$DATABASE_VERSION"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_NAME}|'"$DATABASE_NAME"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_OWNER}|'"$DATABASE_OWNER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_USER}|'"$DATABASE_USER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_PASSWORD}|'"$DATABASE_PASSWORD"'|g' "$manifestFilename".tmp
  sed -i -e 's|${NODES_COUNT}|'"$NODES_COUNT"'|g' "$manifestFilename".tmp
  sed -i -e 's|${STORAGE_SIZE}|'"$STORAGE_SIZE"'|g' "$manifestFilename".tmp

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