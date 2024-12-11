resource "aws_route53_zone" "penpot" {
  name = var.domain
  tags = local.common_tags
}

resource "aws_route53_record" "penpot_A" {
  zone_id = aws_route53_zone.penpot.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_lb.penpot.dns_name
    zone_id                = aws_lb.penpot.zone_id
    evaluate_target_health = false
  }
}
