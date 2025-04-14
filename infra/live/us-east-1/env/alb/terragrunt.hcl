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
  vpc_id           = dependency.vpc.outputs.vpc_id
  public_subnets   = dependency.vpc.outputs.public_subnets
  tags             = local.env_vars.locals.tags

  alb_name         = "barkuni-alb"
  alb_sg_name      = "barkuni-alb-sg"
  alb_ingress_cidr = ["0.0.0.0/0"]

  alb_tg_name      = "barkuni-tg"
  alb_tg_protocol  = "HTTP"
  alb_tg_port      = 80
  alb_listener_port = 80

  zone_id           = "Z05252683ATTVWQ56KS7F"
  domain_name       = "test.vicarius.xyz"
}
