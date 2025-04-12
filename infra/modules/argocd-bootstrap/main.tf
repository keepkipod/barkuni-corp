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
/*
resource "aws_iam_policy" "aws_lb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("iam_policy.json")
}

#############################################################
# Deploy AWS LoadBalancer Controller 
#############################################################
resource "helm_release" "awslb" {
  name      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart     = "aws-load-balancer-controller"
  namespace = "kube-system"
  version = "1.12.0"

  set {
    name  = "clusterName"
    value = "var.eks_cluster_name"
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "region"
    value = var.region
  }
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
}
*/
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
/*
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
        namespace = "kube-system"
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
# Deploy nginx ArgoCD Application
#############################################################
resource "kubernetes_manifest" "nginx_argo_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "nginx-argo-app"
      namespace = "argocd"
      annotations = {
        "argocd.argoproj.io/sync-wave" = "1"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://kubernetes.github.io/ingress-nginx"
        chart          = "ingress-nginx"
        targetRevision = "4.12.1"
        helm = {
          values = yamlencode({
            controller = {
              service = {
                type = "LoadBalancer"
              }
            }
          })
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "ingress-nginx"
      }
      syncPolicy = {
        automated = {
          selfHeal = true
          prune    = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }
}
*/
#############################################################
# Deploy Barkuni ArgoCD Application
#############################################################
resource "kubernetes_manifest" "barkuni_argo_app" { 
  depends_on = [helm_release.argocd]
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "barkuni-app"
      namespace = "argocd"
      annotations = {
        "argocd.argoproj.io/sync-wave" = "2"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.private_repo_url
        targetRevision = "HEAD"
        path           = "k8s/apps/barkuni-app"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
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