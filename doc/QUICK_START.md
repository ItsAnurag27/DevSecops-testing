# DevSecOps Infrastructure - Quick Start Guide

## What Was Created

### 1. Terraform Infrastructure-as-Code
**Location**: `terraform/` directory

Files:
- `main.tf` - Complete AWS infrastructure (VPC, EC2 t2.large, 30GB storage, security groups)
- `variables.tf` - Configuration variables
- `terraform.tfvars` - Variable values (needs customization)
- `outputs.tf` - Output values (IPs, URLs, connection details)
- `user_data.sh` - EC2 bootstrap script (installs Docker, clones repo)
- `README.md` - Comprehensive Terraform documentation

Key Features:
✅ EC2 t2.large instance with 30GB GP3 storage
✅ VPC with public subnet (10.0.0.0/16)
✅ Security group with 8 ingress rules (SSH, HTTP, HTTPS, 3000, 3001, 8082, 9000, 5432, 27017)
✅ Elastic IP for stable public addressing
✅ Auto-installation of Docker and Docker Compose
✅ Git repository auto-cloning on EC2

### 2. GitHub Actions Pipeline
**Location**: `.github/workflows/deploy-to-ec2.yml`

Features:
✅ Manual workflow trigger (workflow_dispatch)
✅ Three actions: plan (preview), apply (create), destroy (cleanup)
✅ Automatic AWS credential handling
✅ Terraform plan artifact storage
✅ Real-time service URL display after deployment
✅ SSH command auto-generation
✅ Security best practices (secrets cleanup)

### 3. Documentation

#### GITHUB_ACTIONS_SETUP.md
Complete guide for:
- Creating AWS IAM user for GitHub Actions
- Setting up GitHub repository secrets
- Creating/configuring EC2 key pairs
- Customizing Terraform variables
- Triggering workflows
- Monitoring execution
- Troubleshooting

#### terraform/README.md
Complete Terraform documentation including:
- Architecture diagram
- Prerequisites and setup
- Configuration steps
- Deployment instructions
- Management commands
- Monitoring and troubleshooting
- Security best practices
- Cost optimization
- Backup and recovery

## Quick Start (5 Steps)

### Step 1: Create EC2 Key Pair (if not exists)
```bash
# Using AWS CLI
aws ec2 create-key-pair --key-name devsecops-key --query 'KeyMaterial' --output text > devsecops-key.pem
chmod 600 devsecops-key.pem
```

### Step 2: Configure GitHub Secrets
Go to: GitHub repo → Settings → Secrets and variables → Actions

Add 4 secrets:
1. `AWS_ACCESS_KEY_ID` - Your AWS access key
2. `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
3. `EC2_KEY_PAIR_NAME` - Name of your EC2 key (e.g., devsecops-key)
4. `EC2_PRIVATE_KEY` - Full contents of your .pem file

### Step 3: Customize terraform.tfvars
Edit `terraform/terraform.tfvars`:
```hcl
key_pair_name    = "devsecops-key"  # Your key pair name
private_key_path = "/tmp/ec2_key.pem"  # Keep as is (GitHub Actions uses this)

