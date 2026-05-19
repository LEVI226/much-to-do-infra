# ─────────────────────────────────────────────────────────────────────────────
#  Firewall Module — Least-privilege VPC firewall rules
# ─────────────────────────────────────────────────────────────────────────────

# Allow GCP Load Balancer health checks and traffic to reach backend VMs
resource "google_compute_firewall" "allow_lb_and_health_checks" {
  name    = "much-to-do-allow-lb-hc-${var.environment}"
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = [tostring(var.backend_port)]
  }

  # GCP Load Balancer and health check source ranges only — no 0.0.0.0/0
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["much-to-do-backend"]
}

# Allow Redis access within the private subnet only
resource "google_compute_firewall" "allow_redis_internal" {
  name    = "much-to-do-allow-redis-${var.environment}"
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["much-to-do-backend"]
}

# Allow SSH via IAP (gcloud compute ssh --tunnel-through-iap)
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "much-to-do-allow-iap-ssh-${var.environment}"
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["much-to-do-backend"]
}
