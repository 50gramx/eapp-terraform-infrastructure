terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.14.0"
    }
  }
}

provider "google" {
  project     = "terraform-007143"
  region      = var.region
  zone        = var.zone
  credentials = file("/home/user/Downloads/terraform-007143-f08ca083236b.json")
}