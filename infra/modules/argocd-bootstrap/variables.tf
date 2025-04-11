variable "deploy_argocd" {
  description = "Flag to deploy the ArgoCD Helm release"
  type        = bool
}

variable "name" {
  description = "Helm release name for ArgoCD"
  type        = string
}

variable "namespace" {
  description = "Namespace where ArgoCD is deployed and where Application CRs are created"
  type        = string
}

variable "repository" {
  description = "Helm repository URL for the ArgoCD chart"
  type        = string
}

variable "chart" {
  description = "Chart name for ArgoCD"
  type        = string
}

variable "version" {
  description = "Version of the ArgoCD chart"
  type        = string
}

variable "create_namespace" {
  description = "Create the ArgoCD namespace if it doesn’t exist"
  type        = bool
}

variable "values" {
  description = "List of YAML strings for overriding values for the ArgoCD installation"
  type        = list(string)
}

variable "private_repo_url" {
  description = "URL for the Git repository containing private manifests (used for the main app)"
  type        = string
}

###########################################
# Variables for cert-manager bootstrap
###########################################
variable "bootstrap_cert_manager" {
  description = "Deploy the cert-manager ArgoCD Application"
  type        = bool
  default     = true
}

variable "bootstrap_cert_manager_app_name" {
  description = "Name of the ArgoCD Application for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "bootstrap_cert_manager_chart_repo" {
  description = "Public Helm repository URL for cert-manager"
  type        = string
  default     = "https://charts.bitnami.com/bitnami"
}

variable "bootstrap_cert_manager_chart" {
  description = "Helm chart name for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "bootstrap_cert_manager_chart_version" {
  description = "Helm chart version for cert-manager"
  type        = string
  default     = "1.8.0"
}

variable "bootstrap_cert_manager_values" {
  description = "Override values for cert-manager chart (YAML content)"
  type        = string
}

###########################################
# Variables for external-dns bootstrap
###########################################
variable "bootstrap_external_dns" {
  description = "Deploy the external-dns ArgoCD Application"
  type        = bool
  default     = true
}

variable "bootstrap_external_dns_app_name" {
  description = "Name of the ArgoCD Application for external-dns"
  type        = string
  default     = "external-dns"
}

variable "bootstrap_external_dns_chart_repo" {
  description = "Public Helm repository URL for external-dns"
  type        = string
  default     = "https://charts.bitnami.com/bitnami"
}

variable "bootstrap_external_dns_chart" {
  description = "Helm chart name for external-dns"
  type        = string
  default     = "external-dns"
}

variable "bootstrap_external_dns_chart_version" {
  description = "Helm chart version for external-dns"
  type        = string
  default     = "2.25.1"
}

variable "bootstrap_external_dns_values" {
  description = "Override values for external-dns chart (YAML content); this template will be processed"
  type        = string
}

###########################################
# Variables for main app bootstrap
###########################################
variable "bootstrap_app" {
  description = "Deploy the main app ArgoCD Application"
  type        = bool
  default     = true
}

variable "bootstrap_app_name" {
  description = "Name of the ArgoCD Application for the main app"
  type        = string
}

variable "bootstrap_app_path" {
  description = "Path in the private Git repo for the main app manifests"
  type        = string
}

variable "bootstrap_app_namespace" {
  description = "Destination namespace for the main app deployment"
  type        = string
}

###########################################################
# New variables for creating the external-dns IRSA role
###########################################################
variable "eks_oidc_provider_arn" {
  description = "The OIDC provider ARN for the EKS cluster"
  type        = string
}

variable "eks_oidc_provider_url" {
  description = "The OIDC provider URL for the EKS cluster (e.g., oidc.eks.<region>.amazonaws.com/id/EXAMPLE)"
  type        = string
}

variable "external_dns_sa_namespace" {
  description = "The Kubernetes namespace for the external-dns service account"
  type        = string
  default     = "default"
}

variable "external_dns_sa_name" {
  description = "The name of the external-dns service account"
  type        = string
  default     = "external-dns"
}
