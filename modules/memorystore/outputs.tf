output "redis_host" {
  description = "Memorystore Redis host:port endpoint (e.g., 10.x.x.x:6379)"
  value       = "${google_redis_instance.redis.host}:${google_redis_instance.redis.port}"
}
