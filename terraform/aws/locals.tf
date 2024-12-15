locals {
  common_tags = {
    Terraform  = "true"
    CostCentre = var.billing_code
  }
  ecs_services = [
    {
      name              = "frontend"
      port              = 8080
      health_check_path = "/"
    },
    {
      name              = "backend"
      port              = 6060
      health_check_path = "/readyz"
    },
    {
      name              = "exporter"
      port              = 6061
      health_check_path = "/readyz"
    }
  ]
}