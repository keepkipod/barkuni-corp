include {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=20.35.0"
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-1234567890abcdef01"
    private_subnets = ["subnet-1234567890abcdef01", "subnet-1234567890abcdef02"]
  }
}

inputs = {
  cluster_name    = local.env_vars.locals.cluster_name
  cluster_version = "1.31"

  cluster_endpoint_public_access  = true
  enable_cluster_creator_admin_permissions = true
  vpc_id  = dependency.vpc.outputs.vpc_id
  subnets = dependency.vpc.outputs.private_subnets

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  node_groups = {
    default = {
      desired_capacity = 2
      min_capacity     = 1
      max_capacity     = 3
      instance_type    = "t3.medium"
    }
  }

  tags = local.env_vars.locals.tags
}
