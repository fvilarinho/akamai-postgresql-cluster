# Required local variables.
locals {
  applyTagsScriptFilename = abspath(pathexpand("../bin/applyTags.sh"))
}

# Applies the tags in cluster nodes and node balancers.
resource "null_resource" "applyTags" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  # Execute when detected changes.
  triggers = {
    hash                   = filemd5(local.applyTagsScriptFilename)
    namespace              = each.value.namespace
    clusterNode            = join(" ", [ for node in data.linode_instances.clusterNodes[each.key].instances : node.id ])
    primaryNodeBalancer    = data.external.fetchNodeBalancers[each.key].result.primaryId
    replicasNodeBalancer   = data.external.fetchNodeBalancers[each.key].result.replicasId
    monitoringNodeBalancer = data.external.fetchNodeBalancers[each.key].result.monitoringId
    tags                   = join(" ", concat(var.settings.general.tags,  each.value.tags))
  }

  provisioner "local-exec" {
    # Required environment variables.
    environment = {
      KUBECONFIG               = local_sensitive_file.kubeconfig[each.key].filename
      NAMESPACE                = each.value.namespace
      CLUSTER_NODES            = join(" ", [ for node in data.linode_instances.clusterNodes[each.key].instances : node.id ])
      PRIMARY_NODE_BALANCER    = data.external.fetchNodeBalancers[each.key].result.primaryId
      REPLICAS_NODE_BALANCER   = data.external.fetchNodeBalancers[each.key].result.replicasId
      MONITORING_NODE_BALANCER = data.external.fetchNodeBalancers[each.key].result.monitoringId
      TAGS                     = join(" ", concat(var.settings.general.tags, each.value.tags))
    }

    quiet   = true
    command = local.applyTagsScriptFilename
  }

  depends_on = [
    linode_lke_cluster.default,
    null_resource.applyConfigMaps,
    null_resource.applySecrets,
    null_resource.applyServices,
    null_resource.applyDeployments,
    data.external.fetchNodeBalancers
  ]
}