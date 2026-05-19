# ─── Global ─────────────────────────────────────────────────────────────────
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region to deploy all resources"
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "List of GCP zones (at least 2) within the region"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b"]
}

variable "environment" {
  description = "Deployment environment (e.g., prod, staging)"
  type        = string
  default     = "prod"
}

variable "github_repo" {
  description = "GitHub repo (owner/name) that will authenticate via WIF"
  type        = string
  default     = "LEVI226/much-to-do"
}

# ─── Networking ───────────────────────────────────────────────────────────────
variable "subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.0.0/24"
}

# ─── Compute ─────────────────────────────────────────────────────────────────
variable "vm_machine_type" {
  description = "GCE machine type for backend VMs"
  type        = string
  default     = "e2-small"
}

variable "mig_size" {
  description = "Target number of instances in the Managed Instance Group"
  type        = number
  default     = 2
}

variable "backend_port" {
  description = "Port the Go backend listens on"
  type        = number
  default     = 8080
}

# ─── Application Secrets (stored in Secret Manager, not committed) ────────────
variable "mongo_uri" {
  description = "MongoDB connection URI (MongoDB Atlas recommended)"
  type        = string
  sensitive   = true
}

variable "jwt_secret_key" {
  description = "JWT secret key for token signing"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "MongoDB database name"
  type        = string
  default     = "much_todo_db"
}

# ─── Memorystore / Redis ──────────────────────────────────────────────────────
variable "redis_memory_size_gb" {
  description = "Memory size in GB for Memorystore Redis instance"
  type        = number
  default     = 1
}

# ─── Cloud Logging ────────────────────────────────────────────────────────────
variable "log_retention_days" {
  description = "Number of days to retain logs in the Cloud Logging bucket"
  type        = number
  default     = 30
}
