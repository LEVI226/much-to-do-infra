# ─────────────────────────────────────────────────────────────────────────────
#  Compute Module — Regional Managed Instance Group (MIG)
# ─────────────────────────────────────────────────────────────────────────────

locals {
  startup_script = templatefile("${path.module}/../../scripts/startup.sh", {
    environment         = var.environment
    mongo_uri_secret_id = var.mongo_uri_secret_id
    jwt_secret_id       = var.jwt_secret_id
    redis_host          = var.redis_host
    db_name             = var.db_name
    backend_port        = var.backend_port
    project_id          = var.project_id
  })
}

resource "google_compute_instance_template" "backend" {
  name_prefix  = "much-to-do-backend-${var.environment}-"
  machine_type = var.vm_machine_type
  region       = var.region
  tags         = ["much-to-do-backend"]

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-balanced"
  }

  network_interface {
    subnetwork = var.subnet_id
    # No access_config = no external IP; egress via Cloud NAT
  }

  service_account {
    email  = var.backend_sa_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = local.startup_script
    enable-oslogin = "TRUE"
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Autohealing health check (separate from LB health check to avoid circular dep)
resource "google_compute_health_check" "backend_autohealing" {
  name                = "much-to-do-autohealing-hc-${var.environment}"
  check_interval_sec  = 30
  timeout_sec         = 10
  healthy_threshold   = 1
  unhealthy_threshold = 3

  http_health_check {
    port         = var.backend_port
    request_path = "/health"
  }
}

resource "google_compute_region_instance_group_manager" "backend" {
  name               = "much-to-do-mig-${var.environment}"
  region             = var.region
  base_instance_name = "much-to-do-backend"
  target_size        = var.mig_size

  distribution_policy_zones = var.zones

  version {
    instance_template = google_compute_instance_template.backend.id
  }

  named_port {
    name = "http"
    port = var.backend_port
  }

  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 1
    max_unavailable_fixed        = 0
    replacement_method           = "SUBSTITUTE"
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.backend_autohealing.id
    initial_delay_sec = 300
  }

  lifecycle {
    create_before_destroy = true
  }
}
