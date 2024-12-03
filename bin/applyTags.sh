#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NAMESPACE" ]; then
    echo "The namespace is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$CLUSTER_NODES" ]; then
    echo "The cluster nodes are not defined! Please define them first to continue!"

    exit 1
  fi

  if [ -z "$PRIMARY_NODE_BALANCER" ]; then
    echo "The primary node balancer is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$REPLICAS_NODE_BALANCER" ]; then
    echo "The replicas node balancer is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$TAGS" ]; then
    echo "The identifier is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Prepare the environment to execute the script.
function prepareToExecute() {
  export TAGS_PARAMS=

  for TAG in $TAGS
  do
    TAGS_PARAMS="$TAGS_PARAMS --tags $TAG"
  done
}

# Applies the tags in node balancers.
function applyTagsInNodeBalancers() {
  echo "Applying tags in node balancers..."

  eval "$LINODE_CLI_CMD nodebalancers update $TAGS_PARAMS --tags primary $PRIMARY_NODE_BALANCER > /dev/null"
  eval "$LINODE_CLI_CMD nodebalancers update $TAGS_PARAMS --tags replicas $REPLICAS_NODE_BALANCER > /dev/null"
}

# Applies the tags in cluster nodes.
function applyTagsInClusterNodes() {
  echo "Applying tags in cluster nodes..."

  for CLUSTER_NODE in $CLUSTER_NODES
  do
    eval "$LINODE_CLI_CMD linodes update $TAGS_PARAMS $CLUSTER_NODE > /dev/null"

    VOLUMES=$($LINODE_CLI_CMD volumes list --json | $JQ_CMD ".[]|select(.linode_id == $CLUSTER_NODE)|.id")

    for VOLUME in $VOLUMES
    do
      eval "$LINODE_CLI_CMD volumes update $TAGS_PARAMS $VOLUME > /dev/null"
    done
  done
}

# Main function.
function main() {
  checkDependencies
  prepareToExecute
  applyTagsInClusterNodes
  applyTagsInNodeBalancers
}

main