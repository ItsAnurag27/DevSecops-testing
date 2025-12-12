# GitHub Actions Setup Guide

## Overview
This guide walks through setting up the GitHub Actions workflow for automated Terraform EC2 deployment.

## Prerequisites
- GitHub repository with push access
- AWS account with appropriate IAM credentials
- EC2 key pair created in AWS
- Repository secrets configured

## Step 1: Create AWS IAM User for GitHub Actions

### Option A: Using AWS Console
1. Go to IAM → Users → Create user
2. User name: `github-actions`
3. Click "Next"
4. Attach policies:
   - `AmazonEC2FullAccess`
   - `AmazonVPCFullAccess`
   - `IAMFullAccess` (for security group)
5. Click "Next" and "Create user"
6. Go to Security credentials tab
7. Create access key (type: Application running outside AWS)
8. Copy Access Key ID and Secret Access Key

### Option B: Using AWS CLI
```bash
# Create user
aws iam create-user --user-name github-actions

# Attach EC2 and VPC policies
aws iam attach-user-policy --user-name github-actions --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
aws iam attach-user-policy --user-name github-actions --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess

# Create access key
aws iam create-access-key --user-name github-actions
```

## Step 2: Add GitHub Repository Secrets

Go to GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:

### 1. AWS_ACCESS_KEY_ID
- Value: Access key ID from Step 1
- Example: `AKIAIOSFODNN7EXAMPLE`

### 2. AWS_SECRET_ACCESS_KEY
- Value: Secret access key from Step 1
- Example: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

### 3. EC2_KEY_PAIR_NAME
- Value: Name of your EC2 key pair (without .pem extension)
- Example: `devsecops-key`
- Note: The key pair must exist in AWS EC2 console → Key pairs

### 4. EC2_PRIVATE_KEY
- Value: Contents of your private key file (.pem)
- How to get:
  ```bash
  cat /path/to/your/key.pem
  ```
- Then copy entire contents including BEGIN and END lines

## Step 3: Prepare EC2 Key Pair

If you don't have an EC2 key pair:

### Using AWS Console:
1. Go to EC2 → Key pairs
2. Click "Create key pair"
3. Name: `devsecops-key` (or your preferred name)
4. Type: RSA
5. Format: .pem
6. Click "Create key pair"
7. Save the downloaded .pem file securely

### Using AWS CLI:
```bash
aws ec2 create-key-pair --key-name devsecops-key --query 'KeyMaterial' --output text > devsecops-key.pem
chmod 600 devsecops-key.pem
```

## Step 4: Customize Terraform Variables

Edit `terraform/terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-east-1"  # Change if needed

# EC2 Configuration
instance_type       = "t2.large"
root_volume_size    = 30
root_volume_type    = "gp3"
key_pair_name       = "devsecops-key"  # Must match your EC2 key pair
private_key_path    = "/tmp/ec2_key.pem"

# VPC/Network Configuration
vpc_cidr       = "10.0.0.0/16"
subnet_cidr    = "10.0.1.0/24"

# GitHub Configuration
github_repo  = "https://github.com/your-username/your-repo.git"
deploy_path  = "/home/ec2-user/devsecops-app"

# Security Configuration
allowed_ssh_cidr = ["YOUR_IP/32"]  # Change to your IP for security
```

## Step 5: Trigger the Workflow

### Via GitHub UI:
1. Go to your repository
2. Click "Actions" tab
3. Select "Deploy to EC2 with Terraform"
4. Click "Run workflow"
5. Select action: `plan` (to preview) or `apply` (to create)
6. Click "Run workflow"

### Via GitHub CLI:
```bash
# Plan
gh workflow run deploy-to-ec2.yml -f action=plan

# Apply
gh workflow run deploy-to-ec2.yml -f action=apply

# Destroy
gh workflow run deploy-to-ec2.yml -f action=destroy
```

## Step 6: Monitor Execution

