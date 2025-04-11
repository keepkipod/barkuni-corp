variable "kube_host" {
  description = "Kubernetes API server endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64 encoded certificate for the Kubernetes cluster"
  type        = string
}

variable "kube_token" {
  description = "Bearer token to authenticate to the Kubernetes cluster"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "OIDC provider ARN from the EKS cluster"
  type        = string
}

variable "eks_oidc_provider_url" {
  description = "OIDC provider URL from the EKS cluster"
  type        = string
}

#########################
# Cert-manager settings
#########################
variable "cert_manager_namespace" {
  description = "Target namespace for cert-manager"
  type        = string
  default     = "default"
}

#########################
# External-dns settings
#########################
variable "bootstrap_external_dns_app_name" {
  description = "Name of the external-dns ArgoCD application"
  type        = string
}

variable "external_dns_namespace" {
  description = "Kubernetes namespace where external-dns should be deployed"
  type        = string
  default     = "default"
}

variable "external_dns_sa_name" {
  description = "ServiceAccount name for external-dns"
  type        = string
  default     = "external-dns"
}

#########################
# Main app settings
#########################
variable "private_repo_url" {
  description = "URL for the private Git repository that contains the main app manifests"
  type        = string
}

variable "bootstrap_app_path" {
  description = "Path in the Git repository for the main app manifests"
  type        = string
}

variable "bootstrap_app_namespace" {
  description = "Kubernetes namespace for the main application"
  type        = string
}
