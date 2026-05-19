variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo (owner/name) to allow WIF authentication from"
  type        = string
}
