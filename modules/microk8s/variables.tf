
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "ssh_public_key_file" {
  # Generate via 'ssh-keygen -f openvpn -t rsa'
  description = "The public SSH key to store in the EC2 instance"
  default     = "settings/openvpn.pub"
}

variable "ssh_private_key_file" {
  # Generate via 'ssh-keygen -f openvpn -t rsa'
  description = "The private SSH key used to connect to the EC2 instance"
  default     = "settings/openvpn"
}

variable "ami" {
  description = "AMI for the ec2 cluster"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8"
}

variable "instance_type" {
  description = "EC2 Instance Types"
  type        = string
  default     = "t2.micro"
}

variable "ovpn_users" {
  type        = list(string)
  description = "The list of users to automatically provision with OpenVPN access"
}

# variable for additinal pod
variable "pod_name" {
  description = "Name of the Kubernetes pod"
  type        = string
  default     = "my-nginx-pod"  # You can set a default value or omit it
}

variable "pod_image" {
  description = "Docker image for the Kubernetes pod"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port to expose on the container"
  type        = number
  default     = 80
}
