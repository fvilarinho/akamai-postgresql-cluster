# Required local variables.
locals {
  sshPrivateKeyFilename = abspath(pathexpand("~/.ssh/id_rsa"))
  sshPublicKeyFilename  = abspath(pathexpand("~/.ssh/id_rsa.pub"))
}

resource "local_sensitive_file" "backupCredentials" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  filename = abspath(pathexpand("../etc/pgadmin/${each.key}.backupCredentials"))
  content  = <<EOT
[default]
aws_access_key_id=${linode_object_storage_key.backup[each.key].access_key}
aws_secret_access_key=${linode_object_storage_key.backup[each.key].secret_key}
EOT

  depends_on = [ linode_object_storage_key.backup ]
}