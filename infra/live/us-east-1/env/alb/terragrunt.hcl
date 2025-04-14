include {
  path = find_in_parent_folders("common.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "eks" {
  config_path = "../eks"
}

generate "aws_provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::058264138725:role/terraform"
    session_name = "terraform-session"
  }
}
EOF
}

terraform {
  source = "../../../../modules/alb"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region   = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  subnet_ids = dependency.vpc.outputs.public_subnets
  vpc_id = dependency.vpc.outputs.vpc_id
  tags = local.env_vars.locals.tags
}
