include {
  path = find_in_parent_folders("common.hcl")
}

dependency "eks" {
  config_path = "../eks"
}

terraform {
  source = "../../../../modules/argocd-bootstrap"
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

generate "helm_provider" {
  path      = "helm_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data "aws_eks_cluster_auth" "eks" {
  name = dependency.eks.outputs.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = dependency.eks.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(dependency.eks.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
EOF
}

inputs = {
  deploy_argocd       = true
  name                = "argocd"
  namespace           = "argocd"
  repository          = "https://argoproj.github.io/argo-helm"
  chart               = "argo-cd"
  version             = "7.8.23"
  create_namespace    = true
  values              = [
    <<YAML
server:
  extraArgs: ["--insecure"]
YAML
  ]

  # Bootstrapping application settings
  bootstrap_apps       = true
  bootstrap_app_name   = "app-bootstrap"
  bootstrap_app_path   = "bootstrap"         # path inside your private repo where the workload manifests are stored
  bootstrap_app_namespace = "default"
  private_repo_url     = local.private_repo_url
}
