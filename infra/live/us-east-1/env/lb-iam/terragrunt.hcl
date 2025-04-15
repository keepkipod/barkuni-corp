include {
  path = find_in_parent_folders("common.hcl")
}

dependency "eks" {
  config_path = "../eks"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region   = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

terraform {
  source = "../../../../modules/lb-iam"
}

inputs = {
  kube_host                   = dependency.eks.outputs.cluster_endpoint
  cluster_ca_certificate      = dependency.eks.outputs.cluster_certificate_authority_data
  kube_token                  = "k8s-aws-v1.aHR0cHM6Ly9zdHMudXMtZWFzdC0xLmFtYXpvbmF3cy5jb20vP0FjdGlvbj1HZXRDYWxsZXJJZGVudGl0eSZWZXJzaW9uPTIwMTEtMDYtMTUmWC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBUTNFR1FHUFNVQUtURFQ2TSUyRjIwMjUwNDE1JTJGdXMtZWFzdC0xJTJGc3RzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LURhdGU9MjAyNTA0MTVUMDgwMDEwWiZYLUFtei1FeHBpcmVzPTYwJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCUzQngtazhzLWF3cy1pZCZYLUFtei1TaWduYXR1cmU9OTI4ZDgzMGY5ZDI4ODlhOGI3MzA4NWEzMGRmNGQ3MjJjY2M5MTg5NzFhMGUyNmUyMTRjYWM5MWM1NTVkNmVmMw"
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
}
