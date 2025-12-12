# Terraform Infrastructure Documentation

## Overview
This directory contains Infrastructure-as-Code (IaC) for deploying the DevSecOps application to AWS EC2 with complete networking and security configuration.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Region (us-east-1)               │
├─────────────────────────────────────────────────────────────┤
│                    VPC (10.0.0.0/16)                         │
│  ┌─────────────────────────────────────────────────────────┐│
│  │         Public Subnet (10.0.1.0/24)                     ││
│  │  ┌───────────────────────────────────────────────────┐ ││
│  │  │     EC2 Instance (t2.large, 30GB)                │ ││
│  │  │  ┌─────────────────────────────────────────────┐ │ ││
│  │  │  │  Docker Compose Services                   │ │ ││
│  │  │  │  • React Frontend (3000)                   │ │ ││
│  │  │  │  • Express Backend (3001)                  │ │ ││
│  │  │  │  • MongoDB (27017)                         │ │ ││
│  │  │  │  • SonarQube (9000)                        │ │ ││
│  │  │  │  • PostgreSQL (5432)                       │ │ ││
│  │  │  │  • OWASP ZAP (8082)                        │ │ ││
│  │  │  └─────────────────────────────────────────────┘ │ ││
│  │  │  Elastic IP: Static Public IP                    │ ││
│  │  │  Security Group: 8 ingress rules                 │ ││
│  │  └───────────────────────────────────────────────────┘ ││
│  │                                                         ││
│  │  Internet Gateway ↔ Route Table → EC2                 ││
│  └─────────────────────────────────────────────────────────┘│
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Files

### main.tf
Complete AWS infrastructure definition including:
- AWS Provider configuration
- VPC with CIDR 10.0.0.0/16
- Internet Gateway for public internet access
- Public Subnet 10.0.1.0/24
- Route Table for subnet routing
- Security Group with 8 ingress rules
- EC2 Instance (t2.large, 30GB GP3 volume)
- Elastic IP for static public addressing
- Provisioner to wait for EC2 initialization

### variables.tf
All configurable parameters with defaults:
- `aws_region` - AWS region (default: us-east-1)
- `instance_type` - EC2 instance type (default: t2.large)
- `root_volume_size` - EBS volume size in GB (default: 30)
- `root_volume_type` - EBS volume type (default: gp3)
- `key_pair_name` - EC2 key pair name (REQUIRED)
- `private_key_path` - Path to private key file (REQUIRED)
- `vpc_cidr` - VPC CIDR block (default: 10.0.0.0/16)
- `subnet_cidr` - Public subnet CIDR (default: 10.0.1.0/24)
- `github_repo` - GitHub repository URL
- `deploy_path` - Deployment directory on EC2
- `allowed_ssh_cidr` - CIDR blocks allowed SSH access

### terraform.tfvars
Variable values to be customized before deployment.

### outputs.tf
Terraform outputs providing:
- EC2 Public IP
- Service URLs (Frontend, Backend, SonarQube, OWASP ZAP)
- SSH connection details
- All resource IDs

### user_data.sh
EC2 initialization script that:
- Updates system packages
- Installs Docker and Docker Compose
- Installs Git and curl
- Creates deployment directory
- Clones GitHub repository
- Prepares for Docker Compose startup

## Prerequisites

### Local System
1. **Terraform** (v1.5.0+)
   ```bash
   brew install terraform  # macOS
   choco install terraform  # Windows
   apt-get install terraform  # Linux
   ```

2. **AWS CLI** (v2)
   ```bash
   aws --version  # Verify installation
   ```

3. **AWS Account**
   - Valid AWS credentials
   - IAM user with EC2, VPC, and IAM permissions
   - EC2 key pair already created or permission to create one

4. **Git**
   ```bash
   git --version  # Verify installation
   ```

### AWS Setup
1. Create or use existing EC2 key pair:
   ```bash
   aws ec2 create-key-pair --key-name devsecops-key \
     --query 'KeyMaterial' --output text > devsecops-key.pem
   chmod 600 devsecops-key.pem
   ```

2. Configure AWS credentials:
   ```bash
   aws configure
   # Enter: Access Key ID, Secret Access Key, Region, Output format
   ```

3. Verify credentials:
   ```bash
   aws sts get-caller-identity
   ```

## Configuration

### Step 1: Customize terraform.tfvars
Edit `terraform/terraform.tfvars` with your values:

```hcl
aws_region = "us-east-1"  # Change to your preferred region

instance_type    = "t2.large"
root_volume_size = 30
root_volume_type = "gp3"

# REQUIRED: Change to your EC2 key pair name
key_pair_name = "devsecops-key"

# REQUIRED: Change to path of your private key
private_key_path = "/Users/yourname/.ssh/devsecops-key.pem"

vpc_cidr  = "10.0.0.0/16"
subnet_cidr = "10.0.1.0/24"

github_repo = "https://github.com/ItsAnurag27/DevSecops-testing.git"
deploy_path = "/home/ec2-user/devsecops-app"

# Security: Change 0.0.0.0/0 to your IP (e.g., "203.0.113.0/32")
allowed_ssh_cidr = ["0.0.0.0/0"]
```

