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

  if [ -z "$DATABASE_USER" ]; then
    echo "The database user is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_PASSWORD" ]; then
    echo "The database password is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_BACKUP_ACCESS_KEY" ]; then
    echo "The database backup access key is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_BACKUP_SECRET_KEY" ]; then
    echo "The database backup secret key is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DATABASE_MONITORING_URL" ]; then
    echo "The database monitoring url is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the cluster secrets replacing the placeholders with the correspondent environment variable value.
function applySecrets() {
  manifestFilename="$MANIFEST_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp

  sed -i -e 's|${IDENTIFIER}|'"$IDENTIFIER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_USER}|'"$DATABASE_USER"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_PASSWORD}|'"$DATABASE_PASSWORD"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_BACKUP_ACCESS_KEY}|'"$DATABASE_BACKUP_ACCESS_KEY"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_BACKUP_SECRET_KEY}|'"$DATABASE_BACKUP_SECRET_KEY"'|g' "$manifestFilename".tmp
  sed -i -e 's|${DATABASE_MONITORING_URL}|'"$DATABASE_MONITORING_URL"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Main function.
function main() {
  checkDependencies
  applySecrets
}

main