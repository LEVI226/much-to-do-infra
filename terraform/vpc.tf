module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Public subnets — ALB lives here
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  # Private app subnets — backend EC2 instances
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  # Private data subnets — MongoDB + ElastiCache
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true
  enable_dns_support     = true
  create_database_subnet_group = true

  public_subnet_tags = {
    "Tier" = "public"
  }

  private_subnet_tags = {
    "Tier" = "private-app"
  }

  database_subnet_tags = {
    "Tier" = "private-data"
  }

  tags = {
    Name = var.vpc_name
  }
}
