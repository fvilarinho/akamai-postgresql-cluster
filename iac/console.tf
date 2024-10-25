# Required variables.
locals {
  sshPrivateKeyFilename = abspath(pathexpand("~/.ssh/id_rsa"))
  sshPublicKeyFilename  = abspath(pathexpand("~/.ssh/id_rsa.pub"))
}

# Definition of the console instance.
resource "linode_instance" "console" {
  label           = var.settings.console.identifier
  tags            = concat(var.settings.console.tags, [ var.settings.console.namespace ])
  region          = var.settings.console.region
  type            = var.settings.console.type
  image           = "linode/debian11"
  private_ip      = true
  root_pass       = var.settings.console.password
  authorized_keys = [ chomp(file(local.sshPublicKeyFilename)) ]
  depends_on      = [ null_resource.applyStackLabelsAndTags ]
}

# Installs all required software.
resource "null_resource" "consoleSetup" {
  provisioner "remote-exec" {
    connection {
      host        = linode_instance.console.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    inline = [
      "apt update",
      "apt -y upgrade",
      "hostnamectl set-hostname ${var.settings.console.identifier}",
      "apt -y install curl wget unzip zip dnsutils net-tools htop",
      "curl https://get.docker.com | sh -",
      "systemctl enable docker",
      "systemctl start docker",
      "apt -y install postgresql-client",
      "apt -y install python3 python3-pip",
      "pip3 install linode-cli --upgrade",
      "pip3 install boto3",
      "mkdir -p /root/.aws",
      "apt -y install awscli"
    ]
  }

  depends_on = [ linode_instance.console ]
}

# Upload all required files.
resource "null_resource" "consoleFiles" {
  provisioner "file" {
    connection {
      host        = linode_instance.console.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.environmentFilename
    destination = "/root/.env"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.console.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = "../etc/docker-compose.yaml"
    destination = "/root/docker-compose.yaml"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.console.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = "../etc/nginx/conf.d/default.conf"
    destination = "/root/default.conf"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.console.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.certificateFilename
    destination = "/root/fullchain.pem"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.console.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.certificateKeyFilename
    destination = "/root/privkey.pem"
  }

  provisioner "file" {
    connection {
      host        = linode_instance.console.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    source      = local.backupCredentialsFilename
    destination = "/root/.aws/credentials"
  }

  depends_on = [
    null_resource.consoleSetup,
    local_sensitive_file.certificate,
    local_sensitive_file.certificateKey,
    local_sensitive_file.environment
  ]
}

# Starts the console.
resource "null_resource" "startConsole" {
  provisioner "remote-exec" {
    connection {
      host = linode_instance.console.ip_address
      private_key = chomp(file(local.sshPrivateKeyFilename))
    }

    inline = [
      "cd /root; source /root/.env",
      "docker compose up -d"
    ]
  }

  depends_on = [ null_resource.consoleFiles ]
}