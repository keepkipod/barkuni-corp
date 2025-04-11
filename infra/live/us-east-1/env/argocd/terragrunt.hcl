include {
  path = find_in_parent_folders("common.hcl")
}

dependency "eks" {
  config_path = "../eks"
}

terraform {
  source = "../../../modules/argocd-bootstrap"
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
  deploy_argocd    = true
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.8.23"
  create_namespace = true
  values           = [
    <<YAML
server:
  extraArgs: ["--insecure"]
YAML
  ]

  # Private repo for the main apps manifests.
  private_repo_url = local.env_vars.locals.private_repo_url

  # Cert-manager bootstrap configuration
  bootstrap_cert_manager         = true
  bootstrap_cert_manager_app_name = "cert-manager"
  bootstrap_cert_manager_chart_repo = "https://charts.jetstack.io"
  bootstrap_cert_manager_chart      = "cert-manager"
  bootstrap_cert_manager_chart_version = "1.17.0"
  bootstrap_cert_manager_values  = file("${get_terragrunt_dir()}/../../addons/cert-manager/values.yaml")

  # External DNS bootstrap configuration
  bootstrap_external_dns         = true
  bootstrap_external_dns_app_name = "external-dns"
  bootstrap_external_dns_chart_repo = "https://charts.bitnami.com/bitnami"
  bootstrap_external_dns_chart      = "external-dns"
  bootstrap_external_dns_chart_version = "8.7.11"
  bootstrap_external_dns_irsa_role_arn = "arn:aws:iam::123456789012:role/external-dns-irsa-role"
  bootstrap_external_dns_values = templatefile(
    "${get_terragrunt_dir()}/../../addons/external-dns/external-dns-values.yaml.tpl",
    {
      irsa_role_arn = var.bootstrap_external_dns_irsa_role_arn
    }
  )

  bootstrap_external_dns_values  = file("${get_terragrunt_dir()}/../../addons/external-dns/values.yaml")

  # Main app bootstrap configuration
  bootstrap_app         = true
  bootstrap_app_name    = "barkuni-app"
  bootstrap_app_path    = "apps/barkuni-app"
  bootstrap_app_namespace = "default"
}
