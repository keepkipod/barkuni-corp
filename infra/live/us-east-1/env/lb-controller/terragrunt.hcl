include {
  path = find_in_parent_folders("common.hcl")
}

terraform {
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-lb-controller.git"
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

dependency "eks" {
  config_path = "../eks"
}

inputs = {
  cluster_identity_oidc_issuer     = dependency.eks.outputs.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = dependency.eks.outputs.oidc_provider_arn
  cluster_name                     = dependency.eks.outputs.cluster_name
}
