# Required local variables.
locals {
  certificateIssuanceScript = abspath(pathexpand("../bin/tls/certificateIssuance.sh"))
  certificateFilename       = abspath(pathexpand("../etc/tls/certs/fullchain.pem"))
  certificateKeyFilename    = abspath(pathexpand("../etc/tls/private/privkey.pem"))
}

# Issues the certificate using Certbot.
resource "null_resource" "certificateIssuance" {
  provisioner "local-exec" {
    # Required environment variables.
    environment = {
      CERTIFICATE_ISSUANCE_PROPAGATION_DELAY = 600 // in seconds.
      DOMAIN                                 = var.settings.general.domain
      EMAIL                                  = var.settings.general.email
      TOKEN                                  = var.settings.general.token
    }

    quiet   = true
    command = local.certificateIssuanceScript
  }
}