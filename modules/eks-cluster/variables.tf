variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "ethos-cluster"
}

variable "instance_type" {
  description = "EKS Cluster Instance Types"
  type        = string
  default     = "t3.small"
}