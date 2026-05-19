variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
