variable "settings" {
  default = {
    # General attributes for the provisioning.
    general = {
      email  = "<your-email>"
      domain = "<your-domain>"
      token  = "<token>"
    }

    # Definition of the PostgreSQL console instance.
    console = {
      namespace  = "akamai-dbaas"
      identifier = "postgresql-console"
      tags       = [ "demo" ]
      type       = "g6-standard-2"
      region     = "<region>"
      user       = "<user>"
      password   = "<password>"
    }

    # Definition of the PostgreSQL cluster.
    cluster = {
      namespace  = "akamai-dbaas"
      identifier = "postgresql"
      tags       = [ "demo" ]

      # Database attributes.
      database = {
        version  = 17.0
        port     = 5432
        name     = "defaultdb"
        user     = "<user>"
        password = "<password>"

        # Backup attributes.
        backup = {
          region    = "<region>"
          schedule  = "0 0 0 * * *"
          retention = 30
        }
      }

      # Node Pool attributes.
      nodes = {
        type   = "g6-standard-4"
        region = "<region>"
        count  = 3
      }

      # Storage attributes.
      storage = {
        size = 10
      }

      # Firewall attributes.
      allowedIps = {
        ipv4 = [ "0.0.0.0/0" ]
        ipv6 = []
      }
    }
  }
}