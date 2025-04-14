data "aws_route53_zone" "selected" {
  name         = var.root_domain_name
  private_zone = false
}

resource "aws_route53_record" "barkuni" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.subdomain_name}.${var.root_domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
