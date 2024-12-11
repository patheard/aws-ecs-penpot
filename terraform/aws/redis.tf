resource "aws_elasticache_cluster" "penpot" {
  cluster_id           = "penpot-${var.env}"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.penpot.name

  security_group_ids = [
    aws_security_group.penpot_redis.id,
  ]

  tags = local.common_tags
}

resource "aws_elasticache_subnet_group" "penpot" {
  name       = "penpot-${var.env}"
  subnet_ids = module.penpot_vpc.private_subnet_ids
}
