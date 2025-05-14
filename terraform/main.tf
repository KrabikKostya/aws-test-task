provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "wordpress-vpc"
  cidr = var.vpc_cidr
  azs = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  enable_dns_hostnames = true
  enable_dns_support = true
}

module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "wordpress-ec2-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = ["http-80-tcp", "ssh-tcp"]
  egress_rules  = ["all-all"]
}

module "db_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "wordpress-db-sg"
  vpc_id = module.vpc.vpc_id
  ingress_with_source_security_group_id = [{
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    source_security_group_id = module.ec2_sg.security_group_id
  }]
  egress_rules = ["all-all"]
}

module "redis_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "wordpress-redis-sg"
  vpc_id = module.vpc.vpc_id
  ingress_with_source_security_group_id = [{
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    source_security_group_id = module.ec2_sg.security_group_id
  }]
  egress_rules = ["all-all"]
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier           = "wordpress-db"
  engine               = "mysql"
  engine_version       = "8.0"
  major_engine_version = "8.0"
  family               = "mysql8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = var.db_name
  username             = var.db_user
  password             = var.db_password

  create_db_subnet_group    = true
  db_subnet_group_name      = "wordpress-db-subnet-group"
  subnet_ids                = module.vpc.private_subnets
  vpc_security_group_ids    = [module.db_sg.security_group_id]
  publicly_accessible       = false
  skip_final_snapshot       = true
}

resource "aws_elasticache_subnet_group" "wordpress" {
  name       = "wordpress-redis-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_elasticache_cluster" "wordpress" {
  cluster_id           = "wordpress-redis"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.wordpress.name
  security_group_ids   = [module.redis_sg.security_group_id]
}

resource "aws_instance" "wordpress" {
  ami = var.ami_id
  instance_type = "t2.micro"
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.ec2_sg.security_group_id]
  associate_public_ip_address = true
  key_name = var.key_pair_name

  user_data = templatefile("../scripts/wp-deploy.sh.tpl", {
    db_name    = var.db_name
    db_user    = var.db_user
    db_pass    = var.db_password
    db_host    = module.rds.db_instance_address
    redis_host = aws_elasticache_cluster.wordpress.cache_nodes[0].address
  })

  tags = {
    Name = "wordpress-server"
  }
}
