locals {
  availability_zones = 2
  common_tags = {
    Terraform  = "true"
    CostCentre = var.billing_code
  }
  ecs_services = [
    {
      name      = "frontend"
      port      = 8080
      lb_tg_arn = aws_lb_target_group.penpot.arn
    },
    {
      name      = "backend"
      port      = 6060
      lb_tg_arn = aws_lb_target_group.penpot_backend.arn
    },
    {
      name      = "exporter"
      port      = 6061
      lb_tg_arn = aws_lb_target_group.penpot_exporter.arn
    }
  ]
}