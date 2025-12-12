# Implementation Checklist

## Pre-Deployment Setup

### AWS Account Setup
- [ ] AWS account created and active
- [ ] AWS CLI installed and configured
  ```bash
  aws --version
  aws sts get-caller-identity
  ```
- [ ] IAM user with EC2, VPC, and IAM permissions created
- [ ] Access Key ID and Secret Access Key obtained

### Local Environment
- [ ] Terraform installed (v1.5.0+)
  ```bash
  terraform version
  ```
- [ ] Git installed and configured
  ```bash
  git --version
  ```
- [ ] GitHub SSH keys configured (for code push)

### GitHub Repository Setup
- [ ] Repository created on GitHub
- [ ] Code pushed to main branch
  ```bash
  git push origin main
  ```
- [ ] Repository is public (or GitHub Actions enabled on private repo)
- [ ] GitHub Actions tab is visible

---

## EC2 Key Pair Setup

### Create New Key Pair (if needed)
- [ ] EC2 key pair created in AWS
  ```bash
  aws ec2 create-key-pair --key-name devsecops-key --query 'KeyMaterial' --output text > devsecops-key.pem
  chmod 600 devsecops-key.pem
  ```
- [ ] Private key file saved securely
- [ ] Key pair name noted: `_________________`

### Verify Key Pair
- [ ] Key pair exists in AWS: `aws ec2 describe-key-pairs --key-names devsecops-key`
- [ ] Private key is readable: `ls -la devsecops-key.pem`
- [ ] Private key has correct permissions (600): `stat devsecops-key.pem`

---

## GitHub Secrets Configuration

### Add Repository Secrets
Go to: GitHub repo → Settings → Secrets and variables → Actions

#### 1. AWS_ACCESS_KEY_ID
- [ ] Secret created with name: `AWS_ACCESS_KEY_ID`
- [ ] Value: Your AWS access key ID (from IAM user)
- [ ] Example: `AKIAIOSFODNN7EXAMPLE`

#### 2. AWS_SECRET_ACCESS_KEY
- [ ] Secret created with name: `AWS_SECRET_ACCESS_KEY`
- [ ] Value: Your AWS secret access key (from IAM user)
- [ ] Example: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
- [ ] ⚠️ Keep this secret safe, never commit to Git

#### 3. EC2_KEY_PAIR_NAME
- [ ] Secret created with name: `EC2_KEY_PAIR_NAME`
- [ ] Value: Your EC2 key pair name (without .pem)
- [ ] Example: `devsecops-key`
- [ ] Verified: Key pair exists in AWS EC2 console

#### 4. EC2_PRIVATE_KEY
- [ ] Secret created with name: `EC2_PRIVATE_KEY`
- [ ] Value: Full contents of your .pem file
  ```bash
  cat devsecops-key.pem  # Copy entire output
  ```
- [ ] Must include: `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`

### Verify Secrets
- [ ] All 4 secrets visible in GitHub Settings
- [ ] No typos in secret names
- [ ] All values match your AWS configuration

---

## Terraform Configuration

### Customize terraform.tfvars

Edit `terraform/terraform.tfvars` with your values:

```hcl
# AWS Configuration
aws_region = "us-east-1"

# EC2 Configuration
instance_type       = "t2.large"      # ✅ Correct for your needs
root_volume_size    = 30              # ✅ 30GB as required
root_volume_type    = "gp3"           # ✅ Keep as is

# CRITICAL: Must match your EC2 key pair
key_pair_name       = "YOUR_KEY_PAIR_NAME"  # ← Change this!
private_key_path    = "/tmp/ec2_key.pem"    # ✅ Keep for GitHub Actions

# VPC/Network Configuration
vpc_cidr       = "10.0.0.0/16"
subnet_cidr    = "10.0.1.0/24"

# GitHub Configuration
github_repo  = "https://github.com/YOUR_USERNAME/YOUR_REPO.git"  # ← Update
deploy_path  = "/home/ec2-user/devsecops-app"

# Security: SSH access control
allowed_ssh_cidr = ["0.0.0.0/0"]  # ⚠️ Change to your IP for security!
                                   # Example: ["203.0.113.45/32"]
```

