output "lb_firewall_name" {
  description = "Name of the LB + health check firewall rule"
  value       = google_compute_firewall.allow_lb_and_health_checks.name
}

output "iap_ssh_firewall_name" {
  description = "Name of the IAP SSH firewall rule"
  value       = google_compute_firewall.allow_iap_ssh.name
}
