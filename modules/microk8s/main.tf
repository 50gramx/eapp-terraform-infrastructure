

resource "aws_key_pair" "ethos_key_pair" {
  key_name   = "ethos-key-pair"
  public_key = file(var.ssh_public_key_file)  # Path to your public key file
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "ethos_control_plane" {
  ami                         = data.aws_ami.amazon_linux_2.id
  associate_public_ip_address = true
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ethos_key_pair.key_name
  subnet_id                   = aws_subnet.ethos_subnet.id

  vpc_security_group_ids = [
    aws_security_group.ethos_sg.id
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  tags = {
    Name        = "ethos_control_plane"
    Provisioner = "Terraform"
  }
}

resource "aws_eip" "ethos_control_place_eip" {
  instance = aws_instance.ethos_control_plane.id
  vpc      = true
}

resource "null_resource" "openvpn_bootstrap" {
  connection {
    type        = "ssh"
    host        = aws_eip.ethos_control_place_eip.public_ip
    user        = "ec2-user"
    port        = "22"
    private_key = file(var.ssh_private_key_file)
    agent       = false
  }

  provisioner "file" {
    source    = "${path.module}/scripts/openvpn-install.sh"
    destination = "/home/ec2-user/openvpn-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x openvpn-install.sh",
      <<EOT
      sudo AUTO_INSTALL=y \
           APPROVE_IP=y \
           ENDPOINT=${aws_eip.ethos_control_place_eip.public_dns} \
           ./openvpn-install.sh
      
EOT
      ,
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
    host        = aws_eip.ethos_control_place_eip.public_ip
    user        = "ec2-user"
    port        = "22"
    private_key = file(var.ssh_private_key_file)
    agent       = false
  }

  provisioner "file" {
    source      = "${path.module}/scripts/update_users.sh"
    destination = "/home/ec2-user/update_users.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~ec2-user/update_users.sh",
      "sudo ~ec2-user/update_users.sh ${join(" ", var.ovpn_users)}",
    ]
  }
}

resource "null_resource" "microk8s_install_script_control_plane" {
  depends_on = [null_resource.openvpn_update_users_script]

  connection {
    type        = "ssh"
    host        = aws_eip.ethos_control_place_eip.public_ip
    user        = "ec2-user"
    port        = "22"
    private_key = file(var.ssh_private_key_file)
    agent       = false
  }

  provisioner "file" {
    source      = "${path.module}/scripts/microk8s-install.sh"
    destination = "/home/ec2-user/microk8s-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~ec2-user/microk8s-install.sh",
      "sudo ~ec2-user/microk8s-install.sh",
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
        -i ${var.ssh_private_key_file} ec2-user@${aws_eip.ethos_control_place_eip.public_ip}:/home/ec2-user/*.ovpn generated/ovpn-config/
    
EOT

  }
}

resource "aws_instance" "ethos_worker_node1" {
  ami                         = data.aws_ami.amazon_linux_2.id
  associate_public_ip_address = true
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ethos_key_pair.key_name
  subnet_id                   = aws_subnet.ethos_subnet.id

  vpc_security_group_ids = [
    aws_security_group.ethos_sg.id
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  tags = {
    Name        = "ethos_worker_node"
    Provisioner = "Terraform"
  }
}

resource "aws_eip" "ethos_worker_node1_eip" {
  instance = aws_instance.ethos_worker_node1.id
  vpc      = true
}

resource "null_resource" "microk8s_install_script_worker" {
  depends_on = [null_resource.openvpn_update_users_script]

  connection {
    type        = "ssh"
    host        = aws_eip.ethos_worker_node1_eip.public_ip
    user        = "ec2-user"
    port        = "22"
    private_key = file(var.ssh_private_key_file)
    agent       = false
  }

  provisioner "file" {
    source      = "${path.module}/scripts/microk8s-install.sh"
    destination = "/home/ec2-user/microk8s-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~ec2-user/microk8s-install.sh",
      "sudo ~ec2-user/microk8s-install.sh",
    ]
  }
}

#Additional pod using an public image
resource "kubernetes_pod" "pod" {
  metadata {
    name = var.pod_name
  }

  spec {
    container {
      name  = "openssh-server"
      image = var.image
      port {
        container_port = var.container_port
      }
    }
  }
}