1. Go to Actions tab
2. Click the running workflow
3. View logs in real-time
4. After completion, check outputs for EC2 IP and access URLs

## Workflow Actions

### Plan (Recommended First Step)
- Previews what Terraform will create
- No actual resources are created
- Shows resource changes
- Artifact saved for review

### Apply
- Actually creates EC2 instance
- Runs after plan review
- Outputs EC2 IP and access URLs
- Takes 5-10 minutes to complete

### Destroy
- Terminates all AWS resources created by Terraform
- Cleans up EC2, VPC, security group, etc.
- Use with caution!

## Accessing Services After Deployment

Once `apply` completes, use the EC2 IP from workflow output:

```bash
# Get EC2 IP
EC2_IP=$(terraform output -raw ec2_public_ip)

# Frontend
curl http://${EC2_IP}:3000

# Backend Health
curl http://${EC2_IP}:3001/api/todos

# SonarQube
open http://${EC2_IP}:9000

# OWASP ZAP
open http://${EC2_IP}:8082

# SSH into EC2
ssh -i /path/to/devsecops-key.pem ec2-user@${EC2_IP}
```

## Troubleshooting

### Error: "AWS credentials not found"
- Check that all GitHub secrets are set correctly
- Verify secret names match exactly: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
- Ensure IAM user has required permissions

### Error: "Key pair not found"
- Verify EC2_KEY_PAIR_NAME matches exactly a key pair in AWS EC2 console
- Key pair must exist before Terraform runs
- Create it manually or via AWS CLI

### Error: "Private key has invalid format"
- Check that EC2_PRIVATE_KEY contains full .pem file contents
- Include BEGIN and END lines
- Should look like: `-----BEGIN RSA PRIVATE KEY-----`

### Error: "terraform init failed"
- Check Terraform version compatibility
- Verify AWS credentials have correct permissions
- Check AWS region is set correctly in workflow

### Terraform Plan Shows No Changes
- Run `destroy` action to clean up
- Check terraform.tfvars is properly configured
- Verify key_pair_name exists in AWS

## Security Best Practices

1. **Restrict SSH Access**
   - Change `allowed_ssh_cidr` in terraform.tfvars to your IP
   - Example: `"203.0.113.0/32"` instead of `"0.0.0.0/0"`

2. **Use GitHub Environments**
   - Create "production" environment
   - Require approvals before apply
   - Goes to Settings → Environments

3. **Rotate Access Keys**
   - Regenerate AWS access keys quarterly
   - Update GitHub secrets

4. **Monitor Costs**
   - Set AWS billing alerts
   - t2.large costs ~$0.10/hour (~$70/month)
   - Use `destroy` action when not needed

5. **Enable Audit Logging**
   - CloudTrail for AWS API calls
   - GitHub action logs (kept for 90 days)

## Next Steps

1. ✅ Add GitHub secrets
2. ✅ Customize terraform.tfvars
3. ✅ Create EC2 key pair
4. ✅ Run workflow with `plan`
5. ✅ Review plan output
6. ✅ Run workflow with `apply` (after approval)
7. ✅ Access services using provided URLs
8. ✅ Run security scans via Jenkins (if configured)
9. ✅ Use `destroy` when done to avoid costs

## Support

For issues with:
- **Terraform**: See terraform/README.md
- **GitHub Actions**: Check workflow logs in Actions tab
- **AWS**: Review CloudTrail logs in AWS console
- **Docker**: SSH to EC2 and check `docker ps` and logs

## Cost Estimation

| Resource | Type | Monthly Cost |
|----------|------|--------------|
| EC2 Instance | t2.large | ~$70 |
| EBS Volume | 30GB gp3 | ~$2.50 |
| Elastic IP | Static | Free (if in use) |
| Data Transfer | Out of AWS | $0.02/GB |
| **Total** | | **~$72.50+** |

*Costs apply only while resources are running. Use `destroy` to stop charges.*
