variable "vpc_id" {
  description = "The VPC ID in which the ALB is deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnets for the ALB."
  type        = list(string)
}

variable "tags" {
  description = "Tags to assign to ALB resources."
  type        = map(string)
}
