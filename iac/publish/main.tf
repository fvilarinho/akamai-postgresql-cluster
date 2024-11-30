terraform {

  # Required providers definition.
  required_providers {
    linode = {
      source = "linode/linode"
    }

    null = {
      source = "hashicorp/null"
    }
  }
}

# Akamai Cloud Computing provider definition.
provider "linode" {
  token = var.settings.general.token
}