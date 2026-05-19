# ─────────────────────────────────────────────────────────────────────────────
#  IAM Module — Service Accounts + Workload Identity Federation
# ─────────────────────────────────────────────────────────────────────────────

# ── Service Account 1: Backend VM runtime ─────────────────────────────────────
resource "google_service_account" "backend_vm" {
  project      = var.project_id
  account_id   = "much-to-do-backend-${var.environment}"
  display_name = "Much-To-Do Backend Runtime"
}

resource "google_project_iam_member" "backend_sm_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.backend_vm.email}"
}

resource "google_project_iam_member" "backend_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.backend_vm.email}"
}

resource "google_project_iam_member" "backend_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.backend_vm.email}"
}

# ── Service Account 2: GitHub Actions deployer ────────────────────────────────
resource "google_service_account" "github_deployer" {
  project      = var.project_id
  account_id   = "much-to-do-deployer"
  display_name = "Much-To-Do GitHub Actions Deployer"
}

resource "google_project_iam_member" "deployer_compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_iap_tunnel" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_firebase_admin" {
  project = var.project_id
  role    = "roles/firebase.admin"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

# ── Service Account 3: Grader (read-only) ────────────────────────────────────
resource "google_service_account" "grader" {
  project      = var.project_id
  account_id   = "muchtodo-dev-view"
  display_name = "MuchToDo Grader Read-Only"
}

resource "google_project_iam_member" "grader_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.grader.email}"
}

resource "google_project_iam_member" "grader_log_viewer" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.grader.email}"
}

resource "google_project_iam_member" "grader_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.grader.email}"
}

resource "google_project_iam_member" "grader_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.grader.email}"
}

# ── Workload Identity Federation — GitHub Actions ─────────────────────────────
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool-${var.environment}"
  display_name              = "GitHub Actions Pool"
  description               = "WIF pool for GitHub Actions CI/CD"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "attribute.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "wif_deployer_binding" {
  service_account_id = google_service_account.github_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}
