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

# Configure Elasticsearch vm.max_map_count for SonarQube
echo "Configuring Elasticsearch kernel parameters..."
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# Install Java (required for Jenkins)
echo "Installing Java..."
sudo yum install -y java-17-amazon-corretto-devel

# Install Jenkins
echo "Installing Jenkins..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Create deployment directory
echo "Creating deployment directory..."
sudo mkdir -p ${deploy_path}
sudo chown ec2-user:ec2-user ${deploy_path}

# Clone repository
echo "Cloning repository..."
cd ${deploy_path}
git clone ${github_repo} .
git checkout main

# Start Docker containers (skip services that need building)
echo "Starting Docker containers..."
cd ${deploy_path}
docker-compose up -d --no-build sonarqube sonardb mongo owasp-zap || echo "Some containers may not be available yet"

# Wait for containers to be healthy
echo "Waiting for containers to start..."
sleep 15

echo "EC2 initialization completed!"
echo "Containers status:"
docker-compose ps

echo ""
echo "Service URLs:"
echo "  - SonarQube: http://$(hostname -I | awk '{print $1}'):9000"
echo "  - MongoDB: $(hostname -I | awk '{print $1}'):27017"
echo "  - OWASP ZAP: http://$(hostname -I | awk '{print $1}'):8082"
