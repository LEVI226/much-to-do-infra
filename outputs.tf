output "vpc_id" {
  description = "VPC network ID"
  value       = module.vpc.network_id
}

output "nat_ip_address" {
  description = "Static NAT IP — add this to MongoDB Atlas Network Access allow-list"
  value       = module.vpc.nat_ip_address
}

output "backend_lb_ip" {
  description = "Static external IP of the backend load balancer"
  value       = module.load_balancer.lb_ip
}

output "backend_lb_domain" {
  description = "sslip.io hostname for the backend LB"
  value       = module.load_balancer.lb_domain
}

output "backend_https_url" {
  description = "Backend API HTTPS URL — use as VITE_API_BASE_URL in GitHub Actions"
  value       = module.load_balancer.backend_https_url
}

output "firebase_hosting_url" {
  description = "Firebase Hosting URL for the frontend SPA"
  value       = "https://${var.project_id}.web.app"
}

output "mig_name" {
  description = "Name of the backend Managed Instance Group"
  value       = module.compute.mig_name
}

output "redis_host" {
  description = "Memorystore Redis host:port endpoint (internal)"
  value       = module.memorystore.redis_host
}

output "log_bucket_name" {
  description = "Cloud Logging log bucket name"
  value       = module.logging.log_bucket_name
}

output "wif_provider" {
  description = "Workload Identity Provider resource name (for GitHub Actions secret)"
  value       = module.iam.wif_provider
}

output "backend_runtime_service_account" {
  description = "Email of the backend VM runtime service account"
  value       = module.iam.backend_sa_email
}

output "github_deployer_service_account" {
  description = "Email of the GitHub Actions deployer service account"
  value       = module.iam.deployer_sa_email
}

output "grader_service_account" {
  description = "Email of the read-only grader service account"
  value       = module.iam.grader_sa_email
}

output "post_deploy_instructions" {
  description = "Manual steps required after first deployment"
  value       = <<-EOT
    ─── Post-Deploy Checklist ────────────────────────────────────────────────
    1. Add NAT IP to MongoDB Atlas allow-list:
       nat_ip_address = ${module.vpc.nat_ip_address}

    2. Wait for SSL certificate to provision (~15-60 min after DNS propagation):
       gcloud compute ssl-certificates describe much-to-do-ssl-cert-prod \
         --global --format="get(managed.status,managed.domainStatus)"

    3. Set GitHub Actions secrets in LEVI226/much-to-do:
       GCP_PROJECT_ID          = ${var.project_id}
       GCP_REGION              = ${var.region}
       WIF_PROVIDER            = ${module.iam.wif_provider}
       DEPLOYER_SA_EMAIL       = ${module.iam.deployer_sa_email}
       MIG_NAME                = ${module.compute.mig_name}
       VITE_API_BASE_URL       = ${module.load_balancer.backend_https_url}
       FIREBASE_PROJECT_ID     = ${var.project_id}

    4. Deploy Firebase Hosting:
       firebase deploy --only hosting --project ${var.project_id}

    5. Test backend HTTPS endpoint:
       curl https://${module.load_balancer.lb_domain}/health

    6. Provide grader credentials (read-only):
       gcloud iam service-accounts keys create grader-key.json \
         --iam-account=${module.iam.grader_sa_email} \
         --project=${var.project_id}
    ──────────────────────────────────────────────────────────────────────────
  EOT
}
