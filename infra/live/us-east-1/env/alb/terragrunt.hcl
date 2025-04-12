include {
  path = find_in_parent_folders("common.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "eks" {
  config_path = "../eks"
}

terraform {
  source = "../../../../modules/alb"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region   = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  name                  = "barkuni-alb"
  subnets               = dependency.vpc.outputs.public_subnets
  vpc_id                = dependency.vpc.outputs.vpc_id
  tags                  = local.env_vars.locals.tags
  zone_id               = "Z05252683ATTVWQ56KS7F"
  domain_name           = "test.vicarius.xyz"
  target_group_port     = 80
}
