# ─────────────────────────────────────────────────────────────────────────────
#  Secrets Module — Secret Manager with per-secret IAM bindings
# ─────────────────────────────────────────────────────────────────────────────

resource "google_secret_manager_secret" "mongo_uri" {
  project   = var.project_id
  secret_id = "much-to-do-mongo-uri-${var.environment}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "mongo_uri" {
  secret      = google_secret_manager_secret.mongo_uri.id
  secret_data = var.mongo_uri
}

resource "google_secret_manager_secret_iam_member" "backend_mongo_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.mongo_uri.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.backend_sa_email}"
}

resource "google_secret_manager_secret" "jwt_secret" {
  project   = var.project_id
  secret_id = "much-to-do-jwt-secret-${var.environment}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = var.jwt_secret_key
}

resource "google_secret_manager_secret_iam_member" "backend_jwt_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.jwt_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.backend_sa_email}"
}
