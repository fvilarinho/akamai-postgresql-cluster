# Required variables.
locals {
  stackPrimaryHostname              = "${var.settings.cluster.identifier}-primary.${var.settings.general.domain}"
  stackReplicasHostname             = "${var.settings.cluster.identifier}-replicas.${var.settings.general.domain}"
  consoleHostname                   = "${var.settings.console.identifier}.${var.settings.general.domain}"
  fetchStackHostnamesScriptFilename = abspath(pathexpand("../bin/fetchStackHostnames.sh"))
}

data "external" "fetchStackHostnames" {
  program = [
    local.fetchStackHostnamesScriptFilename,
    local.kubeconfigFilename,
    var.settings.cluster.namespace,
    var.settings.cluster.identifier
  ]

  depends_on = [ null_resource.applyStackManifest ]
}

# Definition of the default DNS domain.
resource "linode_domain" "default" {
  domain    = var.settings.general.domain
  type      = "master"
  soa_email = var.settings.general.email
  ttl_sec   = 30
  tags      = concat(var.settings.cluster.tags, [ var.settings.cluster.namespace ])
}

# Definition of the default DNS entry for the primary instance.
resource "linode_domain_record" "primary" {
  domain_id   = linode_domain.default.id
  name        = local.stackPrimaryHostname
  record_type = "CNAME"
  target      = data.external.fetchStackHostnames.result.primary
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.external.fetchStackHostnames
  ]
}

# Definition of the default DNS entry for the replica instances.
resource "linode_domain_record" "replicas" {
  domain_id   = linode_domain.default.id
  name        = local.stackReplicasHostname
  record_type = "CNAME"
  target      = data.external.fetchStackHostnames.result.replicas
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.external.fetchStackHostnames
  ]
}

# Definition of the default DNS entry for the console instance.
resource "linode_domain_record" "console" {
  domain_id   = linode_domain.default.id
  name        = local.consoleHostname
  record_type = "A"
  target      = linode_instance.console.ip_address
  ttl_sec     = 30
  depends_on  = [ linode_instance.console ]
}