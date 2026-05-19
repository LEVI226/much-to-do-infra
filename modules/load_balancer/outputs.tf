output "lb_ip" {
  description = "External IP address of the backend API load balancer"
  value       = google_compute_global_forwarding_rule.backend.ip_address
}

output "backend_service_name" {
  description = "Name of the backend service (for health check verification)"
  value       = google_compute_backend_service.backend.name
}

output "url_map_name" {
  description = "Name of the URL map"
  value       = google_compute_url_map.backend.name
}
