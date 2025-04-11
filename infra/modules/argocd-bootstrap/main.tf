# ---------------------------
# Deploy ArgoCD via Helm Release
# ---------------------------
resource "helm_release" "argocd" {
  count            = var.deploy_argocd ? 1 : 0
  name             = var.name
  namespace        = var.namespace
  repository       = var.repository
  chart            = var.chart
  version          = var.version
  create_namespace = var.create_namespace
  values           = var.values
}

#######################################################
# Create IAM Role for external-dns IRSA
#######################################################

locals {
  external_dns_role_name = "${var.bootstrap_external_dns_app_name}-irsa-role"
}

resource "aws_iam_role" "external_dns_irsa" {
  name = local.external_dns_role_name

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": var.eks_oidc_provider_arn
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${var.eks_oidc_provider_url}:sub": "system:serviceaccount:${var.external_dns_sa_namespace}:${var.external_dns_sa_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "external_dns_policy" {
  name        = "${local.external_dns_role_name}-policy"
  description = "Policy for external-dns IRSA to manage Route53 records"
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

###########################################################
# Bootstrap cert-manager via ArgoCD Application (Sync Wave 0)
###########################################################
resource "kubernetes_manifest" "bootstrap_cert_manager" {
  count = var.bootstrap_cert_manager ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.bootstrap_cert_manager_app_name
      namespace = var.namespace
      annotations = {
        "argocd.argoproj.io/sync-wave" = "0"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.bootstrap_cert_manager_chart_repo
        chart          = var.bootstrap_cert_manager_chart
        targetRevision = var.bootstrap_cert_manager_chart_version
        helm = {
          values = var.bootstrap_cert_manager_values
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "kube-system"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}

###############################################################
# Bootstrap external-dns via ArgoCD Application (Sync Wave 1)
# This uses a template file to inject the generated IRSA role ARN.
###############################################################
resource "kubernetes_manifest" "bootstrap_external_dns" {
  count = var.bootstrap_external_dns ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.bootstrap_external_dns_app_name
      namespace = var.namespace
      annotations = {
        "argocd.argoproj.io/sync-wave" = "1"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.bootstrap_external_dns_chart_repo
        chart          = var.bootstrap_external_dns_chart
        targetRevision = var.bootstrap_external_dns_chart_version
        helm = {
          values = templatefile("${path.module}/external-dns-values.yaml.tpl", {
            irsa_role_arn = aws_iam_role.external_dns_irsa.arn
          })
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "kube-system"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}

#######################################################
# Bootstrap main app via ArgoCD Application (Sync Wave 2)
#######################################################
resource "kubernetes_manifest" "bootstrap_app" {
  count = var.bootstrap_app ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.bootstrap_app_name
      namespace = var.namespace
      annotations = {
        "argocd.argoproj.io/sync-wave" = "2"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.private_repo_url
        targetRevision = "HEAD"
        path           = var.bootstrap_app_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.bootstrap_app_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}
