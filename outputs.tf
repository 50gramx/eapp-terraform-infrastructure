# output "cluster_endpoint" {
#   description = "Endpoint for EKS control plane"
#   value       = module.eks_cluster.cluster_endpoint
# }

# output "cluster_security_group_id" {
#   description = "Security group ids attached to the cluster control plane"
#   value       = module.eks_cluster.cluster_security_group_id
# }

# output "region" {
#   description = "AWS region"
#   value       = var.region
# }

# output "cluster_name" {
#   description = "Kubernetes Cluster Name"
#   value       = module.eks_cluster.cluster_name
# }


output "ethos_control_plane_public_ip" {
  value = module.microk8s.ethos_control_plane_public_ip
}

output "ethos_control_plane_dns" {
  value = module.microk8s.ethos_control_plane_dns
}

output "ethos_control_plane_connection_string" {
  value = module.microk8s.ethos_control_plane_connection_string
}

output "ethos_worker_node_public_ip" {
  value = module.microk8s.ethos_worker_node_public_ip
}

output "ethos_worker_node_dns" {
  value = module.microk8s.ethos_worker_node_dns
}

output "ethos_worker_node_connection_string" {
  value = module.microk8s.ethos_worker_node_connection_string
}