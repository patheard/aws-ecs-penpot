locals {
  common_tags = {
    Terraform  = "true"
    CostCentre = var.billing_code
  }
}

module "penpot_vpc" {
  source = "github.com/cds-snc/terraform-modules//vpc?ref=v10.2.0"
  name   = "penpot-${var.env}"

  enable_flow_log                  = true
  availability_zones               = 2
  cidrsubnet_newbits               = 8
  single_nat_gateway               = true
  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true

  billing_tag_value = var.billing_code
}

resource "aws_service_discovery_private_dns_namespace" "penpot" {
  name        = "penpot.ecs.local"
  description = "DNS namespace used to provide service discovery for the Penpot ECS services"
  vpc         = module.penpot_vpc.vpc_id
  tags        = local.common_tags
}

#
# Security groups
#

# ECS
resource "aws_security_group" "penpot_ecs" {
  description = "NSG for Penpot ECS Tasks"
  name        = "penpot_ecs"
  vpc_id      = module.penpot_vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "penpot_ecs_egress_all" {
  type              = "egress"
  protocol          = "-1"
  to_port           = 0
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.penpot_ecs.id
}

resource "aws_security_group_rule" "penpot_ecs_ingress_lb" {
  description              = "Ingress from load balancer to Penpot ECS task"
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.penpot_ecs.id
  source_security_group_id = aws_security_group.penpot_lb.id
}

# Load balancer
resource "aws_security_group" "penpot_lb" {
  name        = "penpot_lb"
  description = "NSG for Penpot load balancer"
  vpc_id      = module.penpot_vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "penpot_lb_ingress_internet_http" {
  description       = "Ingress from internet to load balancer (HTTP)"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.penpot_lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "penpot_lb_ingress_internet_https" {
  description       = "Ingress from internet to load balancer (HTTPS)"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.penpot_lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "penpot_lb_egress_ecs" {
  description              = "Egress from load balancer to Penpot ECS task"
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.penpot_lb.id
  source_security_group_id = aws_security_group.penpot_ecs.id
}

# Database
resource "aws_security_group" "penpot_db" {
  name        = "penpot_db"
  description = "NSG for Penpot database"
  vpc_id      = module.penpot_vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "penpot_db_ingress_ecs" {
  description              = "Ingress from Penpot ECS task to database"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.penpot_db.id
  source_security_group_id = aws_security_group.penpot_ecs.id
}

# Redis
resource "aws_security_group" "penpot_redis" {
  name        = "penpot_redis"
  description = "NSG for Penpot Redis"
  vpc_id      = module.penpot_vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "penpot_redis_ingress_ecs" {
  description              = "Ingress from Penpot ECS task to redis"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.penpot_redis.id
  source_security_group_id = aws_security_group.penpot_ecs.id
}
