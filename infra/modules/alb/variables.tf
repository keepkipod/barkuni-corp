variable "vpc_id" {
  description = "VPC ID for ALB"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "tags" {
  description = "Tags for ALB resources"
  type        = map(string)
  default     = {}
}

variable "alb_name" {
  description = "Name for the ALB"
  type        = string
}

variable "alb_sg_name" {
  description = "Name for the ALB security group"
  type        = string
}

variable "alb_ingress_cidr" {
  description = "CIDR blocks allowed to access the ALB (for ingress)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_tg_name" {
  description = "Name for the ALB target group"
  type        = string
}

variable "alb_tg_protocol" {
  description = "Backend protocol for the target group"
  type        = string
  default     = "HTTP"
}

variable "alb_tg_port" {
  description = "Backend port for the target group"
  type        = number
  default     = 80
}

variable "alb_listener_port" {
  description = "Listener port for the ALB"
  type        = number
  default     = 80
}