### Step 2: Initialize Terraform
```bash
cd terraform
terraform init
```

This downloads required providers and plugins.

### Step 3: Validate Configuration
```bash
terraform validate
```

Checks syntax and configuration validity.

### Step 4: Review Plan
```bash
terraform plan -out=tfplan
```

Shows what will be created/modified without making changes.

## Deployment

### Create Infrastructure
```bash
# Review the plan first
terraform plan

# Apply the plan (creates resources)
terraform apply

# Or apply without plan (auto-approve)
terraform apply -auto-approve
```

**Estimated Time**: 5-10 minutes

### Monitor Creation
Watch EC2 initialization in AWS Console:
1. Go to EC2 → Instances
2. Select the new instance
3. Check System log and Instance log tabs
4. Wait for Status checks to pass (2/2)

### Access Services
After `terraform apply` completes, view outputs:
```bash
terraform output
```

Or access specific service:
```bash
EC2_IP=$(terraform output -raw ec2_public_ip)
curl http://${EC2_IP}:3001/api/todos  # Test backend
```

## Management

### Scale Instance Type
Change instance_type in terraform.tfvars:
```hcl
instance_type = "t2.xlarge"  # Larger instance
```

Then apply:
```bash
terraform apply
```

**Note**: This will terminate and recreate the instance.

### Update Security Group Rules
Modify allowed_ssh_cidr or add new rules in main.tf:
```hcl
ingress {
  from_port   = 8000
  to_port     = 8000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

Apply changes:
```bash
terraform apply
```

### Modify Storage
Change root_volume_size in terraform.tfvars:
```hcl
root_volume_size = 50  # 50GB instead of 30GB
```

Apply:
```bash
terraform apply
```

### Update Instance Tags
Edit `aws_instance` resource in main.tf:
```hcl
tags = {
  Name        = "devsecops-server"
  Environment = "production"
  Team        = "devops"
}
```

Apply:
```bash
terraform apply
```

## Monitoring

### Check Deployment Status
```bash
# Get instance details
terraform output

# Manually check AWS Console
# EC2 → Instances → Click instance
```

### SSH into Instance
```bash
EC2_IP=$(terraform output -raw ec2_public_ip)
KEY_PATH="/path/to/your/key.pem"

ssh -i ${KEY_PATH} ec2-user@${EC2_IP}
```

### Check Docker Services
```bash
# SSH into instance first
ssh -i key.pem ec2-user@<EC2_IP>

# Check running containers
docker ps

# View container logs
docker logs container_name

# Check Docker Compose status
docker-compose ps
```

### View Terraform State
```bash
# Human-readable state
terraform show

# JSON format
terraform state list
terraform state show aws_instance.devsecops_server
```

## Troubleshooting

### Error: "Key pair not found"
```
Error: InvalidKeyPair.NotFound
```
Solution:
1. Verify key_pair_name exists: `aws ec2 describe-key-pairs --key-names devsecops-key`
2. Create if missing: `aws ec2 create-key-pair --key-name devsecops-key --query 'KeyMaterial' --output text > devsecops-key.pem`
3. Update terraform.tfvars and retry

### Error: "Access Denied - Insufficient permissions"
```
Error: UnauthorizedOperation
```
Solution:
1. Verify AWS credentials: `aws sts get-caller-identity`
2. Check IAM permissions (EC2, VPC, IAM full access required)
3. Verify AWS_PROFILE if using multiple credentials

### Error: "Subnet too small"
```
Error: InvalidSubnet.Conflict
```
Solution:
1. Check CIDR notation in terraform.tfvars
2. Ensure subnet_cidr is within vpc_cidr
3. Example: vpc_cidr = "10.0.0.0/16", subnet_cidr = "10.0.1.0/24"

### Error: "EC2 instance failed to initialize"
Check user_data.sh:
1. SSH into instance
2. View cloud-init logs: `tail -f /var/log/cloud-init-output.log`
3. Check Docker status: `sudo systemctl status docker`
4. Verify Git clone: `ls /home/ec2-user/devsecops-app`

### EC2 Instance Created But Services Not Running
```bash
# SSH into instance
ssh -i key.pem ec2-user@<EC2_IP>

# Check if docker-compose.yml exists
ls -la /home/ec2-user/devsecops-app/docker-compose.yml

# Check Docker Compose status
cd /home/ec2-user/devsecops-app
docker-compose ps

# View logs
docker-compose logs -f
```

### Terraform State Issues
```bash
# Refresh state (sync with actual AWS)
terraform refresh

# List all resources in state
terraform state list

# Remove resource from state (caution!)
terraform state rm aws_instance.devsecops_server

