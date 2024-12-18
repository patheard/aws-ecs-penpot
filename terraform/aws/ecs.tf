locals {
  container_env = [
    {
      "name"  = "PENPOT_ASSETS_STORAGE_BACKEND"
      "value" = "assets-s3"
    },
    {
      "name"  = "PENPOT_BACKEND_URI"
      "value" = "https://${var.domain}"
    },
    {
      "name"  = "PENPOT_DATABASE_URI"
      "value" = "postgresql://${module.penpot_db.proxy_endpoint}/penpot"
    },
    {
      "name"  = "PENPOT_EXPORTER_URI"
      "value" = "https://${var.domain}"
    },
    {
      "name"  = "PENPOT_FLAGS"
      "value" = "enable-login-with-google enable-demo-warning enable-registration enable-cors disable-login-with-password disable-smpt disable-email-verification"
    },
    {
      "name"  = "PENPOT_INTERNAL_RESOLVER"
      "value" = "169.254.169.253"
    },
    {
      "name"  = "PENPOT_PUBLIC_URI"
      "value" = "https://${var.domain}"
    },
    {
      "name"  = "PENPOT_REDIS_URI"
      "value" = "redis://${aws_elasticache_cluster.penpot.cache_nodes[0]["address"]}/0"
    },
    {
      "name"  = "PENPOT_STORAGE_ASSETS_S3_BUCKET"
      "value" = module.penpot_asset_bucket.s3_bucket_id
    },
    {
      "name"  = "PENPOT_STORAGE_ASSETS_S3_REGION"
      "value" = var.region
    },
  ]
  container_secrets = [
    {
      "name"      = "PENPOT_DATABASE_PASSWORD"
      "valueFrom" = aws_ssm_parameter.penpot_database_password.arn
    },
    {
      "name"      = "PENPOT_DATABASE_USERNAME"
      "valueFrom" = aws_ssm_parameter.penpot_database_username.arn
    },
    {
      "name"      = "PENPOT_GOOGLE_CLIENT_ID"
      "valueFrom" = aws_ssm_parameter.penpot_google_oauth_client_id.arn
    },
    {
      "name"      = "PENPOT_GOOGLE_CLIENT_SECRET"
      "valueFrom" = aws_ssm_parameter.penpot_google_oauth_client_secret.arn
    },
    {
      "name"      = "PENPOT_SECRET_KEY"
      "valueFrom" = aws_ssm_parameter.penpot_secret_key.arn
    }
  ]
}


resource "aws_ecs_cluster" "penpot" {
  name = "penpot"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "penpot" {
  cluster_name = aws_ecs_cluster.penpot.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

module "penpot_ecs" {
  for_each = { for service in local.ecs_services : service.name => service }

  source = "github.com/cds-snc/terraform-modules//ecs?ref=v10.2.1"

  create_cluster = false
  cluster_name   = aws_ecs_cluster.penpot.name
  service_name   = each.value.name
  task_cpu       = 2048
  task_memory    = 4096

  # Scaling
  enable_autoscaling       = true
  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 2

  # Task definition
  container_image                     = "${aws_ecr_repository.penpot[each.value.name].repository_url}:latest"
  container_host_port                 = each.value.port
  container_port                      = each.value.port
  container_environment               = local.container_env
  container_secrets                   = local.container_secrets
  container_read_only_root_filesystem = false

  task_exec_role_policy_documents = [
    data.aws_iam_policy_document.ecs_task_ssm_parameters.json
  ]
  task_role_policy_documents = [
    data.aws_iam_policy_document.ecs_task_create_tunnel.json,
    data.aws_iam_policy_document.s3_assets_manage.json
  ]

  # Networking
  lb_target_group_arn    = aws_lb_target_group.penpot_tg[each.value.name].arn
  subnet_ids             = module.penpot_vpc.private_subnet_ids
  security_group_ids     = [aws_security_group.penpot_ecs.id]
  enable_execute_command = true

  billing_tag_value = var.billing_code
}

#
# IAM policies
#
data "aws_iam_policy_document" "ecs_task_ssm_parameters" {
  statement {
    sid    = "GetSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.penpot_google_oauth_client_id.arn,
      aws_ssm_parameter.penpot_google_oauth_client_secret.arn,
      aws_ssm_parameter.penpot_secret_key.arn,
      aws_ssm_parameter.penpot_database_username.arn,
      aws_ssm_parameter.penpot_database_password.arn,
    ]
  }
}

data "aws_iam_policy_document" "s3_assets_manage" {
  statement {
    sid    = "S3AssetsManage"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      module.penpot_asset_bucket.s3_bucket_arn,
      "${module.penpot_asset_bucket.s3_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "ecs_task_create_tunnel" {
  statement {
    sid    = "CreateSSMTunnel"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

#
# SSM parameters
#
resource "aws_ssm_parameter" "penpot_google_oauth_client_id" {
  name  = "penpot_google_oauth_client_id"
  type  = "SecureString"
  value = var.penpot_google_oauth_client_id
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "penpot_google_oauth_client_secret" {
  name  = "penpot_google_oauth_client_secret"
  type  = "SecureString"
  value = var.penpot_google_oauth_client_secret
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "penpot_secret_key" {
  name  = "penpot_secret_key"
  type  = "SecureString"
  value = var.penpot_secret_key
  tags  = local.common_tags
}
