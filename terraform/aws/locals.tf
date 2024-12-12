locals {
  common_tags = {
    Terraform  = "true"
    CostCentre = var.billing_code
  }
  ecs_services = [
    {
      name = "frontend"
      port = 8080
    },
    {
      name = "backend"
      port = 6060
    },
    {
      name = "exporter"
      port = 6061
    }
  ]
}