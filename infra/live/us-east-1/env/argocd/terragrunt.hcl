include {
  path = find_in_parent_folders("common.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
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
  kube_token             = "k8s-aws-v1.aHR0cHM6Ly9zdHMudXMtZWFzdC0xLmFtYXpvbmF3cy5jb20vP0FjdGlvbj1HZXRDYWxsZXJJZGVudGl0eSZWZXJzaW9uPTIwMTEtMDYtMTUmWC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBUTNFR1FHUFNVQUtURFQ2TSUyRjIwMjUwNDEyJTJGdXMtZWFzdC0xJTJGc3RzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LURhdGU9MjAyNTA0MTJUMDkzNzU0WiZYLUFtei1FeHBpcmVzPTYwJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCUzQngtazhzLWF3cy1pZCZYLUFtei1TaWduYXR1cmU9YjBmOTMzNjkwYTE2MjgzZmU4YzFkYjNkOWVjMGM2ODUwN2Q0MTk5NGNiZWU0NTg5NTM5ODY3NDc0ZWMyZDY0NA"
  eks_cluster_name       = local.env_vars.locals.cluster_name
  region                 = local.region.locals.region
  vpc_id                 = dependency.vpc.outputs.vpc_id
  eks_oidc_provider_arn  = dependency.eks.outputs.oidc_provider_arn
  eks_oidc_provider_url  = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"

  ###########################
  # ArgoCD Helm Install Values
  ###########################
  argocd_release_name    = "argocd"
  argocd_namespace       = "argocd"
  argocd_chart_repo      = "https://argoproj.github.io/argo-helm"
  argocd_chart_name      = "argo-cd"
  argocd_chart_version   = "7.8.23"
  argocd_create_namespace = true
  argocd_values          = [
    <<YAML
server:
  extraArgs: ["--insecure"]
YAML
  ]

  ##############################
  # Cert-manager Bootstrap Values
  ##############################
  cert_manager_namespace           = "kube-system"
  bootstrap_cert_manager           = true
  bootstrap_cert_manager_app_name  = "cert-manager"
  bootstrap_cert_manager_chart_repo = "https://charts.jetstack.io"
  bootstrap_cert_manager_chart     = "cert-manager"
  bootstrap_cert_manager_chart_version = "1.17.0"
  bootstrap_cert_manager_values    = file("${get_terragrunt_dir()}/../../../../../k8s/addons/cert-manager/values.yaml")

  ##############################
  # External-dns Bootstrap Values
  ##############################
  bootstrap_external_dns           = true
  bootstrap_external_dns_app_name  = "external-dns"
  external_dns_namespace           = "kube-system"
  external_dns_sa_name             = "external-dns"
  bootstrap_external_dns_chart_repo = "https://charts.bitnami.com/bitnami"
  bootstrap_external_dns_chart     = "external-dns"
  bootstrap_external_dns_chart_version = "8.7.11"
  
  ##############################
  # Main App Bootstrap Values
  ##############################
  private_repo_url       = local.env_vars.locals.private_repo_url
  bootstrap_app          = true
  bootstrap_app_name     = "barkuni-app"
  bootstrap_app_path     = "k8s/apps/barkuni-app"
  bootstrap_app_namespace = "default"
}
