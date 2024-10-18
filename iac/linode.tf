# Akamai Cloud Computing provider definition.
provider "linode" {
  config_path = local.apiCredentialsFilename
}