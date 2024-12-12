#
# RDS Postgress cluster
#
module "penpot_db" {
  source = "github.com/cds-snc/terraform-modules//rds?ref=v10.2.0"
  name   = "penpot-${var.env}"

  database_name  = "penpot"
  engine         = "aurora-postgresql"
  engine_version = "15.5"
  instances      = var.penpot_database_instances_count
  instance_class = var.penpot_database_instance_class
  username       = var.penpot_database_username
  password       = var.penpot_database_password

  backup_retention_period      = 14
  preferred_backup_window      = "02:00-04:00"
  performance_insights_enabled = true

  serverless_min_capacity = var.penpot_database_min_capacity
  serverless_max_capacity = var.penpot_database_max_capacity

  vpc_id             = module.penpot_vpc.vpc_id
  subnet_ids         = module.penpot_vpc.private_subnet_ids
  security_group_ids = [aws_security_group.penpot_db.id]

  billing_tag_value = var.billing_code
}

resource "aws_ssm_parameter" "penpot_database_username" {
  name  = "penpot_database_username"
  type  = "SecureString"
  value = var.penpot_database_username
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "penpot_database_password" {
  name  = "penpot_database_password"
  type  = "SecureString"
  value = var.penpot_database_password
  tags  = local.common_tags
}
