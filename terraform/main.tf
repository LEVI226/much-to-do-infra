terraform {
  required_version = ">= 1.7"

  backend "s3" {
    bucket         = "much-to-do-tfstate-alt-soe-025-1318"
    key            = "much-to-do/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "much-to-do-tflock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "baraka-2025-much-to-do"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
