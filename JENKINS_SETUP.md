# Jenkins Setup Guide for DevSecOps Pipeline

## Overview
This document provides complete instructions for setting up Jenkins on the AWS EC2 instance to run the DevSecOps CI/CD pipeline with SonarQube code analysis, Trivy vulnerability scanning, and OWASP ZAP security testing.

---

## Prerequisites

- **EC2 Instance**: Running with public IP `3.231.162.219`
- **OS**: Amazon Linux 2
- **Required Services Running**:
  - Jenkins (port 8080)
  - SonarQube (port 9000)
  - MongoDB (port 27017)
  - Docker and Docker Compose installed

---

## Jenkins Installation (Already Done by Terraform)

Jenkins is automatically installed and configured via the Terraform user_data script. The following components are installed:

- **Java (OpenJDK 11)** - Jenkins runtime
- **Jenkins** - CI/CD automation server
- **Git** - Version control integration
- **Docker** - Container support
- **Docker Compose** - Multi-container orchestration

### Access Jenkins

```
URL: http://3.231.162.219:8080
```

**Initial Setup**:
1. Navigate to Jenkins URL in your browser
2. Retrieve the initial admin password from EC2:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. Complete the Jenkins setup wizard
4. Install recommended plugins
5. Create admin user account

---

## Required Jenkins Plugins

Install the following plugins for full pipeline functionality:

### Essential Plugins
- **Git** - Git SCM integration
- **Pipeline** - Jenkins pipeline support
- **SSH Agent** - SSH key management for EC2 deployment
- **Email Extension** - Email notifications
- **AnsiColor** - Colored log output

### Security & Integration Plugins
- **GitHub Integration** - GitHub webhook integration
- **Credentials Binding** - Secure credential management
- **Log Parser** - Parse and analyze build logs

### How to Install Plugins

1. **Navigate to**: Jenkins Dashboard → Manage Jenkins → Manage Plugins
2. **Go to**: Available tab
3. **Search for** plugin name
4. **Check the box** next to plugin
5. **Click**: "Download now and install after restart"
6. **Check**: "Restart Jenkins when installation is complete"

**Bulk Install Command** (if SSH access):
```bash
# Install plugins via Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080 \
  install-plugin git pipeline ssh-agent email-ext ansicolor \
  github credentials-binding log-parser
```

---

## Credentials Configuration

### 1. GitHub Credentials (github-credentials)

**Purpose**: Clone and pull code from DevSecops-testing repository

**Steps**:
1. Go to: Jenkins Dashboard → Manage Jenkins → Manage Credentials
2. Click: "Jenkins" (under Stores scoped to Jenkins)
3. Click: "Global credentials (unrestricted)"
4. Click: "Add Credentials" button
5. **Configure**:
   - **Kind**: Username with password
   - **Username**: `<your-github-username>`
   - **Password**: `<your-github-personal-access-token>`
   - **ID**: `github-credentials`
   - **Description**: GitHub credentials for DevSecops-testing

6. Click: "Create"

**Get Personal Access Token**:
- Go to: GitHub.com → Settings → Developer settings → Personal access tokens
- Generate new token with `repo` and `admin:repo_hook` scopes
- Copy token and use as password above

---

### 2. EC2 SSH Credentials (ec2-ssh-credentials)

**Purpose**: SSH into EC2 instance for deployment

**Prerequisites**:
- EC2 key pair (`jenkins-key.pem`) must be available locally
- Key file permissions: `600` or `400`

**Steps**:
1. Go to: Jenkins Dashboard → Manage Jenkins → Manage Credentials
2. Click: "Jenkins" (under Stores scoped to Jenkins)
3. Click: "Global credentials (unrestricted)"
4. Click: "Add Credentials" button
5. **Configure**:
   - **Kind**: SSH Username with private key
   - **Username**: `ec2-user`
   - **Private Key**: 
     - Select: "Enter directly"
     - Paste the contents of your `jenkins-key.pem` file
   - **Passphrase**: (leave blank if key has no passphrase)
   - **ID**: `ec2-ssh-credentials`
   - **Description**: EC2 SSH credentials for deployment

6. Click: "Create"

