variable "network_id" {
  description = "ID of the VPC network to attach firewall rules to"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR of the private subnet (used to restrict Redis access)"
  type        = string
}

variable "backend_port" {
  description = "Port the Go backend listens on"
  type        = number
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
