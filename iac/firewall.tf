# Fetches the local IP.
data "http" "myIp" {
  url = "https://ipinfo.io"
}

# Fetches the stack node balancers.
data "linode_nodebalancers" "default" {
  filter {
    name   = "hostname"
    values = [
      data.external.fetchStackHostnames.result.primary,
      data.external.fetchStackHostnames.result.replicas
    ]
  }

  depends_on = [ data.external.fetchStackHostnames ]
}

# Definition of the firewall rules.
resource "linode_firewall" "default" {
  label           = "${var.settings.cluster.identifier}-firewall"
  tags            = concat(var.settings.cluster.tags, [ var.settings.cluster.namespace ])
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  inbound {
    action   = "ACCEPT"
    label    = "allow-icmp"
    protocol = "ICMP"
    ipv4     = [ "0.0.0.0/0" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-ips"
    protocol = "TCP"
    ipv4     = concat(var.settings.cluster.allowedIps.ipv4, [ "${jsondecode(data.http.myIp.response_body).ip}/32", "${linode_instance.pgadmin.ip_address}/32" ])
    ipv6     = var.settings.cluster.allowedIps.ipv6
  }

  nodebalancers = [ for nodeBalancer in data.linode_nodebalancers.default.nodebalancers : nodeBalancer.id ]
  linodes       = [ linode_instance.pgadmin.id ]

  depends_on = [
    null_resource.applyStackServices,
    data.http.myIp,
    data.linode_nodebalancers.default,
    linode_instance.pgadmin
  ]
}