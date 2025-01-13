# VPC
resource "google_compute_network" "ethos_vpc" {
  name                    = "ethos-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Subnet
resource "google_compute_subnetwork" "ethos_subnet" {
  name          = "ethos-subnet"
  region        = var.region
  network       = google_compute_network.ethos_vpc.id
  ip_cidr_range = "10.0.0.0/24"
}

# Router
resource "google_compute_router" "ethos_router" {
  name    = "ethos-router"
  region  = var.region
  network = google_compute_network.ethos_vpc.id
}

resource "google_compute_router_nat" "ethos_nat" {
  name                    = "ethos-nat"
  router                  = google_compute_router.ethos_router.name
  region                  = var.region
  nat_ip_allocate_option  = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_route" "ethos_route" {
  name            = "ethos-default-route"
  network         = google_compute_network.ethos_vpc.id
  dest_range      = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
}

resource "google_compute_firewall" "ethos_sg" {
  name    = "ethos-sg"
  network = google_compute_network.ethos_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "16443", "943", "25000"]
  }

  allow {
    protocol = "udp"
    ports    = ["1194"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]  # Restrict this in production
  target_tags = ["ethos-vm", "ethos-control-plane"]
}