output "mig_name" {
  description = "Name of the Regional Managed Instance Group"
  value       = google_compute_region_instance_group_manager.backend.name
}

output "mig_self_link" {
  description = "Self-link of the MIG's instance group (for load balancer backend)"
  value       = google_compute_region_instance_group_manager.backend.instance_group
}

output "instance_template_name" {
  description = "Name of the current instance template"
  value       = google_compute_instance_template.backend.name
}
