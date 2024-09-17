
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

#Output for new pod
output "pod_name" {
  description = "The name of the pod"
  value       = kubernetes_pod.pod.metadata[0].name
}

output "pod_image" {
  description = "The Docker image used for the pod"
  value       = kubernetes_pod.pod.spec[0].container[0].image
}

output "container_port" {
  description = "The container port exposed by the pod"
  value       = kubernetes_pod.pod.spec[0].container[0].ports[0].container_port
}