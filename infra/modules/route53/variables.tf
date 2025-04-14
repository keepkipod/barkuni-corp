variable "root_domain_name" {
  description = "The root domain name (e.g., vicarius.xyz)"
  type        = string
}

variable "subdomain_name" {
  description = "Subdomain to use (e.g., test)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the ALB"
  type        = string
}

variable "tags" {
  description = "Tags for Route53 records"
  type        = map(string)
}
