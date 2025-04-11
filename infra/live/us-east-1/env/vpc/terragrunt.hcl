include {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.19.0"
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  vpc_cidr    = "10.0.0.0/16"
}

dependency "datasource" {
  config_path = "../../datasource"
  mock_outputs = {
    aws_availability_zones = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }
}

inputs = {
  name = local.env_vars.locals.cluster_name
  cidr = local.vpc_cidr

  azs             = slice(dependency.datasource.outputs.aws_availability_zones.names, 0, 2)
  private_subnets = [for k, v in slice(dependency.datasource.outputs.aws_availability_zones.names, 0, 2) : cidrsubnet(local.vpc_cidr, 3, k)]
  public_subnets  = [for k, v in slice(dependency.datasource.outputs.aws_availability_zones.names, 0, 2) : cidrsubnet(local.vpc_cidr, 3, k + 2)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags = {
    Tier                                                          = "Private"
    "kubernetes.io/role/internal-elb"                             = 1
    "kubernetes.io/cluster/${local.env_vars.locals.cluster_name}" = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                                      = 1
    "kubernetes.io/cluster/${local.env_vars.locals.cluster_name}" = "owned"
  }

  tags = local.env_vars.locals.tags
}
