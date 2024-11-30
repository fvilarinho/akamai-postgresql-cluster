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

output "clusterNodes" {
  value = [ for node in linode_lke_cluster.default.pool[0].nodes : node.instance_id ]
}

output "grafanaNode" {
  value = linode_instance.grafana
}

output "pgadminNode" {
  value = linode_instance.pgadmin
}