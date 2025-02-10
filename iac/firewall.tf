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
resource "linode_firewall" "clusterNodes" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  label           = "${each.key}-${each.value.namespace}-cn-fw"
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
    label    = "allow-akamai-ips"
    protocol = "TCP"
    ports    = "22,443"
    ipv4     = [
      "172.236.119.4/30",
      "172.234.160.4/30",
      "172.236.94.4/30",
      "139.144.212.168/31",
      "172.232.23.164/31"
    ]
    ipv6     = [
      "2600:3c06::f03c:94ff:febe:162f/128",
      "2600:3c06::f03c:94ff:febe:16ff/128",
      "2600:3c06::f03c:94ff:febe:16c5/128",
      "2600:3c07::f03c:94ff:febe:16e6/128",
      "2600:3c07::f03c:94ff:febe:168c/128",
      "2600:3c07::f03c:94ff:febe:16de/128",
      "2600:3c08::f03c:94ff:febe:16e9/128",
      "2600:3c08::f03c:94ff:febe:1655/128",
      "2600:3c08::f03c:94ff:febe:16fd/128"
    ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allow-intracluster-traffic"
    protocol = "TCP"
    ipv4     = flatten([ for node in data.linode_instances.clusterNodes[each.key].instances : [ "${node.ip_address}/32", "${node.private_ip_address}/32" ]])
  }

  linodes = [ for node in data.linode_instances.clusterNodes[each.key].instances : node.id ]

  depends_on = [ data.linode_instances.clusterNodes ]
}

# Definition of the firewall rules.
resource "linode_firewall" "nodeBalancers" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  label           = "${each.key}-${each.value.namespace}-cnb-fw"
  tags            = concat(var.settings.general.tags, [ each.key ])
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  inbound {
    action   = "ACCEPT"
    label    = "allow-external-ips"
    protocol = "TCP"
    ipv6     = concat(each.value.allowedIps.ipv6, [ "::1/128" ])
    ipv4     = concat(each.value.allowedIps.ipv4,
                      [
                        "${linode_instance.pgadmin.ip_address}/32",
                        "${linode_instance.pgadmin.private_ip_address}/32",
                        "${jsondecode(data.http.myIp.response_body).ip}/32",
                      ]
               )
  }

  nodebalancers = [
    data.external.fetchNodeBalancers[each.key].result.primaryId,
    data.external.fetchNodeBalancers[each.key].result.replicasId
  ]

  depends_on = [
    data.http.myIp,
    data.external.fetchNodeBalancers,
    linode_instance.pgadmin
  ]
}

resource "linode_firewall" "pgadmin" {
  label           = "pgadmin-fw"
  tags            = concat(var.settings.general.tags, var.settings.pgadmin.tags)
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
    label    = "allow-akamai-ips"
    protocol = "TCP"
    ports    = "22,443"
    ipv4     = [
      "172.236.119.4/30",
      "172.234.160.4/30",
      "172.236.94.4/30",
      "139.144.212.168/31",
      "172.232.23.164/31"
    ]
    ipv6     = [
      "2600:3c06::f03c:94ff:febe:162f/128",
      "2600:3c06::f03c:94ff:febe:16ff/128",
      "2600:3c06::f03c:94ff:febe:16c5/128",
      "2600:3c07::f03c:94ff:febe:16e6/128",
      "2600:3c07::f03c:94ff:febe:168c/128",
      "2600:3c07::f03c:94ff:febe:16de/128",
      "2600:3c08::f03c:94ff:febe:16e9/128",
      "2600:3c08::f03c:94ff:febe:1655/128",
      "2600:3c08::f03c:94ff:febe:16fd/128"
    ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allow-external-ips"
    protocol = "TCP"
    ports    = "22,80,443"
    ipv4     = concat(var.settings.pgadmin.allowedIps.ipv4,
                      [ "${jsondecode(data.http.myIp.response_body).ip}/32" ])
    ipv6     = concat(var.settings.pgadmin.allowedIps.ipv6,
                      [ "::1/128" ])
  }

  linodes = [ linode_instance.pgadmin.id ]

  depends_on = [
    data.http.myIp,
    linode_instance.pgadmin
  ]
}