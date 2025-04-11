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

resource "kubernetes_manifest" "bootstrap_application" {
  count = var.bootstrap_apps ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.bootstrap_app_name
      namespace = var.namespace
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
          prune     = true
          selfHeal  = true
        }
      }
    }
  }
}
