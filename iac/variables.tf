variable "settings" {
  default = {
    # General attributes.
    general = {
      email  = "<your-email>"
      domain = "<your-domain>"
      token  = "<token>"
      tags   = [ "demo", "postgresql" ]
    }

    # Definition of the PostgreSQL admin instance.
    pgadmin = {
      identifier = "pgadmin"
      tags       = [ "admin" ]
      type       = "g6-standard-2"
      region     = "<region>"
      user       = "<user>"
      password   = "<password>"
      allowedIps = {
        ipv4 = [ "0.0.0.0/0" ]
        ipv6 = []
      }
    }

    # Definition of the PostgreSQL cluster.
    clusters = [
      {
        identifier = "customer1"
        namespace  = "postgresql"
        region     = "<region>"

        # Nodes attributes.
        nodes = {
          type  = "g6-standard-4"
          count = 1
        }

        # Firewall attributes.
        allowedIps = {
          ipv4 = [ "0.0.0.0/0" ]
          ipv6 = []
        }

        # Database attributes.
        database = {
          version  = 17.0
          name     = "defaultdb"
          user     = "<user>"
          password = "<password>"

          # Backup attributes.
          backup = {
            region    = "<region>"
            schedule  = "0 0 0 * * *"
            retention = 30
          }

          # Storage attributes.
          storage = {
            size = 10
          }
        }
      }
    ]
  }
}