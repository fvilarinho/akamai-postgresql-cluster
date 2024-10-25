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

  if [ -z "$IDENTIFIER" ]; then
    echo "The stack identifier is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$MANIFEST_FILENAME" ]; then
    echo "The manifest file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_VERSION" ]; then
    echo "The database version is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_PORT" ]; then
    echo "The database port is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_NAME" ]; then
    echo "The database name is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_OWNER" ]; then
    echo "The database owner is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_BACKUP_URL" ]; then
    echo "The database backup url is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_BACKUP_RETENTION" ]; then
    echo "The database backup retention is not defined! Please define it first to continue!"

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

# Applies the stack deployment replacing the placeholders with the correspondent environment variable value.
function applyStackDeployment() {
  manifestFilename="$MANIFEST_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp

  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${IDENTIFIER}|'"$IDENTIFIER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_VERSION}|'"$DATABASE_VERSION"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_NAME}|'"$DATABASE_NAME"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_OWNER}|'"$DATABASE_OWNER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_BACKUP_URL}|'"$DATABASE_BACKUP_URL"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_BACKUP_RETENTION}|'"$DATABASE_BACKUP_RETENTION"'|g' "$manifestFilename".tmp
  sed -i -e 's|${NODES_COUNT}|'"$NODES_COUNT"'|g' "$manifestFilename".tmp
  sed -i -e 's|${STORAGE_SIZE}|'"$STORAGE_SIZE"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Waits until the deployment completes.
function waitUntilCompletes() {
  while true; do
    sleep 10

    IS_READY=$($KUBECTL_CMD get cluster -n "$NAMESPACE" | grep "Cluster in healthy state")

    if [ -n "$IS_READY" ]; then
      break
    fi

    echo "Waiting until the deployment completes..."
  done

  echo "Deployment completes!"
}

# Main function.
function main() {
  checkDependencies
  applyStackDeployment
  waitUntilCompletes
}

main