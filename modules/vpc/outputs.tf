output "network_id" {
  description = "Self-link ID of the VPC network"
  value       = google_compute_network.main.id
}

output "network_self_link" {
  description = "Self-link of the VPC network"
  value       = google_compute_network.main.self_link
}

output "subnet_id" {
  description = "Self-link ID of the private subnet"
  value       = google_compute_subnetwork.private.id
}

output "nat_ip_address" {
  description = "Static external IP used for Cloud NAT (add to MongoDB Atlas allow-list)"
  value       = google_compute_address.nat_ip.address
}
