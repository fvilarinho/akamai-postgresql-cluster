# Definition of the LKE cluster to deploy the stack.
resource "linode_lke_cluster" "default" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  k8s_version = "1.31"
  label       = "${each.key}-${each.value.namespace}"
  tags        = concat(var.settings.general.tags, [ each.value.namespace], [ each.key ])
  region      = each.value.region

  control_plane {
    high_availability = true
  }

  # Pool of nodes for PostgreSQL.
  pool {
    labels = {
      namespace = each.value.namespace
    }

    type  = each.value.nodes.type
    count = each.value.nodes.count
  }
}

# Saves the K8S cluster configuration file used to connect into it.
resource "local_sensitive_file" "kubeconfig" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  filename        = abspath(pathexpand("../etc/${each.key}-${each.value.namespace}.kubeconfig"))
  content_base64  = linode_lke_cluster.default[each.key].kubeconfig
  file_permission = "600"
  depends_on      = [ linode_lke_cluster.default ]
}