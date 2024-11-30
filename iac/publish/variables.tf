variable "clusterNodes" {}

variable "grafanaNode" {}

variable "pgadminNode" {}

variable "settings" {
  default = {
    # General attributes for the provisioning.
    general = {
      email  = "<your-email>"
      domain = "<your-domain>"
      token  = "<token>"
      tags   = [ "demo", "postgresql" ]
    }

    grafana = {
      identifier = "grafana"
    }

    pgadmin = {
      identifier = "pgadmin"
    }

    # Definition of the PostgreSQL cluster.
    cluster = {
      identifier = "postgresql"

      # Firewall attributes.
      allowedIps = {
        ipv4 = [ "0.0.0.0/0" ]
        ipv6 = []
      }
    }
  }
}