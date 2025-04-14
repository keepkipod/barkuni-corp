include {
  path = find_in_parent_folders("common.hcl")
}

dependency "eks" {
  config_path = "../eks"
}

dependency "lb_iam" {
  config_path = "../lb-iam"
}

dependency "vpc" {
  config_path = "../vpc"
}

generate "helm_provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "helm" {
  kubernetes {
    host                   = "${dependency.eks.outputs.cluster_endpoint}"
    cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_certificate_authority_data}")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}"]
      command     = "aws"
    }
  }
}
EOF
}

terraform {
  source = "../../../../modules/helm"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region   = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  eks_cluster_name      = dependency.eks.outputs.cluster_name
  lb_role_arn           = dependency.lb_iam.outputs.lb_role_arn
  region                = local.region.locals.region
  vpc_id                = dependency.vpc.outputs.vpc_id
}
