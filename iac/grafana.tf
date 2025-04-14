# Required environment variables.
locals {
  grafanaNginxConfFilename     = abspath(pathexpand("../etc/grafana/nginx/conf.d/default.conf"))
  grafanaDockerComposeFilename = abspath(pathexpand("../etc/grafana/docker-compose.yaml"))
  grafanaEnvironmentFilename   = abspath(pathexpand("../etc/grafana/.env"))
}

# Definition of the Grafana environment variables.
resource "local_sensitive_file" "grafanaEnvironment" {
  filename = local.grafanaEnvironmentFilename
  content = <<EOT
export GRAFANA_USER=${var.settings.grafana.user}
export GRAFANA_PASSWORD=${var.settings.grafana.password}
EOT
}

# Definition of the Grafana instance.
resource "linode_instance" "grafana" {
  label           = var.settings.grafana.identifier
  tags            = concat(var.settings.general.tags, var.settings.grafana.tags)
  region          = var.settings.grafana.region
  type            = var.settings.grafana.type
  image           = "linode/debian12"
  private_ip      = true
  root_pass       = var.settings.grafana.password
  authorized_keys = [ chomp(file(local.sshPublicKeyFilename)) ]
  depends_on      = [ null_resource.applyDeployments ]
}

# Installs all required software for Grafana.
resource "null_resource" "grafanaSetup" {
  provisioner "remote-exec" {
    connection {
      host        = linode_instance.grafana.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update",
      "apt -y upgrade",
      "hostnamectl set-hostname ${var.settings.grafana.identifier}",
      "apt -y install curl wget unzip zip dnsutils net-tools htop postgresql-client",
      "curl https://get.docker.com | sh -",
      "systemctl enable docker",
      "systemctl start docker"
    ]
  }

  depends_on = [ linode_instance.grafana ]
}

# Upload all required files for Grafana.
resource "null_resource" "grafanaFiles" {
  provisioner "file" {
    connection {
      host        = linode_instance.grafana.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.grafanaEnvironmentFilename
    destination = "/root/.env"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.grafana.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.grafanaDockerComposeFilename
    destination = "/root/docker-compose.yaml"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.grafana.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.grafanaNginxConfFilename
    destination = "/root/default.conf"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.grafana.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.certificateFilename
    destination = "/root/fullchain.pem"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.grafana.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.certificateKeyFilename
    destination = "/root/privkey.pem"
  }

  depends_on = [
    null_resource.grafanaSetup,
    local_sensitive_file.grafanaEnvironment,
    null_resource.certificateIssuance
  ]
}

# Starts the Grafana.
resource "null_resource" "startGrafana" {
  provisioner "remote-exec" {
    connection {
      host = linode_instance.grafana.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    inline = [ "docker compose up -d" ]
  }

  depends_on = [ null_resource.grafanaFiles ]
}