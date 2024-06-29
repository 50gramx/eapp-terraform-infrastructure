resource "aws_vpc" "ethos_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "ethos_control_plane"
    Provisioner = "Terraform"
  }
}

resource "aws_subnet" "ethos_subnet" {
  vpc_id     = aws_vpc.ethos_vpc.id
  cidr_block = cidrsubnet("10.0.0.0/16", 8, 0)

  tags = {
    Name        = "ethos_control_plane"
    Provisioner = "Terraform"
  }
}

resource "aws_internet_gateway" "ethos" {
  vpc_id = aws_vpc.ethos_vpc.id

  tags = {
    Name        = "ethos_control_plane"
    Provisioner = "Terraform"
  }
}

resource "aws_route_table" "ethos" {
  vpc_id = aws_vpc.ethos_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ethos.id
  }
}

resource "aws_route_table_association" "ethos_rta" {
  subnet_id      = aws_subnet.ethos_subnet.id
  route_table_id = aws_route_table.ethos.id
}

resource "aws_security_group" "ethos_sg" {
  name        = "ethos"
  description = "Allow inbound UDP access to ethos and unrestricted egress"

  vpc_id = aws_vpc.ethos_vpc.id

  tags = {
    Name        = "ethos_control_plane"
    Provisioner = "Terraform"
  }

    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 16443
    to_port     = 16443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25000
    to_port     = 25000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
