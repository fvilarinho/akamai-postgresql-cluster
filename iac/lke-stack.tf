# Required variables.
locals {
  applyStackOperatorScriptFilename = abspath(pathexpand("../bin/applyStackOperator.sh"))
  applyStackManifestScriptFilename = abspath(pathexpand("../bin/applyStackManifest.sh"))
  stackManifestFilename            = abspath(pathexpand("../etc/manifest.yaml"))
}

# Applies the stack operator.
resource "null_resource" "applyStackOperator" {
  # Executes only when a change happened.
  triggers = {
    always_run = filemd5(local.applyStackOperatorScriptFilename)
  }

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
  # Executes only when a change happened.
  triggers = {
    always_run = "${filemd5(local.applyStackManifestScriptFilename)}|${filemd5(local.stackManifestFilename)}"
  }

  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG        = local.kubeconfigFilename
      MANIFEST_FILENAME = local.stackManifestFilename
      NAMESPACE         = var.settings.cluster.namespace
      LABEL             = var.settings.cluster.label
      NODES_COUNT       = var.settings.cluster.nodes.count
      STORAGE_DATA_SIZE = var.settings.cluster.storage.dataSize
    }

    quiet   = true
    command = local.applyStackManifestScriptFilename
  }

  depends_on = [ null_resource.applyStackOperator ]
}