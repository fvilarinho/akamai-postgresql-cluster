# Fetches the local IP.
data "http" "myIp" {
  url = "https://ipinfo.io"
}

# Fetches the nodes to be protected.
data "linode_instances" "clusterNodes" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  filter {
    name   = "id"
    values = [ for node in linode_lke_cluster.default[each.key].pool[0].nodes : node.instance_id ]
  }

  depends_on = [ linode_lke_cluster.default ]
}

# Definition of the firewall rules.
resource "linode_firewall" "default" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  label           = "${each.key}-${each.value.namespace}-firewall"
  tags            = concat(var.settings.general.tags, [ each.key ])
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
    ipv4     = concat(each.value.allowedIps.ipv4,
                      [ "${jsondecode(data.http.myIp.response_body).ip}/32",
                        "${linode_instance.pgadmin.ip_address}/32",
                        "${linode_instance.pgadmin.private_ip_address}/32" ])
    ipv6     = each.value.allowedIps.ipv6
  }

  inbound {
    action   = "ACCEPT"
    label    = "allow-intracluster-traffic"
    protocol = "TCP"
    ipv4     = flatten([ for node in data.linode_instances.clusterNodes[each.key].instances : [ "${node.ip_address}/32", "${node.private_ip_address}/32" ]])
  }

  nodebalancers = [
    data.external.fetchNodeBalancers[each.key].result.primaryId,
    data.external.fetchNodeBalancers[each.key].result.replicasId
  ]

  linodes = concat([ for node in data.linode_instances.clusterNodes[each.key].instances : node.id ],
                   [ linode_instance.pgadmin.id ])

  depends_on = [
    data.http.myIp,
    data.linode_instances.clusterNodes,
    data.external.fetchNodeBalancers,
    linode_lke_cluster.default,
    linode_instance.pgadmin
  ]
}