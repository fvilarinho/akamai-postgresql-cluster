# Terraform definition.
terraform {
  # Stores the provisioning state in Akamai Cloud Computing Object Storage (Please change to use your own).
  backend "s3" {
    bucket                      = "fvilarin-devops"
    key                         = "akamai-postgresql-cluster.tfstate"
    region                      = "us-east-1"
    endpoint                    = "us-east-1.linodeobjects.com"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }
}

module "provisioning" {
  source   = "./provisioning"
  settings = var.settings
}

module "publish" {
  source       = "./publish"
  settings     = var.settings
  clusterNodes = module.provisioning.clusterNodes
  grafanaNode  = module.provisioning.grafanaNode
  pgadminNode  = module.provisioning.pgadminNode
}