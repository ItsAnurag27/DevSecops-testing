# Jenkins Pipeline Deployment to EC2 - Complete Setup Guide

## Overview
This guide explains how to set up a Jenkins pipeline that automatically deploys your DevSecOps application to AWS EC2 with SonarQube, Trivy, and OWASP ZAP.

---

## Prerequisites

### 1. AWS EC2 Instance
- **AMI**: Amazon Linux 2 or Ubuntu 20.04+
- **Instance Type**: t3.medium (minimum)
- **Storage**: 30GB
- **Security Group**: Open ports:
  - 22 (SSH)
  - 80 (HTTP)
  - 443 (HTTPS)
  - 3000 (Frontend)
  - 3001 (Backend API)
  - 8081 (Jenkins on EC2 - optional)
  - 8082 (OWASP ZAP)
  - 9000 (SonarQube)
  - 27017 (MongoDB - internal only)

### 2. Jenkins Server
- Jenkins 2.400+ installed
- Plugins installed:
  - SSH Agent
  - Git
  - SonarQube Scanner
  - Docker
  - Pipeline

### 3. GitHub Account
- Repository: https://github.com/ItsAnurag27/DevSecops-testing.git
- SSH key or Personal Access Token

---

## Step 1: Create EC2 SSH Credentials in Jenkins

### Generate SSH Key Pair (on your local machine)
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ec2-devsecops
# Save without passphrase (or set one)
```

### Add EC2 Public Key to Instance
```bash
# SSH into your EC2 instance
ssh -i /path/to/ec2-key.pem ec2-user@your-ec2-ip

# Add your public key
cat >> ~/.ssh/authorized_keys << EOF
[PASTE CONTENT OF ~/.ssh/ec2-devsecops.pub HERE]
EOF

chmod 600 ~/.ssh/authorized_keys
```

### Add Private Key to Jenkins Credentials
1. Go to Jenkins Dashboard → **Manage Jenkins** → **Manage Credentials**
2. Click **"Global credentials (unrestricted)"**
3. Click **"Add Credentials"**
4. Select: **SSH Username with private key**
5. Fill in:
   - **Credentials ID**: `ec2-ssh-credentials`
   - **Username**: `ec2-user` (or `ubuntu` for Ubuntu AMI)
   - **Private Key**: Paste content of `~/.ssh/ec2-devsecops`
   - **Passphrase**: (if you set one)
6. Click **"Create"**

---

## Step 2: Create SonarQube Token

### In SonarQube (running on your local machine or EC2)
1. Go to http://localhost:9000 (or your SonarQube URL)
2. Login with **admin/admin**
3. Go to **Profile** → **My Account** → **Security** → **Tokens**
4. Enter name: `jenkins-token`
5. Click **"Generate"**
6. **Copy the token** (you'll need it in Jenkins)

**Example token format:**
```
squ_1234567890abcdefghijklmnopqrstuvwxyz
```

---

## Step 3: Create Jenkins Pipeline Job

### Create New Pipeline Job
1. Click **"New Item"** on Jenkins home
2. Enter name: `DeployToEC2-DevSecOps`
3. Select **"Pipeline"**
4. Click **"OK"**

### Configure Pipeline
1. Go to **Pipeline** section
2. Select: **Pipeline script from SCM**
3. Fill in:
   - **SCM**: Git
   - **Repository URL**: `https://github.com/ItsAnurag27/DevSecops-testing.git`
   - **Credentials**: (create GitHub credentials if needed)
   - **Branch**: `*/main`
   - **Script Path**: `Jenkinsfile`

4. Click **"Save"**

---

## Step 4: Set Pipeline Parameters

When you run the pipeline, you'll be asked for:

| Parameter | Value | Description |
|-----------|-------|-------------|
| **EC2_IP** | `your-ec2-public-ip` | Your EC2 instance public IP |
| **EC2_USER** | `ec2-user` | SSH user (ec2-user for Amazon Linux, ubuntu for Ubuntu) |
| **GITHUB_REPO** | `https://github.com/ItsAnurag27/DevSecops-testing.git` | Your GitHub repo URL |
| **SONAR_HOST** | `http://your-ec2-ip:9000` | SonarQube server URL |
| **SONAR_TOKEN** | `squ_xxxx...` | SonarQube authentication token |

---

## Step 5: All Required Credentials Summary

### 1. **EC2 SSH Key**
   - **Type**: SSH Username with private key
   - **Credentials ID**: `ec2-ssh-credentials`
   - **Where**: Jenkins → Manage Credentials → Global credentials
   - **What to provide**: Private SSH key (starts with -----BEGIN RSA PRIVATE KEY-----)

### 2. **SonarQube Token**
   - **Type**: Secret text
   - **Credentials ID**: `sonar-token`
   - **Where**: Jenkins → Manage Credentials → Global credentials
   - **What to provide**: Token from SonarQube (squ_xxxx...)
   - **How to create**: 
     - Login to SonarQube
     - Profile → My Account → Security → Tokens
     - Click Generate
     - Copy token value

