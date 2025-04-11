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
  env_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region   = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  kube_host              = dependency.eks.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.eks.outputs.cluster_certificate_authority_data
  kube_token             = ""
  
  # Supply OIDC provider details (if your eks module does not output the URL, provide one manually)
  eks_oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  eks_oidc_provider_url = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"  # Replace with your real value

  # Cert-manager bootstrap configuration
  cert_manager_namespace           = "kube-system"
  bootstrap_cert_manager           = true
  bootstrap_cert_manager_app_name  = "cert-manager"
  bootstrap_cert_manager_chart_repo = "https://charts.jetstack.io"
  bootstrap_cert_manager_chart     = "cert-manager"
  bootstrap_cert_manager_chart_version = "1.17.0"
  # From current directory (infra/live/us-east-1/env/argocd) go up 5 levels to reach the project root, then into k8s/addons/cert-manager
  bootstrap_cert_manager_values    = file("${get_terragrunt_dir()}/../../../../../k8s/addons/cert-manager/values.yaml")

  # External DNS bootstrap configuration
  bootstrap_external_dns           = true
  bootstrap_external_dns_app_name  = "external-dns"
  external_dns_namespace           = "kube-system"
  external_dns_sa_name             = "external-dns"
  bootstrap_external_dns_chart_repo = "https://charts.bitnami.com/bitnami"
  bootstrap_external_dns_chart     = "external-dns"
  bootstrap_external_dns_chart_version = "8.7.11"
  # The module internally uses a template (placed in its manifests directory) to inject the IRSA role ARN.
  
  # Main app bootstrap configuration
  private_repo_url            = local.env_vars.locals.private_repo_url
  bootstrap_app               = true
  bootstrap_app_name          = "barkuni-app"
  bootstrap_app_path          = "k8s/apps/barkuni-app"
  bootstrap_app_namespace     = "app"
}
