# Required variables.
locals {
  applyStackOperatorScriptFilename = abspath(pathexpand("../bin/applyStackOperator.sh"))
  applyStackManifestScriptFilename = abspath(pathexpand("../bin/applyStackManifest.sh"))
  stackManifestFilename            = abspath(pathexpand("../etc/manifest.yaml"))
}

# Applies the stack operator.
resource "null_resource" "applyStackOperator" {
  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG = local.kubeconfigFilename
    }

    quiet   = true
    command = local.applyStackOperatorScriptFilename
  }

  depends_on = [ local_sensitive_file.kubeconfig ]
}

# Applies the stack manifest.
resource "null_resource" "applyStackManifest" {
  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG        = local.kubeconfigFilename
      MANIFEST_FILENAME = local.stackManifestFilename
      NAMESPACE         = var.settings.cluster.namespace
      LABEL             = var.settings.cluster.label
      VERSION           = var.settings.cluster.version
      NODES_COUNT       = var.settings.cluster.nodes.count
      STORAGE_SIZE      = var.settings.cluster.storage.size
    }

    quiet   = true
    command = local.applyStackManifestScriptFilename
  }

  depends_on = [ null_resource.applyStackOperator ]
}