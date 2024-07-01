
output "ethos_control_plane_public_ip" {
  value = aws_eip.ethos_control_place_eip.public_ip
}

output "ethos_control_plane_dns" {
  value = aws_eip.ethos_control_place_eip.public_dns
}

output "ethos_control_plane_connection_string" {
  value = "'ssh -i ${var.ssh_private_key_file} ec2-user@${aws_eip.ethos_control_place_eip.public_dns}'"
}

output "ethos_worker_node_public_ip" {
  value = aws_eip.ethos_worker_node1_eip.public_ip
}

output "ethos_worker_node_dns" {
  value = aws_eip.ethos_worker_node1_eip.public_dns
}

output "ethos_worker_node_connection_string" {
  value = "'ssh -i ${var.ssh_private_key_file} ec2-user@${aws_eip.ethos_worker_node1_eip.public_dns}'"
}