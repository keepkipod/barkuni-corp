include {
  path = find_in_parent_folders("common.hcl")
}

dependency "eks" {
  config_path = "../eks"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region   = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

terraform {
  source = "../../../../modules/lb-iam"
}

inputs = {
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
}
