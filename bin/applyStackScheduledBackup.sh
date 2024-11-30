#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The cluster configuration file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$MANIFEST_FILENAME" ]; then
    echo "The manifest file is not defined! Please define it first to continue!"

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

  if [ -z "$DATABASE_BACKUP_SCHEDULE" ]; then
    echo "The database backup schedule is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the stack scheduled backup replacing the placeholders with the correspondent environment variable value.
function applyStackScheduledBackup() {
  manifestFilename="$MANIFEST_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp

  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${IDENTIFIER}|'"$IDENTIFIER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_BACKUP_SCHEDULE}|'"$DATABASE_BACKUP_SCHEDULE"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Main function.
function main() {
  checkDependencies
  applyStackScheduledBackup
}

main