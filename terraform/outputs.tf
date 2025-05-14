output "ec2_public_ip" {
  value = aws_instance.wordpress.public_ip
}

output "rds_endpoint" {
  value = module.rds.db_instance_address
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.wordpress.cache_nodes[0].address
}

