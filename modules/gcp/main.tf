# Static IP Address for Control Plane
resource "google_compute_address" "ethos_control_plane_ip" {
  name = "ethos-control-plane-ip"
}

# GCP Instance
resource "google_compute_instance" "ethos_control_plane" {
  name         = "ethos-control-plane"
  machine_type = var.instance_type
  zone         = var.zone
  tags         = ["ethos-control-plane", "terraform"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    network = "default"
    access_config {}  # This assigns an external IP address
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_file)}"
  }
}

# GCP Provisioning via SSH (OpenVPN, Microk8s install, etc.)
resource "null_resource" "openvpn_bootstrap" {
  depends_on = [google_compute_instance.ethos_control_plane]

  connection {
    type        = "ssh"
    host        = google_compute_instance.ethos_control_plane.network_interface[0].access_config[0].nat_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_file)
    agent       = false
  }

  provisioner "file" {
    source      = "/home/user/terraform/new/test/openvpn-install.sh"
    destination = "/home/ubuntu/openvpn-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/openvpn-install.sh",
      "sudo AUTO_INSTALL=y APPROVE_IP=y ENDPOINT=${google_compute_address.ethos_control_plane_ip.address} ./openvpn-install.sh"
    ]
  }
}

resource "null_resource" "microk8s_install_script_control_plane" {
  depends_on = [null_resource.openvpn_bootstrap]

  connection {
    type        = "ssh"
    host        = google_compute_instance.ethos_control_plane.network_interface[0].access_config[0].nat_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "file" {
    source      = "${path.module}/scripts/microk8s-install.sh"
    destination = "/home/ubuntu/microk8s-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/microk8s-install.sh",
      "sudo /home/ubuntu/microk8s-install.sh"
    ]
  }
}

resource "null_resource" "openvpn_update_users_script" {
  depends_on = [null_resource.openvpn_bootstrap]

  triggers = {
    ovpn_users = join(" ", var.ovpn_users)
  }

  connection {
    type        = "ssh"
    host        = google_compute_instance.ethos_control_plane.network_interface[0].access_config[0].nat_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "file" {
    source      = "${path.module}/scripts/update_users.sh"
    destination = "/home/ubuntu/update_users.sh"
  }

  provisioner "file" {
    source      = "/home/user/terraform/new/test/openvpn-install.sh"
    destination = "/home/ubuntu/openvpn-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/update_users.sh",
      "chmod +x /home/ubuntu/openvpn-install.sh",
      "export AUTO_INSTALL=y CLIENT=userOne",
      "timeout 600 sudo /home/ubuntu/update_users.sh ${join(" ", var.ovpn_users)}"
    ]
  }
}

resource "null_resource" "openvpn_download_configurations" {
  depends_on = [null_resource.openvpn_update_users_script]

  triggers = {
    ovpn_users = join(" ", var.ovpn_users)
  }

  provisioner "local-exec" {
    command = <<EOT
    mkdir -p generated/ovpn-config;
    scp -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -i ${var.ssh_private_key_file} ubuntu@${google_compute_instance.ethos_control_plane.network_interface[0].access_config[0].nat_ip}:/home/ubuntu/*.ovpn generated/ovpn-config/
    EOT
  }
}