### Verify Configuration
- [ ] `key_pair_name` matches EC2 key pair in AWS
- [ ] `github_repo` is correct URL to your repository
- [ ] `allowed_ssh_cidr` is updated (optional but recommended)
- [ ] File saved without syntax errors

---

## Pre-Deployment Verification

### Local Terraform Validation
```bash
cd terraform
terraform init
terraform validate
```

- [ ] `terraform init` completes without errors
- [ ] `terraform validate` returns: "Success! The configuration is valid."
- [ ] No warnings about missing variables

### AWS Credentials Verification
```bash
aws sts get-caller-identity
```

- [ ] Outputs your AWS account ID
- [ ] Outputs your IAM user ARN
- [ ] Region is correct (default: us-east-1)

### GitHub Actions Workflow Verification
- [ ] `.github/workflows/deploy-to-ec2.yml` exists in repository
- [ ] File is readable on GitHub
- [ ] Workflow shows in GitHub Actions tab

---

## Deployment Phase 1: Plan

### Trigger Plan Workflow

1. Go to GitHub repository
2. Click "Actions" tab
3. Select "Deploy to EC2 with Terraform"
4. Click "Run workflow" button
5. In dropdown, select action: `plan`
6. Click "Run workflow"

- [ ] Workflow started (check Actions tab)
- [ ] "Deploy to EC2 with Terraform" job visible
- [ ] Steps progressing (Setup Terraform → Configure AWS → Terraform Plan)

### Monitor Plan Execution

While workflow runs:
- [ ] "Terraform Init" step completes successfully
- [ ] "Terraform Validate" step passes
- [ ] "Terraform Plan" shows resources to create
- [ ] Workflow completes (green checkmark)

### Review Plan Output

After workflow completes:
- [ ] Click on "Terraform Plan" step
- [ ] Review what resources will be created:
  - [ ] 1 VPC (10.0.0.0/16)
  - [ ] 1 Subnet (10.0.1.0/24)
  - [ ] 1 Internet Gateway
  - [ ] 1 Route Table
  - [ ] 1 Security Group (8 ingress rules)
  - [ ] 1 EC2 Instance (t2.large)
  - [ ] 1 Elastic IP
- [ ] No errors in output
- [ ] "Plan saved" message visible

### Plan Artifact
- [ ] Artifact "terraform-plan" available for download
- [ ] Contains detailed plan in JSON format

---

## Deployment Phase 2: Apply

### Trigger Apply Workflow

After reviewing plan (recommended):

1. Go to GitHub repository
2. Click "Actions" tab
3. Select "Deploy to EC2 with Terraform"
4. Click "Run workflow" button
5. In dropdown, select action: `apply`
6. Click "Run workflow"

- [ ] Workflow started
- [ ] Same steps as plan, but also runs "Terraform Apply"

### Monitor Apply Execution

While workflow runs (takes 5-10 minutes):
- [ ] "Setup Terraform" completes
- [ ] "Configure AWS credentials" completes
- [ ] "Terraform Init" completes
- [ ] "Terraform Validate" completes
- [ ] "Terraform Plan" completes
- [ ] "Terraform Apply" in progress
  - [ ] VPC creation
  - [ ] Subnet creation
  - [ ] Route table creation
  - [ ] Security group creation
  - [ ] EC2 instance launch
  - [ ] Elastic IP allocation
  - [ ] User data script execution
- [ ] Workflow completes (green checkmark)

### Verify EC2 Creation

In AWS Console:
1. Go to EC2 → Instances
2. Look for instance with name: "devsecops-server"

- [ ] Instance created and running
- [ ] Instance type: t2.large ✓
- [ ] Availability Zone: us-east-1a (or your region) ✓
- [ ] Status checks: 2/2 passed ✓
- [ ] Elastic IP assigned ✓

### Get Service URLs

