# ─────────────────────────────────────────────────────────────────────────────
#  Logging Module — Cloud Logging log bucket config
#  (replaces AWS CloudWatch log group)
# ─────────────────────────────────────────────────────────────────────────────

resource "google_logging_project_bucket_config" "backend_logs" {
  project        = var.project_id
  location       = "global"
  retention_days = var.log_retention_days
  bucket_id      = "much-to-do-backend-logs-${var.environment}"
  description    = "Much-To-Do backend application logs"
}
