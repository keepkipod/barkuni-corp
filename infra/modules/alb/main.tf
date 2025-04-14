resource "aws_security_group" "alb" {
  name        = var.alb_sg_name
  description = "Security group for ALB ${var.alb_name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidr
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.15.0"

  name               = var.alb_name
  load_balancer_type = "application"
  internal           = false
  vpc_id             = var.vpc_id
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb.id]

  target_groups = [
    {
      name             = var.alb_tg_name
      backend_protocol = var.alb_tg_protocol
      backend_port     = var.alb_tg_port
      target_type      = "ip"
    }
  ]

  http_tcp_listeners = [
    {
      port               = var.alb_listener_port
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = var.tags
}