From GitHub Actions output:
- [ ] Frontend URL: http://`<EC2_IP>`:3000
- [ ] Backend URL: http://`<EC2_IP>`:3001
- [ ] SonarQube URL: http://`<EC2_IP>`:9000
- [ ] OWASP ZAP URL: http://`<EC2_IP>`:8082
- [ ] SSH command: ssh -i key.pem ec2-user@`<EC2_IP>`

---

## Post-Deployment Verification

### Wait for EC2 Initialization

After apply completes, wait 2-3 minutes for:
- [ ] Docker installation
- [ ] Docker Compose installation
- [ ] Repository cloning
- [ ] Services ready for startup

Check AWS Console:
- [ ] Go to EC2 → Instances → Select instance
- [ ] Click "Instance state" tab
- [ ] Status checks show: "2/2 checks passed"

### Test SSH Access
```bash
ssh -i devsecops-key.pem ec2-user@<EC2_IP>
```

- [ ] SSH connection successful
- [ ] Logged in as `ec2-user`
- [ ] Can run commands

### Verify Docker Installation
On EC2 (via SSH):
```bash
docker --version
docker-compose --version
```

- [ ] Docker version 20.10+ installed
- [ ] Docker Compose version 2.0+ installed

### Verify Repository Cloned
On EC2 (via SSH):
```bash
ls -la /home/ec2-user/devsecops-app/
```

- [ ] Directory exists
- [ ] Files visible (docker-compose.yml, backend/, frontend/, etc.)
- [ ] Git status clean: `git status`

### Start Services (if not auto-started)
On EC2 (via SSH):
```bash
cd /home/ec2-user/devsecops-app
docker-compose up -d
docker-compose ps
```

- [ ] All containers running:
  - [ ] frontend (React, port 3000)
  - [ ] api (Express, port 3001)
  - [ ] mongo (MongoDB, port 27017)
  - [ ] sonarqube (port 9000)
  - [ ] postgres (port 5432)
  - [ ] zap (OWASP ZAP, port 8082)

### Test Service Accessibility

From local machine (or EC2):
```bash
# Test backend
curl http://<EC2_IP>:3001/api/todos

# Test SonarQube (check response)
curl -I http://<EC2_IP>:9000
```

- [ ] Backend returns JSON response (empty array or todos)
- [ ] SonarQube returns HTTP 200
- [ ] All services respond

### Access Web Interfaces

1. **Frontend**: http://`<EC2_IP>`:3000
   - [ ] React app loads
   - [ ] Can see application UI

2. **Backend API**: http://`<EC2_IP>`:3001/api/todos
   - [ ] Returns JSON data
   - [ ] Can create/read todos

3. **SonarQube**: http://`<EC2_IP>`:9000
   - [ ] Login page visible
   - [ ] Can access with default credentials

4. **OWASP ZAP**: http://`<EC2_IP>`:8082
   - [ ] ZAP dashboard visible or connects via proxy

---

## Production Preparation

### Security Hardening
- [ ] Restrict SSH access: Update `allowed_ssh_cidr` to your IP only
- [ ] Enable CloudTrail for AWS API audit logging
- [ ] Configure VPC Flow Logs for network monitoring
- [ ] Enable S3 bucket for Terraform state (remote backend)

### Backup & Recovery
- [ ] Create AMI snapshot of EC2 instance
- [ ] Configure automated MongoDB backups
- [ ] Document recovery procedures

### Monitoring & Alerts
- [ ] Set up CloudWatch alarms for:
  - [ ] High CPU usage (> 80%)
  - [ ] Low disk space (< 10%)
  - [ ] Network errors
- [ ] Configure email/SNS notifications

### Cost Management
- [ ] Set AWS billing alert (threshold: $100/month)
- [ ] Document monthly cost (~$72.50 for this setup)
- [ ] Plan for seasonal scaling
- [ ] Set resource tags for cost tracking

---

## Maintenance Schedule

### Daily
- [ ] Monitor EC2 instance health
- [ ] Check GitHub Actions logs
- [ ] Review application logs: `docker-compose logs`

### Weekly
- [ ] Review CloudWatch metrics
- [ ] Check disk space on EC2
- [ ] Verify all services are running

