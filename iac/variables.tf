variable "settings" {
  default = {
    general = {
      email  = "<your-email>"
      domain = "<your-domain>"
      token  = "<token>"
    }

    console = {
      namespace  = "akamai-dbaas"
      identifier = "postgresql-console"
      tags       = [ "demo" ]
      type       = "g6-standard-2"
      region     = "<region>"
    }

    cluster = {
      namespace  = "akamai-dbaas"
      identifier = "postgresql"
      tags       = [ "demo" ]

      database = {
        version  = 17.0
        port     = 5432
        name     = "defaultdb"
        user     = "<user>"
        password = "<password>"

        backup = {
          region    = "<region>"
          schedule  = "0 0 0 * * *"
          retention = 30
        }
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