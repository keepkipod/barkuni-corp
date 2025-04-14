module "lb_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.0"

  role_name = "eks-lb-controller"
  
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}


output "iam_role_name" {
  description = "The IAM role name for the LB Controller"
  value       = module.lb_role.iam_role_name
}

output "lb_role_arn" {
  description = "The IAM role ARN for the LB Controller"
  value       = module.lb_role.iam_role_arn
}
