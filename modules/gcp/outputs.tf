output "ethos_control_plane_public_ip" {
  value = google_compute_instance.ethos_control_plane.network_interface[0].access_config[0].nat_ip
}

output "ethos_control_plane_dns" {
  value = google_compute_instance.ethos_control_plane.network_interface[0].access_config[0].nat_ip
}

#output "ethos_control_plane_connection_string" {
#  value = "'ssh -i ${var.ssh_private_key_file} ubuntu@${google_compute_instance.ethos_control_plane.network_interface[0].access_config[0].nat_ip}'"
#}