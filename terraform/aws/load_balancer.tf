resource "aws_lb" "penpot" {
  name               = "penpot-${var.env}"
  internal           = false
  load_balancer_type = "application"

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  security_groups = [
    aws_security_group.penpot_lb.id
  ]
  subnets = module.penpot_vpc.public_subnet_ids

  tags = local.common_tags
}

resource "random_string" "penpot_lb_tg_suffix" {
  for_each = {for service in local.ecs_services : service.name => service}

  length  = 3
  special = false
  upper   = false

  keepers = {
    port     = each.value.port
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group" "penpot_tg" {
  for_each = {for service in local.ecs_services : service.name => service}

  name                 = "penpot-${each.value.name}-${random_string.penpot_lb_tg_suffix[each.value.name].result}"
  port                 = each.value.port
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = module.penpot_vpc.vpc_id

  health_check {
    enabled  = true
    protocol = "HTTP"
    path     = each.value.health_check_path
    matcher  = "200-399"
  }

  stickiness {
    type = "lb_cookie"
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      stickiness[0].cookie_name
    ]
  }
}


resource "aws_lb_listener" "penpot" {
  load_balancer_arn = aws_lb.penpot.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-FIPS-2023-04"
  certificate_arn   = aws_acm_certificate.penpot.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.penpot_tg["frontend"].arn
  }

  depends_on = [
    aws_acm_certificate_validation.penpot,
    aws_route53_record.penpot_validation,
  ]

  tags = local.common_tags
}

resource "aws_lb_listener" "penpot_http_redirect" {
  load_balancer_arn = aws_lb.penpot.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.common_tags
}

resource "aws_alb_listener_rule" "penpot_exporter" {
  listener_arn = aws_lb_listener.penpot.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.penpot_tg["exporter"].arn
  }

  condition {
    path_pattern {
      values = ["/api/export"]
    }
  }
}

resource "aws_alb_listener_rule" "penpot_backend" {
  listener_arn = aws_lb_listener.penpot.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.penpot_tg["backend"].arn
  }

  condition {
    path_pattern {
      values = [
        "/api/*",
        "/ws/notifications",
        "/assets/*"
      ]
    }
  }
}