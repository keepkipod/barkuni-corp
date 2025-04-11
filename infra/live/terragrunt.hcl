generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
    
  assume_role {
    role_arn     = "arn:aws:iam::058264138725:role/terraform"
    session_name = "terraform-session"
  }
}
EOF
}
