# Required local variables.
locals {
  applyOperatorScriptFilename    = abspath(pathexpand("../bin/applyOperator.sh"))
  applyNamespacesScriptFilename  = abspath(pathexpand("../bin/applyNamespaces.sh"))
  applyConfigMapsScriptFilename  = abspath(pathexpand("../bin/applyConfigMaps.sh"))
  applySecretsScriptFilename     = abspath(pathexpand("../bin/applySecrets.sh"))
  applyServicesScriptFilename    = abspath(pathexpand("../bin/applyServices.sh"))
  applyDeploymentsScriptFilename = abspath(pathexpand("../bin/applyDeployments.sh"))

  configMapsManifestFilename     = abspath(pathexpand("../etc/configMaps.yaml"))
  secretsManifestFilename        = abspath(pathexpand("../etc/secrets.yaml"))
  servicesManifestFilename       = abspath(pathexpand("../etc/services.yaml"))
  deploymentsManifestFilename    = abspath(pathexpand("../etc/deployments.yaml"))
}

# Applies the operator responsible for the provisioning of PostgreSQL.
resource "null_resource" "applyOperator" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  # Execute when detected changes.
  triggers = {
    hash = filemd5(local.applyOperatorScriptFilename)
  }

  provisioner "local-exec" {
    # Required environment variables.
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig[each.key].filename
    }

    quiet   = true
    command = local.applyOperatorScriptFilename
  }

  depends_on = [ local_sensitive_file.kubeconfig ]
}

# Applies the clusters' namespaces.
resource "null_resource" "applyNamespaces" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  # Execute when detected changes.
  triggers = {
    hash      = filemd5(local.applyNamespacesScriptFilename)
    namespace = each.value.namespace
  }

  provisioner "local-exec" {
    # Required environment variables.
    environment = {
      KUBECONFIG = local_sensitive_file.kubeconfig[each.key].filename
      NAMESPACE  = each.value.namespace
    }

    quiet   = true
    command = local.applyNamespacesScriptFilename
  }

  depends_on = [ null_resource.applyOperator ]
}

# Applies the clusters' secrets.
resource "null_resource" "applySecrets" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  # Execute when detected changes.
  triggers = {
    hash                    = "${filemd5(local.applySecretsScriptFilename)}|${filemd5(local.secretsManifestFilename)}"
    identifier              = each.key
    namespace               = each.value.namespace
    databaseUser            = base64encode(each.value.database.user)
    databasePassword        = base64encode(each.value.database.password)
    databaseBackupAccessKey = base64encode(linode_object_storage_key.backup[each.key].access_key)
    databaseBackupSecretKey = base64encode(linode_object_storage_key.backup[each.key].secret_key)
    databaseMonitoringUrl   = base64encode("postgresql://${each.value.database.user}:${each.value.database.password}@primary:5432/${each.value.database.name}?sslmode=disable")
  }

  provisioner "local-exec" {
    # Required environment variables.
    environment = {
      KUBECONFIG                 = local_sensitive_file.kubeconfig[each.key].filename
      MANIFEST_FILENAME          = local.secretsManifestFilename
      IDENTIFIER                 = each.key
      NAMESPACE                  = each.value.namespace
      DATABASE_USER              = base64encode(each.value.database.user)
      DATABASE_PASSWORD          = base64encode(each.value.database.password)
      DATABASE_BACKUP_ACCESS_KEY = base64encode(linode_object_storage_key.backup[each.key].access_key)
      DATABASE_BACKUP_SECRET_KEY = base64encode(linode_object_storage_key.backup[each.key].secret_key)
      DATABASE_MONITORING_URL    = base64encode("postgresql://${each.value.database.user}:${each.value.database.password}@primary:5432/${each.value.database.name}?sslmode=disable")
    }

    quiet   = true
    command = local.applySecretsScriptFilename
  }

  depends_on = [
    null_resource.applyNamespaces,
    linode_object_storage_key.backup
  ]
}

# Applies the clusters' config maps.
resource "null_resource" "applyConfigMaps" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  # Execute when detected changes.
  triggers = {
    hash       = "${filemd5(local.applyConfigMapsScriptFilename)}|${filemd5(local.configMapsManifestFilename)}"
    identifier = each.key
    namespace  = each.value.namespace
  }

  provisioner "local-exec" {
    # Required environment variables.
    environment = {
      KUBECONFIG        = local_sensitive_file.kubeconfig[each.key].filename
      MANIFEST_FILENAME = local.configMapsManifestFilename
      IDENTIFIER        = each.key
      NAMESPACE         = each.value.namespace
    }

    quiet   = true
    command = local.applyConfigMapsScriptFilename
  }

  depends_on = [
    null_resource.applyNamespaces,
    linode_object_storage_key.backup
  ]
}

# Applies the clusters' services.
resource "null_resource" "applyServices" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  # Execute when detected changes.
  triggers = {
    hash       = "${filemd5(local.applyServicesScriptFilename)}|${filemd5(local.servicesManifestFilename)}"
    identifier = each.key
    namespace  = each.value.namespace
  }

  provisioner "local-exec" {
    # Required environment variables.
    environment = {
      KUBECONFIG        = local_sensitive_file.kubeconfig[each.key].filename
      MANIFEST_FILENAME = local.servicesManifestFilename
      IDENTIFIER        = each.key
      NAMESPACE         = each.value.namespace
    }

    quiet   = true
    command = local.applyServicesScriptFilename
  }

  depends_on = [ null_resource.applyNamespaces ]
}

# Applies the clusters' deployments.
resource "null_resource" "applyDeployments" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  # Execute when detected changes.
  triggers = {
    hash                    = "${filemd5(local.applyDeploymentsScriptFilename)}|${filemd5(local.deploymentsManifestFilename)}"
    identifier              = each.key
    namespace               = each.value.namespace
    databaseVersion         = each.value.database.version
    databaseName            = each.value.database.name
    databaseOwner           = each.value.database.user
    databaseBackupUrl       = "https://${linode_object_storage_bucket.backup[each.key].hostname}"
    databaseBackupRetention = each.value.database.backup.retention
    databaseBackupSchedule  = each.value.database.backup.schedule
    nodesCount              = each.value.nodes.count
    storageSize             = each.value.database.storage.size
  }

  provisioner "local-exec" {
    # Required environment variables.
    environment = {
      KUBECONFIG                 = local_sensitive_file.kubeconfig[each.key].filename
      MANIFEST_FILENAME          = local.deploymentsManifestFilename
      IDENTIFIER                 = each.key
      NAMESPACE                  = each.value.namespace
      DATABASE_VERSION           = each.value.database.version
      DATABASE_NAME              = each.value.database.name
      DATABASE_OWNER             = each.value.database.user
      DATABASE_BACKUP_URL        = "https://${linode_object_storage_bucket.backup[each.key].hostname}"
      DATABASE_BACKUP_RETENTION  = each.value.database.backup.retention
      DATABASE_BACKUP_SCHEDULE   = each.value.database.backup.schedule
      NODES_COUNT                = each.value.nodes.count
      STORAGE_SIZE               = each.value.database.storage.size
    }

    quiet   = true
    command = local.applyDeploymentsScriptFilename
  }

  depends_on = [
    null_resource.applyConfigMaps,
    null_resource.applySecrets,
    null_resource.applyServices,
    linode_object_storage_bucket.backup
  ]
}