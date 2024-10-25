# Required variables.
locals {
  applyStackOperatorScriptFilename        = abspath(pathexpand("../bin/applyStackOperator.sh"))
  applyStackNamespaceScriptFilename       = abspath(pathexpand("../bin/applyStackNamespace.sh"))
  applyStackSecretsScriptFilename         = abspath(pathexpand("../bin/applyStackSecrets.sh"))
  applyStackServicesScriptFilename        = abspath(pathexpand("../bin/applyStackServices.sh"))
  applyStackDeploymentScriptFilename      = abspath(pathexpand("../bin/applyStackDeployment.sh"))
  applyStackScheduledBackupScriptFilename = abspath(pathexpand("../bin/applyStackScheduledBackup.sh"))
  applyStackLabelsAndTagsScriptFilename   = abspath(pathexpand("../bin/applyStackLabelsAndTags.sh"))

  stackSecretsManifestFilename         = abspath(pathexpand("../etc/secrets.yaml"))
  stackServicesManifestFilename        = abspath(pathexpand("../etc/services.yaml"))
  stackDeploymentManifestFilename      = abspath(pathexpand("../etc/deployment.yaml"))
  stackScheduledBackupManifestFilename = abspath(pathexpand("../etc/scheduledBackup.yaml"))
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

# Applies the stack namespace.
resource "null_resource" "applyStackNamespace" {
  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG = local.kubeconfigFilename
      NAMESPACE  = var.settings.cluster.namespace
    }

    quiet   = true
    command = local.applyStackNamespaceScriptFilename
  }

  depends_on = [ local_sensitive_file.kubeconfig ]
}

# Applies the stack secrets.
resource "null_resource" "applyStackSecrets" {
  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG                 = local.kubeconfigFilename
      MANIFEST_FILENAME          = local.stackSecretsManifestFilename
      NAMESPACE                  = var.settings.cluster.namespace
      IDENTIFIER                 = var.settings.cluster.identifier
      DATABASE_USER              = base64encode(var.settings.cluster.database.user)
      DATABASE_PASSWORD          = base64encode(var.settings.cluster.database.password)
      DATABASE_BACKUP_ACCESS_KEY = base64encode(linode_object_storage_key.backup.access_key)
      DATABASE_BACKUP_SECRET_KEY = base64encode(linode_object_storage_key.backup.secret_key)
    }

    quiet   = true
    command = local.applyStackSecretsScriptFilename
  }

  depends_on = [ local_sensitive_file.kubeconfig ]
}

# Applies the stack services.
resource "null_resource" "applyStackServices" {
  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG        = local.kubeconfigFilename
      MANIFEST_FILENAME = local.stackServicesManifestFilename
      NAMESPACE         = var.settings.cluster.namespace
      IDENTIFIER        = var.settings.cluster.identifier
    }

    quiet   = true
    command = local.applyStackServicesScriptFilename
  }

  depends_on = [ local_sensitive_file.kubeconfig ]
}

# Applies the stack deployment.
resource "null_resource" "applyStackDeployment" {
  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG                = local.kubeconfigFilename
      MANIFEST_FILENAME         = local.stackDeploymentManifestFilename
      NAMESPACE                 = var.settings.cluster.namespace
      IDENTIFIER                = var.settings.cluster.identifier
      DATABASE_VERSION          = var.settings.cluster.database.version
      DATABASE_NAME             = var.settings.cluster.database.name
      DATABASE_OWNER            = var.settings.cluster.database.user
      DATABASE_BACKUP_URL       = "https://${linode_object_storage_bucket.backup.hostname}"
      DATABASE_BACKUP_RETENTION = var.settings.cluster.database.backup.retention
      NODES_COUNT               = var.settings.cluster.nodes.count
      STORAGE_SIZE              = var.settings.cluster.storage.size
    }

    quiet   = true
    command = local.applyStackDeploymentScriptFilename
  }

  depends_on = [
    null_resource.applyStackOperator,
    null_resource.applyStackNamespace,
    null_resource.applyStackSecrets,
    null_resource.applyStackServices
  ]
}

# Applies the stack scheduled backup.
resource "null_resource" "applyStackScheduledBackup" {
  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG               = local.kubeconfigFilename
      MANIFEST_FILENAME        = local.stackScheduledBackupManifestFilename
      NAMESPACE                = var.settings.cluster.namespace
      IDENTIFIER               = var.settings.cluster.identifier
      DATABASE_BACKUP_SCHEDULE = var.settings.cluster.database.backup.schedule
    }

    quiet   = true
    command = local.applyStackScheduledBackupScriptFilename
  }

  depends_on = [ null_resource.applyStackDeployment ]
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

  depends_on = [ null_resource.applyStackDeployment ]
}