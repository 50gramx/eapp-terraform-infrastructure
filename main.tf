provider "aws" {
  region = var.region
}

# resource "random_string" "suffix" {
#   length  = 8
#   special = false
# }

# locals {
#   cluster_name = "ethos-eks-${random_string.suffix.result}"
# }

# module "eks_cluster" {
#     source = "./modules/eks-cluster"
#     cluster_name = local.cluster_name
#     instance_type = "t3.small"
#     region = var.region
# }

module "microk8s" {
  source = "./modules/microk8s"
  region = var.region
  ami = "ami-0f58b397bc5c1f2e8"
  instance_type = "t3.medium"
  ssh_public_key_file="settings/openvpn.pub"
  ssh_private_key_file = "settings/openvpn"
  ovpn_users = ["node1"]
}