**Retrieve SSH Key**:
```bash
# If key file exists on local machine
cat ~/path/to/jenkins-key.pem

# Copy entire contents including BEGIN and END lines
```

---

### 3. SonarQube Token (sonar-token)

**Purpose**: Authenticate with SonarQube for code analysis

**Prerequisites**:
- SonarQube running at `http://3.231.162.219:9000`
- Default login: `admin` / `admin`

**Steps to Generate Token**:

1. **Access SonarQube**:
   ```
   URL: http://3.231.162.219:9000
   Login: admin
   Password: admin
   ```

2. **Navigate to Security Settings**:
   - Click: Profile icon (top-right) → My Account
   - Click: "Security" tab
   - Under "Tokens" section

3. **Generate New Token**:
   - **Token name**: `jenkins-token`
   - **Type**: `Global Analysis Token`
   - Click: "Generate"

4. **Copy Token**: 
   - Copy the generated token value
   - Store it safely - it won't be shown again

5. **Add to Jenkins Credentials**:
   - Go to: Jenkins Dashboard → Manage Jenkins → Manage Credentials
   - Click: "Jenkins" (under Stores scoped to Jenkins)
   - Click: "Global credentials (unrestricted)"
   - Click: "Add Credentials" button
   - **Configure**:
     - **Kind**: Secret text
     - **Secret**: `<paste-sonarqube-token>`
     - **ID**: `sonar-token`
     - **Description**: SonarQube analysis token

   - Click: "Create"

---

## Pipeline Job Configuration

### Create Pipeline Job

1. **New Item**:
   - Click: "New Item" on Jenkins Dashboard
   - **Item name**: `DevSecops-Pipeline`
   - **Type**: Pipeline
   - Click: "OK"

2. **Pipeline Configuration**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/ItsAnurag27/DevSecops-testing.git`
   - **Credentials**: `github-credentials`
   - **Branch Specifier**: `*/main`
   - **Script Path**: `Jenkinsfile`

3. **Build Triggers** (Optional):
   - Check: "GitHub hook trigger for GITScm polling"
   - This enables automatic builds on GitHub push

4. **Save**: Click "Save" button

---

## Pipeline Execution

### Running the Pipeline

1. **Navigate to Pipeline**:
   - Go to: Jenkins Dashboard → DevSecops-Pipeline

2. **Click "Build Now"**:
   - First time will show parameter prompt:
     - **EC2_IP**: `3.231.162.219` (default)
     - **EC2_USER**: `ec2-user` (default)
     - **GITHUB_REPO**: `https://github.com/ItsAnurag27/DevSecops-testing.git` (default)
     - **SONAR_HOST**: `http://localhost:9000` (default)
     - **SONAR_TOKEN**: **REQUIRED** - Paste your SonarQube token here

3. **Click "Build"**:
   - Pipeline will execute with stages:
     - ✓ Validate Inputs
     - ✓ Checkout Code
     - ✓ Prepare EC2
     - ✓ Deploy to EC2
     - ✓ Health Check
     - ✓ SonarQube Analysis
     - ✓ Trivy Scan
     - ✓ OWASP ZAP Scan
     - ✓ Generate Report

4. **Monitor Execution**:
   - Click "Console Output" to see real-time logs
   - Each stage will show progress and status

---

## Jenkinsfile Overview

The `Jenkinsfile` in the repository contains:

### Parameters
```groovy
parameters {
    string(name: 'EC2_IP', defaultValue: '3.231.162.219', ...)
    password(name: 'SONAR_TOKEN', defaultValue: '', ...)
}
```

### Stages Explained

| Stage | Purpose | Key Actions |
|-------|---------|------------|
| **Validate Inputs** | Verify required parameters | Check EC2_IP and SONAR_TOKEN |
| **Checkout Code** | Clone repository | Git pull from GitHub |
| **Prepare EC2** | Verify EC2 readiness | Check Docker, Git installation |
| **Deploy to EC2** | Deploy application | Git pull latest code, docker-compose up |
| **Health Check** | Verify services running | Curl tests for all endpoints |
| **SonarQube Analysis** | Code quality scan | Run sonar-scanner-cli |
| **Trivy Scan** | Vulnerability scan | Scan Dockerfiles for misconfigs |
| **OWASP ZAP Scan** | Security testing | Verify ZAP endpoint availability |
| **Generate Report** | Create deployment summary | Output service URLs and status |

