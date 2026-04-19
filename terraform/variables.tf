variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "much-to-do-vpc"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_suffix" {
  description = "Unique suffix for globally unique resource names"
  type        = string
  default     = "alt-soe-025-1318"
}

variable "backend_instance_type" {
  description = "EC2 instance type for backend servers"
  type        = string
  default     = "t3.micro"
}

variable "mongodb_instance_type" {
  description = "EC2 instance type for MongoDB"
  type        = string
  default     = "t3.small"
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "mongo_db_name" {
  description = "MongoDB database name"
  type        = string
  default     = "muchtodo"
}

variable "jwt_secret_key" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
  default     = "change-me-in-production-secrets-manager"
}

variable "developer_username" {
  description = "IAM username for the grader/developer view user"
  type        = string
  default     = "muchtodo-dev-view"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}
