# Required variables.
locals {
  nodesToBeProtected         = concat([ for node in linode_lke_cluster.default.pool[0].nodes : node.instance_id ], [ linode_instance.pgadmin.id, linode_instance.grafana.id ])
  nodeBalancersToBeProtected = [ for nodeBalancer in data.linode_nodebalancers.clusterNodeBalancers.nodebalancers : nodeBalancer.id ]
  allowedPublicIps           = concat([ for node in data.linode_instances.clusterNodes.instances : "${node.ip_address}/32" ], [ "${jsondecode(data.http.myIp.response_body).ip}/32" ])
  allowedPrivateIps          = [ for node in data.linode_instances.clusterNodes.instances : "${node.private_ip_address}/32" ]
  allowedIpv4                = concat(var.settings.cluster.allowedIps.ipv4, concat(local.allowedPublicIps, local.allowedPrivateIps))
}

# Fetches the local IP.
data "http" "myIp" {
  url = "https://ipinfo.io"
}

# Fetches the cluster nodes.
data "linode_instances" "clusterNodes" {
  filter {
    name   = "id"
    values = local.nodesToBeProtected
  }

  depends_on = [
    linode_lke_cluster.default,
    linode_instance.pgadmin,
    linode_instance.grafana
  ]
}

# Fetches the cluster node balancers.
data "linode_nodebalancers" "clusterNodeBalancers" {
  filter {
    name   = "tags"
    values = [
      local.primaryServiceIdentifier,
      local.replicasServiceIdentifier,
      local.monitoringServiceIdentifier
    ]
  }

  depends_on = [
    linode_lke_cluster.default,
    null_resource.applyStackLabelsAndTags
  ]
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
    label    = "allowed-cluster-nodeports-udp"
    protocol = "IPENCAP"
    ipv4     = [ "192.168.128.0/17" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-kubelet-health-checks"
    protocol = "TCP"
    ports    = "10250, 10256"
    ipv4     = [ "192.168.128.0/17" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-lke-wireguard"
    protocol = "UDP"
    ports    = "51820"
    ipv4     = [ "192.168.128.0/17" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-cluster-dns-tcp"
    protocol = "TCP"
    ports    = "53"
    ipv4     = [ "192.168.128.0/17" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-cluster-dns-udp"
    protocol = "UDP"
    ports    = "53"
    ipv4     = [ "192.168.128.0/17" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-nodebalancers-tcp"
    protocol = "TCP"
    ports    = "30000-32767"
    ipv4     = [ "192.168.255.0/24" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-nodebalancers-udp"
    protocol = "UDP"
    ports    = "30000-32767"
    ipv4     = [ "192.168.255.0/24" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-ips"
    protocol = "TCP"
    ports    = "22,80,443,5432,9090"
    ipv4     = local.allowedIpv4
    ipv6     = var.settings.cluster.allowedIps.ipv6
  }

  nodebalancers = local.nodeBalancersToBeProtected
  linodes       = local.nodesToBeProtected

  depends_on = [
    data.http.myIp,
    data.linode_instances.clusterNodes,
    data.linode_nodebalancers.clusterNodeBalancers
  ]
}