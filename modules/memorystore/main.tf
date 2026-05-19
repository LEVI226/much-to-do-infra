# ─────────────────────────────────────────────────────────────────────────────
#  Memorystore Module — Managed Redis 7.0 (replaces AWS ElastiCache)
# ─────────────────────────────────────────────────────────────────────────────

resource "google_redis_instance" "redis" {
  name               = "much-to-do-redis-${var.environment}"
  tier               = "BASIC"
  memory_size_gb     = var.memory_size_gb
  region             = var.region
  authorized_network = var.network_id
  redis_version      = "REDIS_7_0"
  display_name       = "Much-To-Do Redis ${var.environment}"
  connect_mode       = "DIRECT_PEERING"
}
