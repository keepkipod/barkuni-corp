locals {
  environment      = "dev"
  cluster_name     = "dev-us-east-1"
  vpc_cidr         = "10.0.0.0/16"
  private_repo_url = "git@github.com:keepkipod/barkuni-corp.git"
  tags = {
    Environment = local.environment
    Terraform   = "true"
    Project     = "eks-cluster-demo"
  }
}
