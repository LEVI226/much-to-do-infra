# ─────────────────────────────────────────────────────────────────────────────
#  VPC Module — Custom VPC, private subnet, static NAT IP, Cloud Router, NAT
# ─────────────────────────────────────────────────────────────────────────────

resource "google_compute_network" "main" {
  name                    = "much-to-do-vpc-${var.environment}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "private" {
  name                     = "much-to-do-private-${var.environment}"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true
}

# Static external IP for Cloud NAT — add this to MongoDB Atlas allow-list
resource "google_compute_address" "nat_ip" {
  name         = "much-to-do-nat-ip-${var.environment}"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Static NAT IP — add to MongoDB Atlas Network Access allow-list"
}

resource "google_compute_router" "router" {
  name    = "much-to-do-router-${var.environment}"
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "much-to-do-nat-${var.environment}"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
