#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The cluster configuration file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NAMESPACE" ]; then
    echo "The cluster namespace file is not defined! Please define it first to continue!"

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

  for NODE in $NODES
  do
    LABEL=$($KUBECTL_CMD get pods -o wide -n "$NAMESPACE" | grep "$NODE" | awk -F' ' '{print $1}')
    NODE_IP=$($KUBECTL_CMD get node -o wide | grep "$NODE" | awk -F' ' '{print $7}')
    NODE_ID=$($LINODE_CLI_CMD linodes list --text | grep "$NODE_IP" | awk -F' ' '{print $1}')
    VOLUME_ID=$($LINODE_CLI_CMD volumes list --text | grep "$NODE_ID" | awk -F' ' '{print $1}')
    VOLUME=$($LINODE_CLI_CMD volumes list --text | grep "$NODE_ID" | awk -F' ' '{print $2}')

    echo "Applying label $NODE to node $NODE_ID..."

    $LINODE_CLI_CMD linodes update --label "$NODE" "$NODE_ID" > /dev/null 2>&1

    echo "Applying label $VOLUME to volume $VOLUME_ID..."

    $LINODE_CLI_CMD volumes update --label "$VOLUME" "$VOLUME_ID" > /dev/null 2>&1

    echo "Applying tags $TAGS, $LABEL, $NAMESPACE to node $NODE_ID and volume $VOLUME_ID..."

    for TAG in $TAGS
    do
      $LINODE_CLI_CMD linodes update --tags "$TAG" --tags "$LABEL" --tags "$NAMESPACE" "$NODE_ID" > /dev/null 2>&1
      $LINODE_CLI_CMD volumes update --tags "$TAG" --tags "$LABEL" --tags "$NAMESPACE" "$VOLUME_ID" > /dev/null 2>&1
    done
  done

  NODE_BALANCERS=$($KUBECTL_CMD get svc -n "$NAMESPACE" | grep LoadBalancer | awk -F' ' '{print $4}')

  for NODE_BALANCER in $NODE_BALANCERS
  do
    LABEL=$($KUBECTL_CMD get svc -n "$NAMESPACE" | grep "$NODE_BALANCER" | awk -F' ' '{print $1}')
    NODE_BALANCER_ID=$($LINODE_CLI_CMD nodebalancers list --text | grep "$NODE_BALANCER" | awk -F' ' '{print $1}')

    echo "Applying tags $TAGS, $LABEL, $NAMESPACE to node balancer $NODE_BALANCER_ID..."

    for TAG in $TAGS
    do
      $LINODE_CLI_CMD nodebalancers update --tags "$TAG" --tags "$LABEL" --tags "$NAMESPACE" "$NODE_BALANCER_ID" > /dev/null 2>&1
    done
  done
}

# Main function.
function main() {
  checkDependencies
  applyStackLabelsAndTags
}

main