# Import existing resource
terraform import aws_instance.devsecops_server i-1234567890abcdef0
```

## Security Considerations

### Network Security
- ✅ Restricted to VPC (10.0.0.0/16)
- ⚠️ SSH access: Change allowed_ssh_cidr to your IP
  ```hcl
  allowed_ssh_cidr = ["203.0.113.0/32"]  # Your IP only
  ```
- ✅ Other services accessible only from EC2 internally

### Key Management
- ⚠️ Store private key securely
- ❌ Never commit .pem files to Git
- ✅ Use specific directory permissions: `chmod 600 key.pem`
- ✅ Rotate keys quarterly

### IAM Security
- ✅ Use dedicated IAM user (github-actions)
- ✅ Limit permissions (EC2, VPC only)
- ⚠️ Rotate access keys regularly
- ✅ Use temporary credentials (STS) for CI/CD

### Resource Tagging
Add tags for cost tracking:
```hcl
tags = {
  Environment = "production"
  CostCenter  = "engineering"
  Owner       = "devops-team"
  Terraform   = "true"
}
```

## Cost Optimization

### Estimated Costs
| Resource | Type | Monthly |
|----------|------|---------|
| EC2 t2.large | Compute | $70 |
| 30GB GP3 EBS | Storage | $2.50 |
| Elastic IP | Static IP | Free* |
| Data Transfer | Egress | $0.02/GB |
| **Total** | | **~$72.50+** |

*Free if in use, charged if unassociated

### Cost Reduction
1. **Stop instance** (instead of terminating):
   ```bash
   # AWS Console: EC2 → Instance State → Stop
   # Cost during stop: EBS only (~$2.50/month)
   ```

2. **Use smaller instance** for non-prod:
   ```hcl
   instance_type = "t2.medium"  # ~$35/month instead of $70
   ```

3. **Reduce storage**:
   ```hcl
   root_volume_size = 20  # 20GB instead of 30GB
   ```

4. **Auto-shutdown** (using cron or Lambda):
   ```bash
   # SSH into EC2 and add to crontab:
   0 20 * * *  /usr/bin/sudo /usr/sbin/shutdown -h now  # Shut down at 8 PM
   ```

5. **Destroy when not needed**:
   ```bash
   terraform destroy  # Removes all resources
   ```

## Backup & Recovery

### Backup EC2 Data
Create AMI (machine image):
```bash
# AWS Console
# EC2 → Instances → Right-click → Image and templates → Create image

# Or via AWS CLI
aws ec2 create-image --instance-id i-1234567890abcdef0 --name "devsecops-backup-$(date +%Y%m%d)"
```

### Restore from Backup
1. Note the AMI ID from backup
2. Update main.tf to use backup AMI:
   ```hcl
   ami = "ami-xxxxxxxx"  # Your backup AMI
   ```
3. Run `terraform apply` to restore

### Database Backups
MongoDB:
```bash
# SSH into EC2
ssh -i key.pem ec2-user@<EC2_IP>

# Backup MongoDB
docker-compose exec mongo mongodump --out /home/ec2-user/mongo-backup

# Restore MongoDB
docker-compose exec mongo mongorestore /home/ec2-user/mongo-backup
```

## Advanced

### Custom VPC Configuration
Modify variables.tf to allow more subnets:
```hcl
variable "subnet_cidrs" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
```

### Multi-AZ Deployment
Create subnets in different availability zones:
```hcl
resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.devsecops_vpc.id
  cidr_block        = var.subnet_cidr  # Different CIDR
  availability_zone = "${var.aws_region}b"
}
```

### Auto-Scaling Configuration
Create launch template and auto-scaling group:
```hcl
resource "aws_launch_template" "devsecops_lt" {
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
}

resource "aws_autoscaling_group" "devsecops_asg" {
  # Configuration...
}
```

### Load Balancer
Add Application Load Balancer:
```hcl
resource "aws_lb" "devsecops_alb" {
  name               = "devsecops-alb"
  internal           = false
  load_balancer_type = "application"
}
```

## Clean Up

### Destroy Resources (Warning: Cannot be undone)
```bash
# List resources to be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Destroy specific resource
terraform destroy -target=aws_instance.devsecops_server
```

**Caution**: This terminates EC2, deletes EBS volume, and removes all data.

### Remove State Locally
```bash
rm -rf terraform/.terraform
rm terraform/.terraform.lock.hcl
rm terraform/tfstate*
```

**Result**: Next `terraform init` creates fresh state.

## Support & Documentation

- Terraform Docs: https://www.terraform.io/docs
- AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest
- EC2 Documentation: https://docs.aws.amazon.com/ec2/
- Best Practices: https://www.terraform.io/docs/cloud/best-practices

## Next Steps

1. ✅ Configure terraform.tfvars
2. ✅ Create EC2 key pair
3. ✅ Run `terraform init`
4. ✅ Run `terraform plan`
5. ✅ Run `terraform apply`
6. ✅ Access services using output IPs
7. ✅ Set up GitHub Actions for automated deployments (see GITHUB_ACTIONS_SETUP.md)
8. ✅ Configure Jenkins pipeline for security scanning (see JENKINS_EC2_SETUP.md)
