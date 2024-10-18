#!/bin/bash

# Shows the labels.
function showLabel() {
  if [[ "$0" == *"undeploy.sh"* ]]; then
    echo "** Undeploy **"
  elif [[ "$0" == *"deploy.sh"* ]]; then
    echo "** Deploy **"
  fi

  echo
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  # Required binaries
  export TERRAFORM_CMD=$(which terraform)
  export KUBECTL_CMD=$(which kubectl)
  export JQ_CMD=$(which jq)
}

# Shows the banner.
function showBanner() {
  # Checks if the banner file exists.
  if [ -f banner.txt ]; then
    cat banner.txt
  fi

  showLabel
}

prepareToExecute