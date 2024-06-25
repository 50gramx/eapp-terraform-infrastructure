
output "instance_public_ip" {
  value = aws_eip.openvpn_eip.public_ip
}

output "ec2_instance_dns" {
  value = aws_eip.openvpn_eip.public_dns
}

output "connection_string" {
  value = "'ssh -i ${var.ssh_private_key_file} ubuntu@${aws_eip.openvpn_eip.public_dns}'"
}