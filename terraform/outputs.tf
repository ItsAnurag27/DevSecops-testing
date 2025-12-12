output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.devsecops_eip.public_ip
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.devsecops_server.id
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_eip.devsecops_eip.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.devsecops_sg.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.devsecops_vpc.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "frontend_url" {
  description = "URL to access the React frontend"
  value       = "http://${aws_eip.devsecops_eip.public_ip}:3000"
}

output "backend_url" {
  description = "URL to access the Express backend"
  value       = "http://${aws_eip.devsecops_eip.public_ip}:3001"
}

output "sonarqube_url" {
  description = "URL to access SonarQube"
  value       = "http://${aws_eip.devsecops_eip.public_ip}:9000"
}

output "owasp_zap_url" {
  description = "URL to access OWASP ZAP"
  value       = "http://${aws_eip.devsecops_eip.public_ip}:8082"
}

output "mongodb_connection" {
  description = "MongoDB connection string"
  value       = "mongodb://${aws_eip.devsecops_eip.public_ip}:27017/todos"
}

output "ssh_command" {
  description = "SSH command to connect to EC2 instance"
  value       = "ssh -i /path/to/your/key.pem ec2-user@${aws_eip.devsecops_eip.public_ip}"
}

output "all_service_urls" {
  description = "All service URLs"
  value = {
    frontend  = "http://${aws_eip.devsecops_eip.public_ip}:3000"
    backend   = "http://${aws_eip.devsecops_eip.public_ip}:3001"
    sonarqube = "http://${aws_eip.devsecops_eip.public_ip}:9000"
    zap       = "http://${aws_eip.devsecops_eip.public_ip}:8082"
  }
}
