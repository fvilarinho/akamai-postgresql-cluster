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

  if [ -z "$IDENTIFIER" ]; then
    echo "The identifier is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NAMESPACE" ]; then
    echo "The namespace is not defined! Please define it first to continue!"

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

  if [ -z "$DATABASE_BACKUP_SCHEDULE" ]; then
    echo "The database backup schedule is not defined! Please define it first to continue!"

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

# Applies the cluster deployments replacing the placeholders with the correspondent environment variable value.
function applyDeployments() {
  manifestFilename="$MANIFEST_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp

  sed -i -e 's|${IDENTIFIER}|'"$IDENTIFIER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_VERSION}|'"$DATABASE_VERSION"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_NAME}|'"$DATABASE_NAME"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_OWNER}|'"$DATABASE_OWNER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_BACKUP_URL}|'"$DATABASE_BACKUP_URL"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_BACKUP_RETENTION}|'"$DATABASE_BACKUP_RETENTION"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_BACKUP_SCHEDULE}|'"$DATABASE_BACKUP_SCHEDULE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${NODES_COUNT}|'"$NODES_COUNT"'|g' "$manifestFilename".tmp
  sed -i -e 's|${STORAGE_SIZE}|'"$STORAGE_SIZE"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Waits until the deployment completes.
function waitUntilCompletes() {
  while true; do
    sleep 15

    IS_READY=$($KUBECTL_CMD get cluster -n "$NAMESPACE" | grep "Cluster in healthy state")

    if [ -n "$IS_READY" ]; then
      break
    fi

    echo "Waiting until the cluster gets ready..."

    sleep 15
  done

  echo "Cluster is now ready!"
}

# Main function.
function main() {
  checkDependencies
  applyDeployments
  waitUntilCompletes
}

main