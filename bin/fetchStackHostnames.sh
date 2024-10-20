#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  export KUBECONFIG="$1"

  if [ -z "$KUBECONFIG" ]; then
    echo "The cluster configuration file is not defined! Please define it first to continue!"

    exit 1
  fi

  export NAMESPACE="$2"

  if [ -z "$NAMESPACE" ]; then
    echo "The cluster namespace is not defined! Please define it first to continue!"

    exit 1
  fi

  export IDENTIFIER="$3"

  if [ -z "$IDENTIFIER" ]; then
    echo "The cluster identifier is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Fetches the stack hostnames.
function fetchStackHostnames() {
  checkDependencies "$1" "$2" "$3"

  PRIMARY_HOSTNAME=
  REPLICAS_HOSTNAME=

  # Waits until LKE cluster load balancer is ready.
  while true; do
    PRIMARY_HOSTNAME=$($KUBECTL_CMD get service "$IDENTIFIER"-ingress-primary \
                                    -n "$NAMESPACE" \
                                    -o json | $JQ_CMD -r '.status.loadBalancer.ingress[].hostname')

    if [ -n "$PRIMARY_HOSTNAME" ]; then
      REPLICAS_HOSTNAME=$($KUBECTL_CMD get service "$IDENTIFIER"-ingress-replicas \
                                       -n "$NAMESPACE" \
                                       -o json | $JQ_CMD -r '.status.loadBalancer.ingress[].hostname')

      if [ -n "$REPLICAS_HOSTNAME" ]; then
        break
      fi
    fi

    sleep 5
  done

  # Returns the fetched hostnames.
  echo "{\"primary\": \"$PRIMARY_HOSTNAME\", \"replicas\": \"$REPLICAS_HOSTNAME\"}"
}

fetchStackHostnames "$1" "$2" "$3"