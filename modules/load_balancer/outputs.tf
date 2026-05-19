output "lb_ip" {
  description = "Static external IP of the backend load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "lb_domain" {
  description = "sslip.io hostname for the backend LB (resolves to lb_ip)"
  value       = local.lb_domain
}

output "backend_https_url" {
  description = "Backend API HTTPS URL — use as VITE_API_BASE_URL"
  value       = "https://${local.lb_domain}"
}

output "backend_service_name" {
  description = "Name of the backend service (for health check verification)"
  value       = google_compute_backend_service.backend.name
}

output "url_map_name" {
  description = "Name of the URL map"
  value       = google_compute_url_map.backend.name
}
