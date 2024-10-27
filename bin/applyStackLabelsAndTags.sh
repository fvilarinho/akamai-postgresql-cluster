#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The cluster configuration file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NAMESPACE" ]; then
    echo "The stack namespace file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$TAGS" ]; then
    echo "The tags are not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies stack labels and tags.
function applyStackLabelsAndTags() {
  NODES=$($KUBECTL_CMD get nodes | grep lke | awk -F' ' '{print $1}')

  echo "Applying labels and tags to nodes..."

  TAGS_PARAMS=

  for TAG in $TAGS
  do
    TAGS_PARAMS="$TAGS_PARAMS --tags \"$TAG\""
  done

  for NODE in $NODES
  do
    PODS=$($KUBECTL_CMD get pods -o wide -n "$NAMESPACE" | grep "$NODE" | awk -F' ' '{print $1}')
    NODE_IP=$($KUBECTL_CMD get node -o wide | grep "$NODE" | awk -F' ' '{print $7}')
    NODE_ID=$($LINODE_CLI_CMD linodes list --text | grep "$NODE_IP" | awk -F' ' '{print $1}')
    VOLUME_ID=$($LINODE_CLI_CMD volumes list --text | grep "$NODE_ID" | awk -F' ' '{print $1}')
    VOLUME=$($LINODE_CLI_CMD volumes list --text | grep "$NODE_ID" | awk -F' ' '{print $2}')

    $LINODE_CLI_CMD linodes update --label "$NODE" "$NODE_ID" > /dev/null 2>&1
    $LINODE_CLI_CMD volumes update --label "$VOLUME" "$VOLUME_ID" > /dev/null 2>&1

    ADDITIONAL_TAGS=

    for POD in $PODS
    do
      ADDITIONAL_TAGS="$ADDITIONAL_TAGS --tags \"$POD\""
    done

    ADDITIONAL_TAGS="$ADDITIONAL_TAGS --tags \"$NAMESPACE\""

    eval "$LINODE_CLI_CMD linodes update $TAGS_PARAMS $ADDITIONAL_TAGS $NODE_ID > /dev/null 2>&1"
    eval "$LINODE_CLI_CMD volumes update $TAGS_PARAMS $ADDITIONAL_TAGS $VOLUME_ID > /dev/null 2>&1"
  done

  echo "Applying labels and tags to node balancers..."

  NODE_BALANCERS=$($KUBECTL_CMD get svc -n "$NAMESPACE" | grep LoadBalancer | awk -F' ' '{print $4}')

  for NODE_BALANCER in $NODE_BALANCERS
  do
    NODE_BALANCER_NAME=$($KUBECTL_CMD get svc -n "$NAMESPACE" | grep "$NODE_BALANCER" | awk -F' ' '{print $1}')
    NODE_BALANCER_ID=$($LINODE_CLI_CMD nodebalancers list --text | grep "$NODE_BALANCER" | awk -F' ' '{print $1}')

    ADDITIONAL_TAGS="--tags \"$NODE_BALANCER_NAME\" --tags \"$NAMESPACE\""

    eval "$LINODE_CLI_CMD nodebalancers update $TAGS_PARAMS $ADDITIONAL_TAGS $NODE_BALANCER_ID > /dev/null 2>&1"
  done
}

# Main function.
function main() {
  checkDependencies
  applyStackLabelsAndTags
}

main