### 3. **GitHub Credentials** (Optional - for private repos)
   - **Type**: Username with password or SSH key
   - **Credentials ID**: `github-credentials`
   - **Where**: Jenkins → Manage Credentials → Global credentials
   - **What to provide**: GitHub username + Personal Access Token (or SSH key)

### 4. **EC2 Instance Details**
   - **EC2_IP**: Your EC2 public IP address
   - **EC2_USER**: `ec2-user` (Amazon Linux) or `ubuntu` (Ubuntu)
   - **EC2_KEY_PAIR**: Name of EC2 key pair (for SSH access)

---

## Step 6: Run the Pipeline

### Option A: Run from Jenkins Web UI
1. Go to Jenkins Dashboard
2. Find **"DeployToEC2-DevSecOps"** job
3. Click **"Build with Parameters"**
4. Fill in the parameters:
   ```
   EC2_IP: 54.123.45.67
   EC2_USER: ec2-user
   GITHUB_REPO: https://github.com/ItsAnurag27/DevSecops-testing.git
   SONAR_HOST: http://54.123.45.67:9000
   SONAR_TOKEN: squ_b0bbdaae27b077cc6b8e5c876f89a846ac35b6e2
   ```
5. Click **"Build"**

### Option B: Monitor Pipeline Progress
1. Click the build number (e.g., **#1**)
2. Click **"Console Output"**
3. Watch the deployment in real-time

---

## Step 7: Access Services on EC2

After deployment completes, access your services:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frontend** | `http://54.123.45.67:3000` | None (public) |
| **Backend API** | `http://54.123.45.67:3001/api` | None (CORS enabled) |
| **SonarQube** | `http://54.123.45.67:9000` | admin / admin |
| **OWASP ZAP** | `http://54.123.45.67:8082` | Proxy settings |
| **MongoDB** | Internal only | mongodb://localhost:27017/todos |

---

## Step 8: Configure SonarQube Quality Gates (Optional)

1. Go to SonarQube Dashboard
2. Create project:
   - **Project key**: `docker-app`
   - **Display name**: `DevSecOps App`

3. Set Quality Gate:
   - Go to **Quality Gates**
   - Select **Sonar way**
   - Apply to your project

4. View analysis results:
   - Go to your project
   - See issues, vulnerabilities, code smells

---

## Troubleshooting

### Issue: "Authentication failed" in Jenkins
**Solution**: 
- Verify EC2 SSH credentials ID matches `ec2-ssh-credentials`
- Check EC2 security group allows SSH (port 22)
- Test SSH connection manually: `ssh -i key.pem ec2-user@your-ip`

### Issue: "SonarQube not responding"
**Solution**:
- Check SonarQube is running on EC2: `docker-compose logs sonarqube`
- Verify EC2 security group allows port 9000
- Check SONAR_TOKEN is valid

### Issue: "Pipeline fails at health check"
**Solution**:
- Wait longer for services to start (add more sleep time)
- Check Docker logs: `docker-compose logs`
- Verify all ports are open in EC2 security group

### Issue: "Docker daemon not running"
**Solution**:
- SSH into EC2
- Start Docker: `sudo systemctl start docker`
- Enable on startup: `sudo systemctl enable docker`

---

## Environment Variables in Pipeline

The pipeline uses these environment variables (set at EC2 level):

```bash
# On EC2, these are set by Jenkinsfile
EC2_DEPLOY_PATH=/opt/devsecops
PROJECT_NAME=DevSecops-testing
SONAR_PROJECT_KEY=docker-app
DOCKER_REGISTRY=docker.io
```

---

## Security Best Practices

1. **Never commit secrets**: SSH keys and tokens should be in Jenkins Credentials, not in Jenkinsfile
2. **Use IAM roles**: Attach EC2 IAM role for S3 access (if needed)
3. **Restrict security group**: Only allow SSH from your IP
4. **Rotate tokens**: Regenerate SonarQube token every 90 days
5. **Enable Jenkins authentication**: Always require login for Jenkins
6. **Use HTTPS**: Configure HTTPS for Jenkins if using over internet

---

## Next Steps

1. ✅ Create EC2 SSH credentials in Jenkins
2. ✅ Generate SonarQube token
3. ✅ Create Jenkins Pipeline job
4. ✅ Run the pipeline
5. ✅ Access services on EC2
6. ✅ Configure quality gates in SonarQube
7. ✅ Set up GitHub webhooks for CI/CD

---

## Questions?

Refer to:
- **Jenkins Docs**: https://www.jenkins.io/doc/
- **SonarQube Docs**: https://docs.sonarqube.org/
- **AWS EC2 Docs**: https://docs.aws.amazon.com/ec2/
- **Docker Compose**: https://docs.docker.com/compose/
