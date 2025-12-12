#!/bin/bash
set -e

echo "Starting EC2 initialization..."

# Update system
sudo yum update -y

# Install Docker
echo "Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Git
echo "Installing Git..."
sudo yum install -y git

# Install curl for health checks
sudo yum install -y curl

# Create deployment directory
echo "Creating deployment directory..."
sudo mkdir -p ${deploy_path}
sudo chown ec2-user:ec2-user ${deploy_path}

# Clone repository
echo "Cloning repository..."
cd ${deploy_path}
git clone ${github_repo} .
git checkout main

# Create marker file for provisioner
touch /tmp/docker_ready

echo "EC2 initialization completed!"
