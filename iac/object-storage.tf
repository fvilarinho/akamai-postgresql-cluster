locals {
  backupCredentialsFilename = abspath(pathexpand("../etc/.backupCredentials"))
}

# Definition of the object storage bucket for backup.
resource "linode_object_storage_bucket" "backup" {
  label  = "${var.settings.cluster.namespace}-${var.settings.cluster.identifier}-backup"
  region = var.settings.cluster.database.backup.region
}

# Definition of the object storage bucket credentials.
resource "linode_object_storage_key" "backup" {
  label = "${var.settings.cluster.namespace}-${var.settings.cluster.identifier}-backup"

  bucket_access {
    bucket_name = "${var.settings.cluster.namespace}-${var.settings.cluster.identifier}-backup"
    region      = var.settings.cluster.database.backup.region
    permissions = "read_write"
  }

  depends_on = [ linode_object_storage_bucket.backup ]
}

# Creates the backup credentials file.
resource "local_sensitive_file" "backupCredentials" {
  filename = local.backupCredentialsFilename
  content = <<EOT
[default]
aws_access_key_id=${linode_object_storage_key.backup.access_key}
aws_secret_access_key=${linode_object_storage_key.backup.secret_key}
EOT
  depends_on = [ linode_object_storage_key.backup ]
}