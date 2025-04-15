# Required environment variables.
locals {
  pgadminNginxConfFilename     = abspath(pathexpand("../etc/pgadmin/nginx/conf.d/default.conf"))
  pgadminDockerComposeFilename = abspath(pathexpand("../etc/pgadmin/docker-compose.yaml"))
  pgadminEnvironmentFilename   = abspath(pathexpand("../etc/pgadmin/.env"))
}

# Definition of the PostgreSQL admin environment variables.
resource "local_sensitive_file" "pgadminEnvironment" {
  filename = local.pgadminEnvironmentFilename
  content = <<EOT
export PGADMIN_USER=${var.settings.pgadmin.user}
export PGADMIN_PASSWORD=${var.settings.pgadmin.password}
EOT
}

# Definition of the PostgreSQL admin instance.
resource "linode_instance" "pgadmin" {
  label           = var.settings.pgadmin.identifier
  tags            = concat(var.settings.general.tags, var.settings.pgadmin.tags)
  region          = var.settings.pgadmin.region
  type            = var.settings.pgadmin.type
  image           = "linode/debian12"
  private_ip      = true
  root_pass       = var.settings.pgadmin.password
  authorized_keys = [ chomp(file(local.sshPublicKeyFilename)) ]
  depends_on      = [ null_resource.applyDeployments ]
}

# Installs all required software for PostgreSQL admin.
resource "null_resource" "pgadminSetup" {
  provisioner "remote-exec" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update",
      "apt -y upgrade",
      "hostnamectl set-hostname ${var.settings.pgadmin.identifier}",
      "apt -y install curl wget unzip zip dnsutils net-tools htop postgresql-client awscli",
      "mkdir -p /root/.aws",
      "curl https://get.docker.com | sh -",
      "systemctl enable docker",
      "systemctl start docker"
    ]
  }

  depends_on = [ linode_instance.pgadmin ]
}

# Upload all required files for PostgreSQL admin.
resource "null_resource" "pgadminFiles" {
  provisioner "file" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.pgadminEnvironmentFilename
    destination = "/root/${basename(local.pgadminEnvironmentFilename)}"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.pgadminDockerComposeFilename
    destination = "/root/${basename(local.pgadminDockerComposeFilename)}"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.pgadminNginxConfFilename
    destination = "/root/${basename(local.pgadminNginxConfFilename)}"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.certificateFilename
    destination = "/root/${basename(local.certificateFilename)}"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.certificateKeyFilename
    destination = "/root/${basename(local.certificateKeyFilename)}"
  }

  depends_on = [
    null_resource.pgadminSetup,
    local_sensitive_file.pgadminEnvironment,
    null_resource.certificateIssuance
  ]
}

resource "null_resource" "pgadminBackupCredentials" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  provisioner "file" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local_sensitive_file.backupCredentials[each.key].filename
    destination = "/root/${basename(local_sensitive_file.backupCredentials[each.key].filename)}"
  }

  depends_on = [
    local_sensitive_file.backupCredentials,
    null_resource.pgadminFiles
  ]
}

# Starts the PostgreSQL admin.
resource "null_resource" "startPgAdmin" {
  provisioner "remote-exec" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    inline = [ "docker compose up -d" ]
  }

  depends_on = [ null_resource.pgadminBackupCredentials ]
}