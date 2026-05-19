output "backend_sa_email" {
  description = "Email of the backend VM runtime service account"
  value       = google_service_account.backend_vm.email
}

output "deployer_sa_email" {
  description = "Email of the GitHub Actions deployer service account"
  value       = google_service_account.github_deployer.email
}

output "grader_sa_email" {
  description = "Email of the grader read-only service account"
  value       = google_service_account.grader.email
}

output "wif_provider" {
  description = "Full resource name of the WIF provider (for GitHub Actions secret)"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "wif_pool_name" {
  description = "Full resource name of the WIF pool"
  value       = google_iam_workload_identity_pool.github.name
}
