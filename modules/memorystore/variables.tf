variable "region" {
  description = "GCP region for the Memorystore Redis instance"
  type        = string
}

variable "network_id" {
  description = "ID of the VPC network to authorize for the Redis instance"
  type        = string
}

variable "memory_size_gb" {
  description = "Memory size in GB for the Redis instance"
  type        = number
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
