variable "settings" {
  default = {
    general = {
      email               = "<your-email>"
      domain              = "<your-domain>"
      credentialsFilename = "<your-credentials-filename>"
    }

    cluster = {
      namespace = "akamai-postgresql"
      label     = "postgresql"
      version   = 17.0
      tags      = [ "database" ]

      nodes = {
        type   = "g6-standard-4"
        region = "br-gru"
        count  = 3
      }

      storage = {
        size = 10
      }

      allowedIps = {
        ipv4 = [ "0.0.0.0/0" ]
        ipv6 = []
      }
    }
  }
}