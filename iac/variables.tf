variable "settings" {
  default = {
    general = {
      email  = "<your-email>"
      domain = "<your-domain>"
    }

    cluster = {
      namespace  = "akamai-dbaas"
      identifier = "postgresql"
      tags       = [ "demo" ]

      database = {
        version  = 17.0
        name     = "defaultdb"
        user     = "<user>"
        password = "<password>"

        backup = {
          region   = "<region>"
          schedule = "0 0 0 * * *"
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
    }
  }
}