

resource "aws_key_pair" "openvpn" {
  key_name   = "my-key-pair"
  public_key = file(var.ssh_public_key_file)  # Path to your public key file
}

# resource "aws_security_group" "ethos_control_plane_sg" {
#   name        = "ethos_control_plane_sg"
#   description = "Allow SSH and Kubernetes ports"

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 16443
#     to_port     = 16443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 943
#     to_port     = 943
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 1194
#     to_port     = 1194
#     protocol    = "udp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = -1
#     to_port     = -1
#     protocol    = "icmp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 25000
#     to_port     = 25000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_instance" "ethos_control_plane" {
#   ami           = var.ami
#   instance_type = var.instance_type

#   key_name               = aws_key_pair.generated_key_pair.key_name 
  
#   vpc_security_group_ids     = [aws_security_group.ethos_control_plane_sg.id]
#   associate_public_ip_address = true

#   user_data = <<-EOF
#               #!/bin/bash
#               sudo apt update -y
#               sudo apt upgrade -y
#               sudo snap install microk8s --classic
#               sudo usermod -a -G microk8s ubuntu
#               sudo chown -f -R ubuntu ~/.kube
#               EOF

#   tags = {
#     Name = "Ethos Control Plan"
#   }
# }

resource "aws_instance" "openvpn" {
  ami                         = var.ami
  associate_public_ip_address = true
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.openvpn.key_name
  subnet_id                   = aws_subnet.openvpn.id

  vpc_security_group_ids = [
    aws_security_group.openvpn.id
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

resource "aws_eip" "openvpn_eip" {
  instance = aws_instance.openvpn.id
  vpc      = true
}

resource "null_resource" "openvpn_bootstrap" {
  connection {
    type        = "ssh"
    host        = aws_eip.openvpn_eip.public_ip
    user        = "ubuntu"
    port        = "22"
    private_key = file(var.ssh_private_key_file)
    agent       = false
  }

  provisioner "file" {
    source    = "${path.module}/scripts/openvpn-install.sh"
    destination = "/home/ubuntu/openvpn-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x openvpn-install.sh",
      <<EOT
      sudo AUTO_INSTALL=y \
           APPROVE_IP=y \
           ENDPOINT=${aws_eip.openvpn_eip.public_dns} \
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
    host        = aws_eip.openvpn_eip.public_ip
    user        = "ubuntu"
    port        = "22"
    private_key = file(var.ssh_private_key_file)
    agent       = false
  }

  provisioner "file" {
    source      = "${path.module}/scripts/update_users.sh"
    destination = "/home/ubuntu/update_users.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~ubuntu/update_users.sh",
      "sudo ~ubuntu/update_users.sh ${join(" ", var.ovpn_users)}",
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
        -i ${var.ssh_private_key_file} ubuntu@${aws_eip.openvpn_eip.public_ip}:/home/ubuntu/*.ovpn generated/ovpn-config/
    
EOT

  }
}
