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

  if [ -z "$DATABASE_USER" ]; then
    echo "The database user is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_PASSWORD" ]; then
    echo "The database password is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_BACKUP_ACCESS_KEY" ] || [ -z "$DATABASE_BACKUP_SECRET_KEY" ]; then
    echo "The database backup credentials are not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_CONNECTION_STRING" ]; then
    echo "The database connection string is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the stack manifest replacing the placeholders with the correspondent environment variable value.
function applyStackSecrets() {
  manifestFilename="$MANIFEST_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp

  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${IDENTIFIER}|'"$IDENTIFIER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_USER}|'"$DATABASE_USER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_PASSWORD}|'"$DATABASE_PASSWORD"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_BACKUP_ACCESS_KEY}|'"$DATABASE_BACKUP_ACCESS_KEY"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_BACKUP_SECRET_KEY}|'"$DATABASE_BACKUP_SECRET_KEY"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_CONNECTION_STRING}|'"$DATABASE_CONNECTION_STRING"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Main function.
function main() {
  checkDependencies
  applyStackSecrets
}

main