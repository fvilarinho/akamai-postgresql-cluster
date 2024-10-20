# Definition of the object storage bucket for backup.
resource "linode_object_storage_bucket" "backup" {
  label  = "${var.settings.cluster.identifier}-backup"
  region = var.settings.cluster.database.backup.region
}

# Definition of the object storage bucket credentials.
resource "linode_object_storage_key" "backup" {
  label = "${var.settings.cluster.identifier}-backup"

  bucket_access {
    bucket_name = "${var.settings.cluster.identifier}-backup"
    region      = var.settings.cluster.database.backup.region
    permissions = "read_write"
  }

  depends_on = [ linode_object_storage_bucket.backup ]
}