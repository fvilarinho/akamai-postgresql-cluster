# Terraform definition.
terraform {
  # Stores the provisioning state in Akamai Cloud Computing Object Storage (Please change to use your own).
  backend "s3" {
    bucket                      = "fvilarin-devops"
    key                         = "akamai-postgresql-cluster.tfstate"
    region                      = "us-east-1"
    endpoint                    = "us-east-1.linodeobjects.com"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }

  # Required providers definition.
  required_providers {
    linode = {
      source = "linode/linode"
    }

    null = {
      source = "hashicorp/null"
    }

    random = {
      source = "hashicorp/random"
    }
  }
}

# Akamai Cloud Computing provider definition.
provider "linode" {
  token = var.settings.general.token
}

# Creates the environment variables file.
locals {
  environmentFilename = abspath(pathexpand("../etc/.env"))
}

resource "local_sensitive_file" "environment" {
  filename = local.environmentFilename
  content = <<EOT
export CONSOLE_USER=${var.settings.console.user}
export CONSOLE_PASSWORD=${var.settings.console.password}
export LINODE_CLI_TOKEN=${var.settings.general.token}
EOT
}
