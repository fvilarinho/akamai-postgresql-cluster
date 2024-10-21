# Required variables.
locals {
  applyStackOperatorScriptFilename      = abspath(pathexpand("../bin/applyStackOperator.sh"))
  applyStackManifestScriptFilename      = abspath(pathexpand("../bin/applyStackManifest.sh"))
  applyStackLabelsAndTagsScriptFilename = abspath(pathexpand("../bin/applyStackLabelsAndTags.sh"))
  stackManifestFilename                 = abspath(pathexpand("../etc/manifest.yaml"))
}

# Applies the stack operator responsible for the stack provisioning.
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

# Applies the stack manifest and waits until it is ready.
resource "null_resource" "applyStackManifest" {
  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG                 = local.kubeconfigFilename
      MANIFEST_FILENAME          = local.stackManifestFilename
      NAMESPACE                  = var.settings.cluster.namespace
      IDENTIFIER                 = var.settings.cluster.identifier
      DATABASE_VERSION           = var.settings.cluster.database.version
      DATABASE_NAME              = var.settings.cluster.database.name
      DATABASE_OWNER             = var.settings.cluster.database.user
      DATABASE_USER              = base64encode(var.settings.cluster.database.user)
      DATABASE_PASSWORD          = base64encode(var.settings.cluster.database.password)
      DATABASE_BACKUP_URL        = "https://${linode_object_storage_bucket.backup.hostname}"
      DATABASE_BACKUP_ACCESS_KEY = base64encode(linode_object_storage_key.backup.access_key)
      DATABASE_BACKUP_SECRET_KEY = base64encode(linode_object_storage_key.backup.secret_key)
      DATABASE_BACKUP_SCHEDULE   = var.settings.cluster.database.backup.schedule
      NODES_COUNT                = var.settings.cluster.nodes.count
      STORAGE_SIZE               = var.settings.cluster.storage.size
    }

    quiet   = true
    command = local.applyStackManifestScriptFilename
  }

  depends_on = [
    null_resource.applyStackOperator,
    linode_object_storage_bucket.backup,
    linode_object_storage_key.backup
  ]
}

# Applies the stack labels and tags.
resource "null_resource" "applyStackLabelsAndTags" {
  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local.kubeconfigFilename
      NAMESPACE  = var.settings.cluster.namespace
      TAGS       = join(" ", var.settings.cluster.tags)
    }

    quiet   = true
    command = local.applyStackLabelsAndTagsScriptFilename
  }

  depends_on = [ null_resource.applyStackManifest ]
}