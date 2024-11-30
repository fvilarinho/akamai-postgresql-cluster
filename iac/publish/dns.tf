# Required variables.
locals {
  primaryServiceIp    = join("", compact([ for nodeBalancer in data.linode_nodebalancers.clusterNodeBalancers.nodebalancers : (contains(nodeBalancer.tags, local.primaryServiceIdentifier) ? nodeBalancer.ipv4 : null) ]))
  replicasServiceIp   = join("", compact([ for nodeBalancer in data.linode_nodebalancers.clusterNodeBalancers.nodebalancers : (contains(nodeBalancer.tags, local.replicasServiceIdentifier) ? nodeBalancer.ipv4 : null)]))
  monitoringServiceIp = join("", compact([ for nodeBalancer in data.linode_nodebalancers.clusterNodeBalancers.nodebalancers : (contains(nodeBalancer.tags, local.monitoringServiceIdentifier) ? nodeBalancer.ipv4 : null)]))
}

# Definition of the default DNS domain.
resource "linode_domain" "default" {
  domain    = var.settings.general.domain
  type      = "master"
  soa_email = var.settings.general.email
  ttl_sec   = 30
  tags      = var.settings.general.tags
}

# Definition of the default DNS entry for the PostgreSQL primary instance.
resource "linode_domain_record" "primary" {
  domain_id   = linode_domain.default.id
  name        = "${local.primaryServiceIdentifier}.${var.settings.general.domain}"
  record_type = "A"
  target      = local.primaryServiceIp
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
  target      = local.replicasServiceIp
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.linode_nodebalancers.clusterNodeBalancers
  ]
}

# Definition of the default DNS entry for the PostgreSQL monitoring server instance.
resource "linode_domain_record" "monitoring" {
  domain_id   = linode_domain.default.id
  name        = "${local.monitoringServiceIdentifier}.${var.settings.general.domain}"
  record_type = "A"
  target      = local.monitoringServiceIp
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
  target      = var.pgadminNode.ip_address
  ttl_sec     = 30
  depends_on  = [ linode_domain.default ]
}

# Definition of the default DNS entry for the Grafana instance.
resource "linode_domain_record" "grafana" {
  domain_id   = linode_domain.default.id
  name        = "${var.settings.grafana.identifier}.${var.settings.general.domain}"
  record_type = "A"
  target      = var.grafanaNode.ip_address
  ttl_sec     = 30
  depends_on  = [ linode_domain.default ]
}