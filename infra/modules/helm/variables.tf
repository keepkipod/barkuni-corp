variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "lb_role_arn" {
  description = "The IAM role ARN for the LB Controller."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed."
  type        = string
}
