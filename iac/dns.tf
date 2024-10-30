# Required variables.
locals {
  primaryServiceIdentifier    = "${var.settings.cluster.identifier}-primary"
  primaryServiceIp            = compact([ for node in data.linode_nodebalancers.clusterNodeBalancers.nodebalancers : (contains(node.tags, local.primaryServiceIdentifier) ? node.ipv4 : null)])
  replicasServiceIdentifier   = "${var.settings.cluster.identifier}-replicas"
  replicasServiceIp           = compact([ for node in data.linode_nodebalancers.clusterNodeBalancers.nodebalancers : (contains(node.tags, local.replicasServiceIdentifier) ? node.ipv4 : null)])
  monitoringServiceIdentifier = "${var.settings.cluster.identifier}-monitoring"
  monitoringServiceIp         = compact([ for node in data.linode_nodebalancers.clusterNodeBalancers.nodebalancers : (contains(node.tags, local.monitoringServiceIdentifier) ? node.ipv4 : null)])
}

# Definition of the default DNS domain.
resource "linode_domain" "default" {
  domain    = var.settings.general.domain
  type      = "master"
  soa_email = var.settings.general.email
  ttl_sec   = 30
  tags      = concat(var.settings.cluster.tags, [ var.settings.cluster.namespace ])
}

# Definition of the default DNS entry for the PostgreSQL primary instance.
resource "linode_domain_record" "primary" {
  domain_id   = linode_domain.default.id
  name        = "${local.primaryServiceIdentifier}.${var.settings.general.domain}"
  record_type = "A"
  target      = local.primaryServiceIp[0]
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.linode_nodebalancers.clusterNodeBalancers
  ]
}

# Definition of the default DNS entry for the PostgreSQL replica instances.
resource "linode_domain_record" "replicas" {
  domain_id   = linode_domain.default.id
  name        = "${local.replicasServiceIdentifier}.${var.settings.general.domain}"
  record_type = "A"
  target      = local.replicasServiceIp[0]
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.linode_nodebalancers.clusterNodeBalancers
  ]
}

# Definition of the default DNS entry for the PostgreSQL monitoring server instance.
resource "linode_domain_record" "monitoringServer" {
  domain_id   = linode_domain.default.id
  name        = "${local.monitoringServiceIdentifier}.${var.settings.general.domain}"
  record_type = "A"
  target      = local.monitoringServiceIp[0]
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.linode_nodebalancers.clusterNodeBalancers
  ]
}

# Definition of the default DNS entry for the PostgreSQL admin instance.
resource "linode_domain_record" "pgadmin" {
  domain_id   = linode_domain.default.id
  name        = "${var.settings.pgadmin.identifier}.${var.settings.general.domain}"
  record_type = "A"
  target      = linode_instance.pgadmin.ip_address
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    linode_instance.pgadmin
  ]
}

# Definition of the default DNS entry for the Grafana instance.
resource "linode_domain_record" "grafana" {
  domain_id   = linode_domain.default.id
  name        = "${var.settings.grafana.identifier}.${var.settings.general.domain}"
  record_type = "A"
  target      = linode_instance.grafana.ip_address
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    linode_instance.grafana
  ]
}