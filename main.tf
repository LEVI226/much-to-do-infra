# ─────────────────────────────────────────────────────────────────────────────
#  Much-To-Do — Root Module (GCP)
#  Wires together all child modules for the production infrastructure
# ─────────────────────────────────────────────────────────────────────────────

# ── 1. Networking (VPC, Subnet, static NAT IP, Cloud Router, Cloud NAT) ───────
module "vpc" {
  source = "./modules/vpc"

  project_id  = var.project_id
  region      = var.region
  subnet_cidr = var.subnet_cidr
  environment = var.environment
}

# ── 2. Firewall Rules ─────────────────────────────────────────────────────────
module "firewall" {
  source = "./modules/firewall"

  network_id   = module.vpc.network_id
  subnet_cidr  = var.subnet_cidr
  backend_port = var.backend_port
  environment  = var.environment
}

# ── 3. IAM — Service Accounts + Workload Identity Federation ──────────────────
module "iam" {
  source = "./modules/iam"

  project_id  = var.project_id
  environment = var.environment
  github_repo = var.github_repo
}

# ── 4. Secret Manager ─────────────────────────────────────────────────────────
module "secrets" {
  source = "./modules/secrets"

  project_id      = var.project_id
  environment     = var.environment
  mongo_uri       = var.mongo_uri
  jwt_secret_key  = var.jwt_secret_key
  backend_sa_email = module.iam.backend_sa_email
}

# ── 5. Memorystore Redis ──────────────────────────────────────────────────────
module "memorystore" {
  source = "./modules/memorystore"

  region         = var.region
  network_id     = module.vpc.network_id
  memory_size_gb = var.redis_memory_size_gb
  environment    = var.environment
}

# ── 6. Cloud Logging ──────────────────────────────────────────────────────────
module "logging" {
  source = "./modules/logging"

  project_id         = var.project_id
  environment        = var.environment
  log_retention_days = var.log_retention_days
}

# ── 7. Compute — Managed Instance Group (MIG) ─────────────────────────────────
module "compute" {
  source = "./modules/compute"

  project_id          = var.project_id
  region              = var.region
  subnet_id           = module.vpc.subnet_id
  vm_machine_type     = var.vm_machine_type
  mig_size            = var.mig_size
  zones               = var.zones
  backend_port        = var.backend_port
  backend_sa_email    = module.iam.backend_sa_email
  mongo_uri_secret_id = module.secrets.mongo_uri_secret_id
  jwt_secret_id       = module.secrets.jwt_secret_id
  redis_host          = module.memorystore.redis_host
  db_name             = var.db_name
  environment         = var.environment

  depends_on = [
    module.secrets,
    module.memorystore,
  ]
}

# ── 8. External HTTP Load Balancer (Backend API) ──────────────────────────────
module "load_balancer" {
  source = "./modules/load_balancer"

  backend_port   = var.backend_port
  mig_self_link  = module.compute.mig_self_link
  environment    = var.environment
}
