variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "ami_id" {
  type = string
}

variable "key_pair_name" {
  type = string
}
