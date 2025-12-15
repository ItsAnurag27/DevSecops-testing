variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devsecops"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.large"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "jenkins-key"
}

variable "private_key_path" {
  description = "Path to private key file"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/ItsAnurag27/DevSecops-testing.git"
}

variable "deploy_path" {
  description = "Deployment path on EC2"
  type        = string
  default     = "/opt/devsecops"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