### Monthly
- [ ] Review AWS costs
- [ ] Update security patches
- [ ] Rotate AWS credentials (quarterly)
- [ ] Test backup restoration

### Quarterly
- [ ] Rotate EC2 key pair
- [ ] Update Terraform version
- [ ] Review and update security groups
- [ ] Performance optimization review

---

## Troubleshooting Checklist

### If Workflow Fails

**"AWS credentials not found"**
- [ ] Check GitHub Secrets exist (exact names)
- [ ] Verify AWS_ACCESS_KEY_ID is valid
- [ ] Verify AWS_SECRET_ACCESS_KEY is valid
- [ ] Test locally: `aws sts get-caller-identity`

**"Key pair not found"**
- [ ] Verify EC2_KEY_PAIR_NAME in secrets
- [ ] Check key pair exists: `aws ec2 describe-key-pairs`
- [ ] Ensure name matches (case-sensitive)

**"Terraform validation failed"**
- [ ] Check terraform.tfvars syntax
- [ ] Verify all required variables are set
- [ ] Review plan output for errors

### If EC2 Doesn't Initialize

**"Services not running"**
- [ ] SSH to instance: `ssh -i key.pem ec2-user@<IP>`
- [ ] Check cloud-init logs: `tail -f /var/log/cloud-init-output.log`
- [ ] Start services: `cd /home/ec2-user/devsecops-app && docker-compose up -d`

**"Can't reach services"**
- [ ] Check security group allows ports (3000, 3001, 8082, 9000)
- [ ] Verify EC2 has internet: `ping 8.8.8.8`
- [ ] Check firewall: `sudo firewall-cmd --list-ports`

**"Disk full or low space"**
- [ ] SSH to instance
- [ ] Check space: `df -h`
- [ ] Clean Docker: `docker system prune -a`
- [ ] Or increase volume size in terraform.tfvars

### If Can't Access from Outside

- [ ] Ping EC2: `ping <EC2_IP>`
- [ ] Check security group allows your IP
- [ ] Verify Elastic IP is attached
- [ ] Test from EC2: `curl localhost:3000`

---

## Cleanup (When Done)

### Stop Costs (Non-Destructive)

In AWS Console:
- [ ] EC2 → Instances → Stop instance
- [ ] Cost reduces to ~$3/month (EBS only)
- [ ] Can restart later (no data loss)

### Full Destruction (Careful!)

Via GitHub Actions:
1. Go to Actions tab
2. Run workflow with action: `destroy`
3. Confirm deletion

Or locally:
```bash
cd terraform
terraform destroy
```

- [ ] EC2 instance terminated
- [ ] VPC and network deleted
- [ ] All resources removed
- [ ] Billing stops
- [ ] ⚠️ Cannot recover data after destruction

---

## Sign-Off

- [ ] All prerequisite setup completed
- [ ] All GitHub Secrets configured
- [ ] terraform.tfvars customized
- [ ] Plan workflow executed and reviewed
- [ ] Apply workflow executed successfully
- [ ] EC2 instance created and accessible
- [ ] All services running and responding
- [ ] SSH access verified
- [ ] Security measures implemented
- [ ] Backup strategy in place
- [ ] Monitoring configured
- [ ] Documentation reviewed

**Deployment Date**: _______________

**Deployed By**: _______________

**EC2 IP Address**: _______________

**Notes**: _______________________________________________

---

## Post-Deployment Support

If you encounter issues:

1. **Check logs**: GitHub Actions → Workflow logs
2. **Review documentation**:
   - Terraform: `terraform/README.md`
   - GitHub Actions: `GITHUB_ACTIONS_SETUP.md`
   - Jenkins: `JENKINS_EC2_SETUP.md` (if using Jenkins)
   - Credentials: `CREDENTIALS_REFERENCE.md`
3. **SSH to EC2**: `ssh -i key.pem ec2-user@<IP>`
4. **Check services**: `docker-compose ps`
5. **View logs**: `docker-compose logs <service>`

---
