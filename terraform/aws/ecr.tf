resource "aws_ecr_repository" "penpot" {
  for_each = { for service in local.ecs_services : service.name => service }

  name                 = "penpot-${each.value.name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "penpot" {
  for_each = { for service in local.ecs_services : service.name => service }

  repository = aws_ecr_repository.penpot[each.value.name].name
  policy     = <<-EOT
  {
    "rules": [
        {
            "rulePriority": 10,
            "description": "Keep last 10 git SHA tagged images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": [
                    "sha-"
                ],
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 20,
            "description": "Expire untagged images older than 7 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 7
            },
            "action": {
                "type": "expire"
            }
        }
    ]
  }
  EOT
}
