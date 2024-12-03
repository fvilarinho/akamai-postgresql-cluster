# Required variables.
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
      "apt update",
      "apt -y upgrade",
      "hostnamectl set-hostname ${var.settings.pgadmin.identifier}",
      "apt -y install curl wget unzip zip dnsutils net-tools htop postgresql-client",
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
    destination = "/root/.env"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.pgadminDockerComposeFilename
    destination = "/root/docker-compose.yaml"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.pgadminNginxConfFilename
    destination = "/root/default.conf"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.certificateFilename
    destination = "/root/fullchain.pem"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.certificateKeyFilename
    destination = "/root/privkey.pem"
  }

  depends_on = [
    null_resource.pgadminSetup,
    local_sensitive_file.certificate,
    local_sensitive_file.certificateKey,
    local_sensitive_file.pgadminEnvironment
  ]
}

# Starts the PostgreSQL admin.
resource "null_resource" "startPgAdmin" {
  provisioner "remote-exec" {
    connection {
      host = linode_instance.pgadmin.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    inline = [
      "cd /root; source /root/.env",
      "docker compose up -d"
    ]
  }

  depends_on = [ null_resource.pgadminFiles ]
}