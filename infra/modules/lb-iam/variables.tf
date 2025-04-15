variable "kube_host" {
  description = "The Kubernetes API server endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "The base64-encoded CA certificate for the Kubernetes cluster"
  type        = string
}

variable "kube_token" {
  description = "The authentication token for the Kubernetes cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC provider associated with your EKS cluster"
  type        = string
}
