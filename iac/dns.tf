# Required environment variables.
locals {
  fetchNodeBalancersScriptFilename = abspath(pathexpand("../bin/fetchNodeBalancers.sh"))
}

# Fetches the clusters' node balancers.
data "external" "fetchNodeBalancers" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  program = [
    local.fetchNodeBalancersScriptFilename,
    local_sensitive_file.kubeconfig[each.key].filename,
    each.value.namespace
  ]
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
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  domain_id   = linode_domain.default.id
  name        = "${each.key}-primary.${var.settings.general.domain}"
  record_type = "CNAME"
  target      = data.external.fetchNodeBalancers[each.key].result.primaryHostname
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.external.fetchNodeBalancers
  ]
}

# Definition of the default DNS entry for the PostgreSQL replicas instances.
resource "linode_domain_record" "replicas" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  domain_id   = linode_domain.default.id
  name        = "${each.key}-replicas.${var.settings.general.domain}"
  record_type = "CNAME"
  target      = data.external.fetchNodeBalancers[each.key].result.replicasHostname
  ttl_sec     = 30

  depends_on  = [
    linode_domain.default,
    data.external.fetchNodeBalancers
  ]
}

# Definition of the default DNS entry for the monitoring instances.
resource "linode_domain_record" "monitoring" {
  for_each = { for cluster in var.settings.clusters : cluster.identifier => cluster }

  domain_id   = linode_domain.default.id
  name        = "${each.key}-monitoring.${var.settings.general.domain}"
  record_type = "CNAME"
  target      = data.external.fetchNodeBalancers[each.key].result.monitoringHostname
  ttl_sec     = 30

  depends_on  = [
    linode_domain.default,
    data.external.fetchNodeBalancers
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