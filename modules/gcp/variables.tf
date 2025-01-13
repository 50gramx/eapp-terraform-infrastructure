variable "instance_type" {
  description = "Type of instance to create"
  type        = string
  default     = "e2-medium"
}

variable "ssh_public_key_file" {
  description = "Path to the SSH key file"
  type        = string
  default     = "/home/user/terraform/new/test/openvpn.pub"
}

variable "ssh_private_key_file" {
  description = "Path to the SSH private key file"
  type        = string
  default     = "/home/user/terraform/new/test/openvpn"
}

variable "zone" {
  description = "The GCP zone to deploy the resources in"
  type        = string
  default     = "us-central1-a"
}

variable "ovpn_users" {
  description = "List of OpenVPN users to be added"
  type        = list(string)
  default     = ["user1", "user2"]
}

variable "region" {
  description = "The GCP region to deploy the resources in"
  type        = string
  default     = "us-central1"
}