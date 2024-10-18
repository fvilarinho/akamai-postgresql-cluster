variable "settings" {
  default = {
    general = {
      domain              = "<your-domain>"
      credentialsFilename = "<your-credentials-filename>"
    }

    cluster = {
      namespace = "akamai-postgresql"
      label     = "postgresql"
      tags      = [ "database" ]

      nodes = {
        type   = "g6-standard-4"
        region = "br-gru"
        count  = 3
      }

      storage = {
        dataSize = 10
      }

      allowedIps = {
        ipv4 = [ "0.0.0.0/0" ]
        ipv6 = []
      }
    }
  }
}