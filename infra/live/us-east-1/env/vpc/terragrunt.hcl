include {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.19.0"
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  name = local.env_vars.locals.environment
  cidr = local.env_vars.locals.vpc_cidr

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = local.env_vars.locals.tags
}
