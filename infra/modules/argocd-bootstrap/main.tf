data "aws_eks_cluster_auth" "eks" {
  name = var.eks_cluster_name
}

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

#######################
# Providers
#######################
provider "helm" {
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

#############################
# Install ArgoCD via Helm Release
#############################
resource "helm_release" "argocd" {
  name             = var.argocd_release_name
  namespace        = var.argocd_namespace
  repository       = var.argocd_chart_repo
  chart            = var.argocd_chart_name
  version          = var.argocd_chart_version
  create_namespace = var.argocd_create_namespace

  values = concat(
    var.argocd_values,
    [
      "installCRDs: true"
    ]
  )
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
  depends_on = [helm_release.argocd]
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
  depends_on = [helm_release.argocd]
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
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "role" {
  name               = "${var.eks_cluster_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ec2-full-access-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.role.name
}

resource "aws_eks_pod_identity_association" "barkuni" {
  cluster_name    = var.eks_cluster_name
  namespace       = "default"
  service_account = "barkuni"
  role_arn        = aws_iam_role.role.arn
}

resource "kubectl_manifest" "barkuni_app" {
  depends_on = [helm_release.argocd]
  validate_schema = false
  yaml_body = templatefile(
    "${path.module}/manifests/barkuni-app.yaml", {
      repo_url  = var.private_repo_url,
      app_path  = var.bootstrap_app_path,
      namespace = var.bootstrap_app_namespace
      service_account = aws_eks_pod_identity_association.barkuni.role_arn
    }
  )
}