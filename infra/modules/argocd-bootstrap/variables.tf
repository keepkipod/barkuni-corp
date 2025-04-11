variable "eks_cluster_name" {
  description = "Cluster Name"
  type        = string
}

variable "kube_host" {
  description = "Kubernetes API server endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate for the cluster"
  type        = string
}

variable "kube_token" {
  description = "Bearer token for Kubernetes authentication"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "eks_oidc_provider_url" {
  description = "EKS OIDC provider URL (e.g., oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE)"
  type        = string
}

######################
# ArgoCD Helm Install
######################
variable "argocd_release_name" {
  description = "Helm release name for ArgoCD"
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace in which ArgoCD will be installed"
  type        = string
}

variable "argocd_chart_repo" {
  description = "Helm repository URL for the ArgoCD chart"
  type        = string
}

variable "argocd_chart_name" {
  description = "ArgoCD chart name"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD chart version"
  type        = string
}

variable "argocd_create_namespace" {
  description = "Whether to create the ArgoCD namespace"
  type        = bool
}

variable "argocd_values" {
  description = "List of YAML strings that override values for the ArgoCD chart"
  type        = list(string)
}

#########################
# Cert-manager Settings
#########################
variable "cert_manager_namespace" {
  description = "Kubernetes namespace for cert-manager"
  type        = string
}

#########################
# External-dns Settings
#########################
variable "bootstrap_external_dns_app_name" {
  description = "Name of the external-dns ArgoCD application"
  type        = string
}

variable "external_dns_namespace" {
  description = "Kubernetes namespace where external-dns is deployed"
  type        = string
}

variable "external_dns_sa_name" {
  description = "Service account name for external-dns"
  type        = string
}

#########################
# Main App Settings
#########################
variable "private_repo_url" {
  description = "Private Git repository URL containing the main app manifests"
  type        = string
}

variable "bootstrap_app_path" {
  description = "Path in the repository for the main app manifests"
  type        = string
}

variable "bootstrap_app_namespace" {
  description = "Kubernetes namespace for the main app"
  type        = string
}
