variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the MIG"
  type        = string
  default     = "us-central1"
}

variable "subnet_id" {
  description = "Self-link ID of the private subnet"
  type        = string
}

variable "vm_machine_type" {
  description = "GCE machine type (e.g., e2-small)"
  type        = string
}

variable "mig_size" {
  description = "Target number of instances in the MIG"
  type        = number
  default     = 2
}

variable "zones" {
  description = "List of GCP zones for instance distribution (at least 2)"
  type        = list(string)
}

variable "backend_port" {
  description = "Port the Go backend listens on"
  type        = number
}

variable "backend_sa_email" {
  description = "Email of the backend VM runtime service account"
  type        = string
}

variable "mongo_uri_secret_id" {
  description = "Secret Manager secret ID for the MongoDB URI"
  type        = string
}

variable "jwt_secret_id" {
  description = "Secret Manager secret ID for the JWT secret key"
  type        = string
}

variable "redis_host" {
  description = "Memorystore Redis host endpoint (without port)"
  type        = string
}

variable "db_name" {
  description = "MongoDB database name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
