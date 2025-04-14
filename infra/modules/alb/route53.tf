resource "aws_route53_record" "alb_record" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"
  
  alias {
    name                   = dependency.alb.outputs.alb_dns_name
    zone_id                = dependency.alb.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

variable "zone_id" {
  description = "Route53 Hosted Zone ID for the domain"
  type        = string
}

variable "domain_name" {
  description = "Domain name to point to the ALB (e.g., test.vicarius.xyz)"
  type        = string
}
