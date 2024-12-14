resource "aws_efs_file_system" "penpot" {
  # checkov:skip=CKV2_AWS_18: Automated EFS backups are enabled using aws_efs_backup_policy.penpot resource 
  encrypted = true
  tags = local.common_tags
}

resource "aws_efs_file_system_policy" "penpot" {
  file_system_id = aws_efs_file_system.penpot.id
  policy         = data.aws_iam_policy_document.penpot_efs_policy.json
}

data "aws_iam_policy_document" "penpot_efs_policy" {
  statement {
    sid    = "AllowAccessThroughAccessPoint"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]
    resources = [aws_efs_file_system.penpot.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values = [
        aws_efs_access_point.penpot.arn
      ]
    }
  }

  statement {
    sid       = "DenyNonSecureTransport"
    effect    = "Deny"
    actions   = ["*"]
    resources = [aws_efs_file_system.penpot.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

resource "aws_efs_backup_policy" "penpot" {
  file_system_id = aws_efs_file_system.penpot.id
  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "penpot" {
  count = local.availability_zones

  file_system_id = aws_efs_file_system.penpot.id
  subnet_id      = tolist(module.penpot_vpc.private_subnet_ids)[count.index]

  security_groups = [
    aws_security_group.penpot_efs.id
  ]
}

resource "aws_efs_access_point" "penpot" {
  file_system_id = aws_efs_file_system.penpot.id
  posix_user {
    gid = 1001
    uid = 1001
  }
  root_directory {
    path = "/opt/data/assets"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = 775
    }
  }
  tags = local.common_tags
}
