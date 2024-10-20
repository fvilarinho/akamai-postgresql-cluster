variable "settings" {
  default = {
    general = {
      email  = "<your-email>"
      domain = "<your-domain>"
    }

    cluster = {
      namespace  = "akamai-postgresql"
      identifier = "postgresql"
      tags       = [ "database" ]

      database = {
        version  = 17.0
        name     = "defaultdb"
        user     = "<user>"
        password = "<password>"
      }

      nodes = {
        type   = "g6-standard-4"
        region = "<region>"
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