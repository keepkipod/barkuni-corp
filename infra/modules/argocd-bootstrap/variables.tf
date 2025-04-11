variable "deploy_argocd" {
  description = "Flag to deploy the ArgoCD helm release"
  type        = bool
}

variable "name" {
  description = "Release name for ArgoCD"
  type        = string
}

variable "namespace" {
  description = "Namespace where ArgoCD will be deployed"
  type        = string
}

variable "repository" {
  description = "Helm repository URL for ArgoCD"
  type        = string
}

variable "chart" {
  description = "Chart name for ArgoCD"
  type        = string
}

variable "version" {
  description = "Chart version to deploy"
  type        = string
}

variable "create_namespace" {
  description = "Create namespace for ArgoCD if it does not exist"
  type        = bool
}

variable "values" {
  description = "List of YAML strings for values overrides"
  type        = list(string)
}

variable "bootstrap_apps" {
  description = "Flag to deploy a bootstrap ArgoCD application"
  type        = bool
}

variable "bootstrap_app_name" {
  description = "Name of the ArgoCD bootstrap application"
  type        = string
}

variable "bootstrap_app_path" {
  description = "Path in the repository to find the app manifests"
  type        = string
}

variable "bootstrap_app_namespace" {
  description = "Destination namespace for the bootstrap application"
  type        = string
}

variable "private_repo_url" {
  description = "Private git repository URL for bootstrapping workloads"
  type        = string
}
