terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0"
    }
  }
}

provider "helm" {
  # These connection details can be passed through variables if needed.
  kubernetes {
    host                   = var.kube_host
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    token                  = var.kube_token
  }
}

provider "kubectl" {
  host                   = var.kube_host
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = var.kube_token
}

###############################################
# Install ArgoCD via Helm Release
###############################################
resource "helm_release" "argocd" {
  name             = var.argocd_release_name
  namespace        = var.argocd_namespace
  repository       = var.argocd_chart_repo
  chart            = var.argocd_chart_name
  version          = var.argocd_chart_version
  create_namespace = var.argocd_create_namespace
  values           = var.argocd_values
}

###############################################
# Create IRSA role for external-dns (for IRSA)
###############################################
locals {
  external_dns_role_name = "${var.bootstrap_external_dns_app_name}-irsa-role"
}

resource "aws_iam_role" "external_dns_irsa" {
  name = local.external_dns_role_name

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Federated": var.eks_oidc_provider_arn
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${var.eks_oidc_provider_url}:sub": "system:serviceaccount:${var.external_dns_namespace}:${var.external_dns_sa_name}"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "external_dns_policy" {
  name        = "${local.external_dns_role_name}-policy"
  description = "Policy for external-dns to manage Route53 records"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "external_dns_policy_attach" {
  role       = aws_iam_role.external_dns_irsa.name
  policy_arn = aws_iam_policy.external_dns_policy.arn
}

#############################################################
# Deploy Cert-manager ArgoCD Application via kubectl_manifest
#############################################################
resource "kubectl_manifest" "cert_manager" {
  validate_schema = false
  yaml_body = templatefile(
    "${path.module}/manifests/cert-manager.yaml", {
      namespace = var.cert_manager_namespace
    }
  )
}

#############################################################
# Deploy External-dns ArgoCD Application via kubectl_manifest
#############################################################
resource "kubectl_manifest" "external_dns" {
  validate_schema = false
  yaml_body = templatefile(
    "${path.module}/manifests/external-dns.yaml", {
      irsa_role_arn = aws_iam_role.external_dns_irsa.arn,
      namespace     = var.external_dns_namespace
    }
  )
}

#############################################################
# Deploy Main Application (barkuni-app) via kubectl_manifest
#############################################################
resource "kubectl_manifest" "barkuni_app" {
  validate_schema = false
  yaml_body = templatefile(
    "${path.module}/manifests/barkuni-app.yaml", {
      repo_url  = var.private_repo_url,
      app_path  = var.bootstrap_app_path,
      namespace = var.bootstrap_app_namespace
    }
  )
}
