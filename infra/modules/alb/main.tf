#############################
# Create ALB Security Group
#############################
resource "aws_security_group" "alb" {
  count       = var.create_security_group && length(var.security_groups) == 0 ? 1 : 0

  name        = "${var.name}-sg"
  description = "Security group for ALB ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}

#############################
# Determine Final Security Groups
#############################
locals {
  final_security_groups = length(var.security_groups) > 0 ? var.security_groups : [aws_security_group.alb[0].id]
}

#############################
# Provision the ALB using the terraform-aws-modules/alb/aws module
#############################
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.15.0"

  name               = var.name
  load_balancer_type = "application"
  internal           = false
  subnets            = var.subnets
  security_groups    = local.final_security_groups
  vpc_id             = var.vpc_id

  target_groups = {
    default = {
      name_prefix      = substr(var.name, 0, 6)
      backend_protocol = var.target_group_protocol
      target_type      = "ip"
      port             = var.target_group_port
    }
  }

  listeners = {
    alb_listener = {
      port = 80
      protocol = "HTTP"
      default_actions = [
        {
          type             = "forward"
          target_group_key = "default"
        }
      ]
    }
    ex-fixed-response = {
      port     = 82
      protocol = "HTTP"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed message"
        status_code  = "200"
      }
    }
  }

  additional_target_group_attachments = {}

  tags = var.tags
}

#############################
# Create a Route 53 A record pointing your domain to the ALB
#############################
resource "aws_route53_record" "alb_record" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

#############################
# Output the ALB DNS Name
#############################
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}
