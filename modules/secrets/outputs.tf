output "mongo_uri_secret_id" {
  description = "Secret Manager secret ID for MongoDB URI (not the value)"
  value       = google_secret_manager_secret.mongo_uri.secret_id
}

output "jwt_secret_id" {
  description = "Secret Manager secret ID for JWT secret (not the value)"
  value       = google_secret_manager_secret.jwt_secret.secret_id
}
