provider "kubernetes" {
  host                   = var.kube_host
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = var.kube_token
}


module "lb_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

  role_name = "eks-alb-controller"
  
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}
/*
resource "kubernetes_service_account" "aws_lb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_role.iam_role_arn
    }
  }
} */

output "iam_role_name" {
  description = "The IAM role name for the LB Controller"
  value       = module.lb_role.iam_role_name
}

output "lb_role_arn" {
  description = "The IAM role ARN for the LB Controller"
  value       = module.lb_role.iam_role_arn
}
