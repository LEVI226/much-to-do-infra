# ─────────────────────────────────────────────────────────────────────────────
#  Load Balancer Module — External Global HTTP Load Balancer for backend API
# ─────────────────────────────────────────────────────────────────────────────

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

resource "google_compute_target_http_proxy" "backend" {
  name    = "much-to-do-http-proxy-${var.environment}"
  url_map = google_compute_url_map.backend.id
}

resource "google_compute_global_forwarding_rule" "backend" {
  name                  = "much-to-do-forwarding-rule-${var.environment}"
  target                = google_compute_target_http_proxy.backend.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
}
