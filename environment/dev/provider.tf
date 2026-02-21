provider "aws" {
  region  = var.region
  profile = var.profile_infra
  default_tags {
    tags = {
      Product   = var.product
      App       = var.service
      Env       = var.identity
      Terraform = true
    }
  }
}
