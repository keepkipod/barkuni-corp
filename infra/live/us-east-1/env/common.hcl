locals {
  environment      = "dev"
  cluster_name     = "dev-us-east-1"
  private_repo_url = "https://github.com/keepkipod/barkuni-corp.git"
  tags = {
    Environment = local.environment
    Terraform   = "true"
    Project     = "eks-cluster-demo"
  }
}
