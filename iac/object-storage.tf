# Definition of the object storage bucket for the clusters' backup.
resource "linode_object_storage_bucket" "backup" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  label  = "${each.key}-${each.value.namespace}-backup"
  region = each.value.region
}

# Definition of the object storage bucket credentials for the clusters' backup.
resource "linode_object_storage_key" "backup" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  label = "${each.key}-${each.value.namespace}-backup"

  bucket_access {
    bucket_name = "${each.key}-${each.value.namespace}-backup"
    region      = each.value.region
    permissions = "read_write"
  }

  depends_on = [ linode_object_storage_bucket.backup ]
}