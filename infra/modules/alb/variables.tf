variable "name" {
  description = "The name for the ALB"
  type        = string
}

variable "subnets" {
  description = "The public subnets to attach the ALB to"
  type        = list(string)
}

variable "security_groups" {
  description = "Pre-existing security group IDs to attach to the ALB. If empty and create_security_group is true, a security group will be created."
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "If true, create a security group for the ALB if none is provided"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the ALB and security group"
  type        = map(string)
  default     = {}
}

variable "target_group_port" {
  description = "Port for the target group"
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "Protocol for the target group"
  type        = string
  default     = "HTTP"
}

variable "zone_id" {
  description = "Route 53 Hosted Zone ID for the domain"
  type        = string
}

variable "domain_name" {
  description = "FQDN that will point to the ALB (e.g., test.vicarius.xyz)"
  type        = string
}