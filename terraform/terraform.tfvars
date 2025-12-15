# AWS Configuration
aws_region = "eu-north-1"

# Project Configuration
project_name = "devsecops"
environment  = "production"

# EC2 Configuration
instance_type    = "t2.large"
root_volume_size = 30
root_volume_type = "gp3"

# VPC Configuration
vpc_cidr    = "10.0.0.0/16"
subnet_cidr = "10.0.1.0/24"

# Key Pair Configuration
key_pair_name     = "demo"  # Your EC2 key pair name
private_key_path  = "/tmp/ec2_key.pem"  # GitHub Actions will use this path

# GitHub Configuration
github_repo = "https://github.com/ItsAnurag27/DevSecops-testing.git"
deploy_path = "/opt/devsecops"

# Security Configuration
allowed_ssh_cidr = ["0.0.0.0/0"]  # Change this to your IP for better security
