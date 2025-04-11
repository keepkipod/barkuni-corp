data "aws_eks_cluster_auth" "eks" {
  name = var.eks_cluster_name
}

terraform {
  required_providers {
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

provider "kubernetes" {
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
# Deploy Cert-manager ArgoCD Application
#############################################################
resource "kubernetes_manifest" "cert_manager_argo_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "cert-manager-argo-app"
      namespace = "argocd"
      annotations = {
        "argocd.argoproj.io/sync-wave" = "0"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://charts.jetstack.io"
        chart          = "cert-manager"
        targetRevision = "1.17.0"
        helm = {
          values = yamlencode({
            installCRDs = true
            extraArgs   = [
              "--enable-certificate-owner-ref=true"
            ]
          })
        }
      }
      destination = {
        server = "https://kubernetes.default.svc"
      }
      syncPolicy = {
        automated = {
          selfHeal = true
          prune    = true
        }
      }
    }
  }
}

#############################################################
# Deploy External-dns ArgoCD Application
#############################################################
resource "kubernetes_manifest" "external_dns_argo_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "external-dns-argo-app"
      namespace = "argocd"
      annotations = {
        "argocd.argoproj.io/sync-wave" = "1"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://charts.bitnami.com/bitnami"
        chart          = "external-dns"
        targetRevision = "8.7.11"
        helm = {
          values = yamlencode({
            replicaCount = 1
            serviceAccount = {
              create = true
              name   = "external-dns"
              annotations = {
                "eks.amazonaws.com/role-arn" = local.external_dns_role_name
              }
            }
            provider   = "aws"
            txtOwnerId = "barkuni-dev"
            interval   = "1m"
          })
        }
      }
      destination = {
        server = "https://kubernetes.default.svc"
      }
      syncPolicy = {
        automated = {
          selfHeal = true
          prune    = true
        }
      }
    }
  }
}

#############################################################
# Deploy Main Application (barkuni-app)
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

resource "kubernetes_manifest" "barkuni_argo_app" { 
  depends_on      = [helm_release.argocd]
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "barkuni-app"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.private_repo_url
        targetRevision = "HEAD"
        path           = "barkuni-app"
        helm = {
          parameters = [
            {
              name  = "serviceAccount.annotations.eks.amazonaws.com/role-arn"
              value = aws_eks_pod_identity_association.barkuni.role_arn
            },
          ]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          selfHeal = true
          prune     = true
        }
      }
    }
  }
}