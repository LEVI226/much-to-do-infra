output "log_bucket_name" {
  description = "Cloud Logging bucket ID for the backend application logs"
  value       = google_logging_project_bucket_config.backend_logs.bucket_id
}
