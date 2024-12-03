#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  export KUBECONFIG=$1

  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig is not defined! Please define it first to continue!"

    exit 1
  fi

  export NAMESPACE=$2

  if [ -z "$NAMESPACE" ]; then
    echo "The namespace is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Fetches the node balancers.
function fetchNodeBalancers() {
  PRIMARY_ID=
  PRIMARY_HOSTNAME=
  REPLICAS_ID=
  REPLICAS_HOSTNAME=

  # Waits until all node balancers is ready.
  while true; do
    # Fetches the primary node balancer.
    PRIMARY_HOSTNAME=$($KUBECTL_CMD get service primary \
                                    -n "$NAMESPACE" \
                                    -o jsonpath='{.status.loadBalancer.ingress[].hostname}')

    if [ -n "$PRIMARY_HOSTNAME" ]; then
      PRIMARY_ID=$($LINODE_CLI_CMD nodebalancers list --json | $JQ_CMD ".[]|select(.hostname == \"$PRIMARY_HOSTNAME\")|.id")

      if [ -n "$PRIMARY_ID" ]; then
        REPLICAS_HOSTNAME=$($KUBECTL_CMD get service replicas \
                                         -n "$NAMESPACE" \
                                         -o jsonpath='{.status.loadBalancer.ingress[].hostname}')

        if [ -n "$REPLICAS_HOSTNAME" ]; then
          REPLICAS_ID=$($LINODE_CLI_CMD nodebalancers list --json | $JQ_CMD ".[]|select(.hostname == \"$REPLICAS_HOSTNAME\")|.id")

          if [ -n "$REPLICAS_ID" ]; then
            break
          fi
        fi
      fi
    fi

    sleep 1
  done

  # Returns the fetched hostnames.
  echo "{\"primaryId\": \"$PRIMARY_ID\", \"primaryHostname\": \"$PRIMARY_HOSTNAME\", \"replicasId\": \"$REPLICAS_ID\", \"replicasHostname\": \"$REPLICAS_HOSTNAME\"}"
}

# Main function.
function main() {
  checkDependencies "$1" "$2"
  fetchNodeBalancers
}

main "$1" "$2"