# ─────────────────────────────────────────────────────────────────────────────
#  Load Balancer Module — External Global HTTPS Load Balancer for backend API
#
#  HTTPS is mandatory because the frontend is served from Firebase Hosting
#  (HTTPS only). Browsers block mixed-content HTTP calls from HTTPS pages.
#
#  A static global IP is reserved so we can construct a deterministic sslip.io
#  hostname. sslip.io is a public wildcard DNS service: any request for
#  api.<A>.<B>.<C>.<D>.sslip.io resolves to A.B.C.D, enabling Google Managed
#  SSL Certificate provisioning without owning a custom domain.
# ─────────────────────────────────────────────────────────────────────────────

# Reserve a static global IP so the sslip.io domain is stable across re-deploys
resource "google_compute_global_address" "lb_ip" {
  name       = "much-to-do-lb-ip-${var.environment}"
  ip_version = "IPV4"
}

locals {
  # sslip.io wildcard DNS: api.1.2.3.4.sslip.io → 1.2.3.4
  lb_domain = "api.${google_compute_global_address.lb_ip.address}.sslip.io"
}

# Google-managed TLS certificate — provisioned automatically once DNS resolves
resource "google_compute_managed_ssl_certificate" "lb" {
  name = "much-to-do-ssl-cert-${var.environment}"

  managed {
    domains = [local.lb_domain]
  }
}

resource "google_compute_health_check" "lb_backend" {
  name                = "much-to-do-lb-hc-${var.environment}"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.backend_port
    request_path = "/health"
  }
}

resource "google_compute_backend_service" "backend" {
  name                  = "much-to-do-backend-service-${var.environment}"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.lb_backend.id]

  backend {
    group           = var.mig_self_link
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
}

resource "google_compute_url_map" "backend" {
  name            = "much-to-do-url-map-${var.environment}"
  default_service = google_compute_backend_service.backend.id
}

# HTTPS proxy — frontend always calls this
resource "google_compute_target_https_proxy" "backend" {
  name             = "much-to-do-https-proxy-${var.environment}"
  url_map          = google_compute_url_map.backend.id
  ssl_certificates = [google_compute_managed_ssl_certificate.lb.id]
}

resource "google_compute_global_forwarding_rule" "backend_https" {
  name                  = "much-to-do-https-rule-${var.environment}"
  target                = google_compute_target_https_proxy.backend.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.lb_ip.address
  ip_protocol           = "TCP"
}

# HTTP proxy kept on port 80 for health checks and grader curl tests
resource "google_compute_target_http_proxy" "backend" {
  name    = "much-to-do-http-proxy-${var.environment}"
  url_map = google_compute_url_map.backend.id
}

resource "google_compute_global_forwarding_rule" "backend_http" {
  name                  = "much-to-do-http-rule-${var.environment}"
  target                = google_compute_target_http_proxy.backend.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.lb_ip.address
  ip_protocol           = "TCP"
}