# Optional: Restrict SSH access
allowed_ssh_cidr = ["YOUR_IP/32"]  # Change to your IP
```

### Step 4: Trigger GitHub Actions (Plan)
1. Go to GitHub repo → Actions tab
2. Select "Deploy to EC2 with Terraform"
3. Click "Run workflow"
4. Choose action: `plan` (to preview)
5. Click "Run workflow"
6. Monitor execution, review output

### Step 5: Deploy (Apply)
1. Same as Step 4, but choose action: `apply`
2. Wait 5-10 minutes for EC2 to initialize
3. Check workflow output for service URLs
4. Access services using provided IPs

## Access Your Services

After successful deployment, use the EC2 IP from GitHub Actions output:

```
Frontend:  http://<EC2_IP>:3000
Backend:   http://<EC2_IP>:3001
API Docs:  http://<EC2_IP>:3001/api/todos
SonarQube: http://<EC2_IP>:9000
OWASP ZAP: http://<EC2_IP>:8082
MongoDB:   mongodb://<EC2_IP>:27017/todos
```

SSH Access:
```bash
ssh -i devsecops-key.pem ec2-user@<EC2_IP>
```

## Security Features

✅ **Network Security**
- VPC isolation (10.0.0.0/16)
- Security group with specific ports only
- SSH access restricted to allowed IPs

✅ **Data Protection**
- Private key stored securely in GitHub Secrets
- No hardcoded credentials
- Automatic secret cleanup after deployment

✅ **Monitoring**
- CloudWatch integration
- Instance status checks
- Auto-generated logs in GitHub Actions

## Cost Estimate

| Resource | Monthly Cost |
|----------|--------------|
| EC2 t2.large | ~$70 |
| 30GB EBS | ~$2.50 |
| Elastic IP | Free* |
| Data transfer | $0.02/GB |
| **Total** | **~$72.50+** |

*Free if in use, billed if unassociated

## Cleanup

To stop incurring charges:
```bash
# Option 1: Destroy via GitHub Actions (recommended)
# Go to Actions → Run workflow → Choose "destroy"

# Option 2: Local destruction (if you have Terraform installed)
cd terraform
terraform destroy
```

## Workflow Status

✅ **Completed**
- Terraform scripts for EC2 t2.large (30GB, security groups)
- GitHub Actions workflow (plan/apply/destroy)
- User data script for EC2 bootstrap
- Complete documentation

✅ **Next Steps**
1. Add GitHub Secrets (4 items)
2. Customize terraform.tfvars
3. Run GitHub Actions workflow (plan)
4. Review plan output
5. Run GitHub Actions workflow (apply)
6. Access services using provided IPs

## Troubleshooting

### Workflow fails at "AWS credentials not found"
→ Check all 4 GitHub Secrets are set correctly

### Workflow fails at "Key pair not found"
→ Verify EC2_KEY_PAIR_NAME matches a key pair in AWS EC2 console

### EC2 created but services not running
→ SSH to instance and check: `docker-compose ps`

### Can't access services on EC2 IP
→ Check security group allows inbound on required ports (3000, 3001, 8082, 9000, 27017, 5432)

## Files Summary

```
terraform/
├── main.tf              # AWS infrastructure definition
├── variables.tf         # Configuration variables
├── terraform.tfvars     # Variable values (customize these!)
├── outputs.tf           # Output values
├── user_data.sh         # EC2 bootstrap script
└── README.md            # Comprehensive documentation

.github/workflows/
└── deploy-to-ec2.yml    # GitHub Actions pipeline

GITHUB_ACTIONS_SETUP.md  # GitHub Actions setup guide
```

## Related Documentation

- **Jenkins Pipeline**: See JENKINS_EC2_SETUP.md
- **Security Scanning**: See docker-compose.yml (SonarQube, OWASP ZAP, Trivy)
- **Backend API**: See backend/README.md
- **Frontend**: See frontend/README.md

## Support

For detailed instructions:
- **Terraform setup**: See `terraform/README.md`
- **GitHub Actions setup**: See `GITHUB_ACTIONS_SETUP.md`
- **Jenkins integration**: See `JENKINS_EC2_SETUP.md`
- **Credentials reference**: See `CREDENTIALS_REFERENCE.md`

## Important Notes

⚠️ **Before deploying to production:**
1. Restrict SSH access (`allowed_ssh_cidr` → your IP)
2. Enable CloudTrail for audit logging
3. Configure billing alerts
4. Set up automated backups
5. Use separate AWS accounts for staging/production
6. Enable MFA for AWS console access
7. Review security group rules (minimize open ports)

🔐 **Keep secure:**
- Store private keys safely (not in Git)
- Rotate AWS credentials regularly
- Use GitHub Secrets (never hardcode credentials)
- Review GitHub Actions logs regularly
- Monitor AWS billing
