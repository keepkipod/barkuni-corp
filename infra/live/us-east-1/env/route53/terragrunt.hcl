include {
  path = find_in_parent_folders("common.hcl")
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs = {
    alb_dns_name = "dualstack.k8s-default-barkuni-d6b4e0119b-43202206.us-east-1.elb.amazonaws.com"
    alb_zone_id  = "Z05252683ATTVWQ56KS7F"
  }
}

terraform {
  source = "../../../../modules/route53"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region   = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  root_domain_name = "vicarius.xyz"
  subdomain_name   = "test"
  alb_dns_name     = dependency.alb.outputs.alb_dns_name
  alb_zone_id      = dependency.alb.outputs.alb_zone_id
  tags             = local.env_vars.locals.tags
}
