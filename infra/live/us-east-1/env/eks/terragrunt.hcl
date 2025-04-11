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
}

inputs = {
  cluster_name    = local.env_vars.locals.cluster_name
  cluster_version = "1.32"

  cluster_endpoint_public_access  = true
  enable_cluster_creator_admin_permissions = true
  vpc_id  = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  eks_managed_node_groups = {
    app = {
      ami_type       = "AL2_x86_64"
      instance_types = ["t3.medium"]

      min_size = 1
      max_size = 3
      desired_size = 1
    }
  }

  tags = local.env_vars.locals.tags
}