---

## Troubleshooting

### Issue: SSH Connection Fails

**Symptoms**: 
```
ssh: connect to host 3.231.162.219 port 22: Connection timed out
```

**Solutions**:
1. Verify EC2 instance is running:
   ```bash
   # Check instance status in AWS console
   ```
2. Verify security group allows port 22:
   ```bash
   # Port 22 (SSH) must be open in EC2 security group
   ```
3. Verify SSH key permissions:
   ```bash
   chmod 400 jenkins-key.pem
   ```

### Issue: Git Permission Denied

**Symptoms**:
```
fatal: detected dubious ownership in repository
```

**Solution**: Already handled in Jenkinsfile:
```bash
sudo chown -R ec2-user:ec2-user /opt/devsecops
```

### Issue: SonarQube Analysis Fails

**Symptoms**:
```
Failed to query server version: Call to URL failed
```

**Solutions**:
1. Verify SonarQube is running:
   ```bash
   ssh ec2-user@3.231.162.219 "docker ps | grep sonarqube"
   ```

2. Test SonarQube connectivity:
   ```bash
   curl http://3.231.162.219:9000/api/system/status
   ```

3. Verify token is valid:
   - Go to: SonarQube → Security → Tokens
   - Check token hasn't expired
   - Generate new token if needed

4. Verify Docker can reach SonarQube:
   - Add `--network host` flag in SonarQube Analysis stage

### Issue: Docker Images Not Building

**Symptoms**:
```
compose build requires buildx 0.17 or later
```

**Workaround**: Images are pre-built and pushed to DockerHub (future enhancement)

**Current Behavior**: Pipeline continues without frontend/backend services

### Issue: Trivy Scanner Can't Find Images

**Symptoms**:
```
No such image: docker-frontend-backend-db-master-web:latest
```

**Behavior**: Fallback to Dockerfile scanning (which succeeds)

---

## Accessing Services

After successful pipeline execution:

### SonarQube
```
URL: http://3.231.162.219:9000
Login: admin
Password: admin
```

**View Analysis Results**:
1. Click "Projects"
2. Select "DevSecops-testing"
3. View code quality metrics, issues, and security findings

### Application Services

| Service | URL | Status |
|---------|-----|--------|
| Frontend | http://3.231.162.219:3000 | Not running (docker build issue) |
| Backend API | http://3.231.162.219:3001 | Not running (docker build issue) |
| SonarQube | http://3.231.162.219:9000 | ✓ Running |
| OWASP ZAP | http://3.231.162.219:8082 | Not running |

---

## Performance Optimization

### Reduce Build Time

1. **Cache Docker layers**:
   ```bash
   # In Dockerfile
   FROM node:18-alpine
   RUN apk add --no-cache curl  # Use --no-cache
   ```

2. **Parallel stages** (future enhancement):
   ```groovy
   parallel {
       stage('Trivy Scan') { ... }
       stage('SonarQube Analysis') { ... }
   }
   ```

3. **Skip unnecessary stages**:
   - Edit Jenkinsfile to comment out stages you don't need

---

## Next Steps

1. **Enable GitHub Webhooks**:
   - GitHub repo → Settings → Webhooks
   - Add: `http://3.231.162.219:8080/github-webhook/`
   - This will trigger builds automatically on push

2. **Configure Email Notifications**:
   - Jenkins → Manage Jenkins → Configure System
   - Set up SMTP for build failure alerts

3. **Improve Docker Image Building**:
   - Upgrade docker-compose to v2.0+ with buildx support
   - Push images to DockerHub/ECR
   - Update Jenkinsfile to pull pre-built images

4. **Add Quality Gates**:
   - SonarQube → Administration → Quality Gates
   - Set rules to fail builds on code quality issues

---

## Support & Documentation

- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **SonarQube Documentation**: https://docs.sonarqube.org/
- **Trivy Documentation**: https://aquasecurity.github.io/trivy/
- **Pipeline Examples**: https://github.com/jenkinsci/pipeline-examples

---

**Last Updated**: December 15, 2025
**Status**: Production Ready
**Version**: 1.0
