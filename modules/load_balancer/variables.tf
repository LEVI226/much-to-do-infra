variable "backend_port" {
  description = "Port the Go backend listens on"
  type        = number
}

variable "mig_self_link" {
  description = "Self-link of the MIG's instance group"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
