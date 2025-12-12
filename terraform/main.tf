# Configure AWS Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create VPC (optional, uses default VPC if not specified)
resource "aws_vpc" "devsecops_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "devsecops_igw" {
  vpc_id = aws_vpc.devsecops_vpc.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# Create Public Subnet
resource "aws_subnet" "devsecops_subnet" {
  vpc_id                  = aws_vpc.devsecops_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-subnet"
    Environment = var.environment
  }
}

# Create Route Table
resource "aws_route_table" "devsecops_rt" {
  vpc_id = aws_vpc.devsecops_vpc.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.devsecops_igw.id
  }

  tags = {
    Name        = "${var.project_name}-rt"
    Environment = var.environment
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "devsecops_rta" {
  subnet_id      = aws_subnet.devsecops_subnet.id
  route_table_id = aws_route_table.devsecops_rt.id
}

# Get Available Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create Security Group
resource "aws_security_group" "devsecops_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for DevSecOps application"
  vpc_id      = aws_vpc.devsecops_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Frontend access
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Frontend - React"
  }

  # Backend API access
  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Backend API - Node.js"
  }

  # SonarQube access
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SonarQube"
  }

  # OWASP ZAP access
  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OWASP ZAP"
  }

  # PostgreSQL (internal)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "PostgreSQL"
  }

  # MongoDB (internal)
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "MongoDB"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
  }
}

# Create EC2 Instance
resource "aws_instance" "devsecops_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.devsecops_subnet.id
  vpc_security_group_ids = [aws_security_group.devsecops_sg.id]
  key_name               = var.key_pair_name

  # Root volume configuration
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = false

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  # User data script to setup Docker and dependencies
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    github_repo = var.github_repo
    deploy_path = var.deploy_path
  }))

  monitoring = true

  tags = {
    Name        = "${var.project_name}-server"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.devsecops_igw]
}

# Create Elastic IP for stable public IP
resource "aws_eip" "devsecops_eip" {
  instance = aws_instance.devsecops_server.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-eip"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.devsecops_igw]
}

# Null resource to execute remote commands after instance is ready
resource "null_resource" "devsecops_provisioner" {
  triggers = {
    instance_id = aws_instance.devsecops_server.id
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for EC2 instance to be ready...'",
      "while [ ! -f /tmp/docker_ready ]; do sleep 5; done",
      "echo 'EC2 instance is ready!'"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = aws_eip.devsecops_eip.public_ip
      timeout     = "2m"
    }
  }

  depends_on = [aws_eip.devsecops_eip]
}

# Output EC2 instance details
output "ec2_instance_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_eip.devsecops_eip.public_ip
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.devsecops_server.id
}

output "ec2_instance_public_dns" {
  description = "Public DNS of EC2 instance"
  value       = aws_instance.devsecops_server.public_dns
}

output "ec2_security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.devsecops_sg.id
}

output "access_urls" {
  description = "URLs to access services"
  value = {
    frontend  = "http://${aws_eip.devsecops_eip.public_ip}:3000"
    backend   = "http://${aws_eip.devsecops_eip.public_ip}:3001/api"
    sonarqube = "http://${aws_eip.devsecops_eip.public_ip}:9000"
    owasp_zap = "http://${aws_eip.devsecops_eip.public_ip}:8082"
  }
}
