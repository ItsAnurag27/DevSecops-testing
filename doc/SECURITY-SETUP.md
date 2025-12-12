# Security Implementation Guide

This document explains how to use SonarQube, OWASP, and Trivy for securing your 3-tier application.

## Overview

Three security tools are integrated into your application:

### 1. **SonarQube** - Code Quality & Security Analysis
- Analyzes code for vulnerabilities and quality issues
- Provides detailed reports and metrics
- Dashboard for tracking improvements
- **Port:** 9000
- **Default Credentials:** admin/admin

### 2. **Trivy** - Container Image Vulnerability Scanner
- Scans Docker images for known vulnerabilities
- Identifies CVEs in dependencies
- Fast and lightweight
- **Usage:** Command-line scanning

### 3. **OWASP ZAP** - Web Application Security Scanning
- Tests running web applications
- Identifies OWASP Top 10 vulnerabilities
- Automated and manual scanning capabilities
- **Port:** 8080 (Proxy), 8090 (API)

---

## Quick Start

### Step 1: Start All Services with Security Tools

```bash
# Windows PowerShell
docker-compose up -d

# Linux/Mac
docker-compose up -d
```

This will start:
- Frontend (React) - http://localhost:3000
- Backend (Node.js) - http://localhost:3001
- Database (MongoDB)
- SonarQube - http://localhost:9000
- PostgreSQL (SonarQube DB)
- OWASP ZAP

### Step 2: Access SonarQube Dashboard

1. Open http://localhost:9000
2. Login with credentials:
   - Username: `admin`
   - Password: `admin`
3. Change password on first login (recommended)

### Step 3: Run Code Quality Scan

```bash
# Prerequisites: Install Node.js global packages
npm install -g sonarqube-scanner

# Run the scan
bash sonarqube-scan.sh
```

Or use the automated script:
```bash
bash security-scan.sh
```

### Step 4: Scan Container Images with Trivy

```bash
# Install Trivy (Windows)
# Download from: https://github.com/aquasecurity/trivy/releases

# Run scans
bash trivy-scan.sh
```

---

## Detailed Setup Instructions

### Windows Setup

#### Install Trivy
```powershell
# Using Chocolatey
choco install trivy

# Or download from GitHub
# https://github.com/aquasecurity/trivy/releases
```

#### Install SonarQube Scanner
```powershell
npm install -g sonarqube-scanner
```

#### Run Full Security Scan
```powershell
# Convert bash script to PowerShell and run
bash security-scan.sh

# Or run individual scans
bash sonarqube-scan.sh
bash trivy-scan.sh
```

### Linux/Mac Setup

#### Install Trivy
```bash
# Using package manager
brew install trivy  # Mac
apt-get install trivy  # Ubuntu/Debian

# Or download from GitHub
```

#### Install SonarQube Scanner
```bash
npm install -g sonarqube-scanner
```

#### Run Scans
```bash
chmod +x *.sh
bash security-scan.sh
```

---

## SonarQube Configuration

### Default Setup
- **URL:** http://localhost:9000
- **Database:** PostgreSQL (sonardb)
- **Project Key:** docker-app
- **Sources:** backend/, frontend/

### Initial Configuration

1. **First Login:**
   - Username: `admin`
   - Password: `admin`
   - Change password when prompted

2. **Create Project:**
   - Manually in UI or automatic via scanner
   - Project Key: `docker-app`

3. **Add Quality Gates:**
   - Set minimum coverage percentage
   - Set allowed issues threshold
   - Configure security hotspot requirements

4. **Configure Plugins (Optional):**
   - Go to Administration → Marketplace
   - Install Node.js, React, or other language plugins

---

## Trivy Scanning

### Scan Docker Images

```bash
# Scan a specific image
trivy image --severity HIGH,CRITICAL docker-image-name

# Scan with detailed report
trivy image --format json --output report.json docker-image-name

# Scan with HTML report
trivy image --format sarif --output report.sarif docker-image-name
```

### Scan Filesystem

```bash
# Scan application dependencies
trivy fs ./backend
trivy fs ./frontend
```

### Ignore Vulnerabilities

Create `.trivyignore` file:
```
# Ignore specific CVEs
CVE-2021-1234
CVE-2021-5678
```

---

## OWASP ZAP Scanning

### Manual Scanning

```bash
# Start ZAP in daemon mode
docker-compose up owasp-zap

# Run scan against your application
docker exec docker-app-owasp-zap zap-webdriver.py \
  -t http://web:3000 \
  -r /root/reports/owasp-report.html
```

### Configure ZAP Proxy

1. Point browser proxy to `http://localhost:8080`
2. Access your application through the proxy
3. ZAP will passively scan all traffic
4. Export reports from ZAP UI

### OWASP Top 10 Coverage
ZAP checks for:
- Injection attacks
- Broken authentication
- Sensitive data exposure
- XML External Entities (XXE)
- Broken access control
- Security misconfiguration
- Cross-site scripting (XSS)
- Insecure deserialization
- Using components with known vulnerabilities
- Insufficient logging

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Security Scans

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Run Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v1
        with:
          sarif_file: 'trivy-results.sarif'
```

---

## Reports and Results

### SonarQube Reports
- Location: `security/sonarqube-reports/`
- Accessible via: http://localhost:9000
- Metrics: Code coverage, bugs, vulnerabilities, code smells

### Trivy Reports
- Location: `security/trivy-reports/`
- Format: JSON, SARIF
- Contents: CVE details, severity levels, affected components

### OWASP ZAP Reports
- Location: `security/owasp-reports/`
- Format: HTML, XML
- Contents: Vulnerabilities found, risk ratings, remediation guidance

---

## Remediation Workflow

1. **Review Findings:**
   - SonarQube: Code quality issues and security hotspots
   - Trivy: Container vulnerabilities
   - OWASP ZAP: Web application vulnerabilities

2. **Prioritize Issues:**
   - Critical/High severity first
   - Security vulnerabilities before code quality
   - Quick wins that reduce risk

3. **Fix Issues:**
   - Update dependencies: `npm audit fix`
   - Refactor code based on SonarQube recommendations
   - Apply security patches

4. **Re-scan:**
   - Run scans after fixes
   - Verify vulnerabilities are resolved
   - Track progress over time

---

## Best Practices

### Code Quality
- ✓ Maintain code coverage > 80%
- ✓ Keep duplication low (< 3%)
- ✓ Address security hotspots immediately
- ✓ Review SonarQube reports regularly

### Container Security
- ✓ Use specific base image versions (not `latest`)
- ✓ Scan images before deploying
- ✓ Keep dependencies updated
- ✓ Use minimal base images (alpine)

### Application Security
- ✓ Implement security headers
- ✓ Use HTTPS in production
- ✓ Validate all inputs
- ✓ Sanitize outputs
- ✓ Implement proper authentication
- ✓ Use parameterized queries

---

## Troubleshooting

### SonarQube Not Starting
```bash
# Check logs
docker-compose logs sonarqube

# Ensure sufficient disk space and memory
# SonarQube requires at least 2GB RAM
```

### Trivy Installation Issues
- Update to latest version: `trivy image --version`
- Check internet connectivity for vulnerability database

### OWASP ZAP Connection Issues
- Ensure application is running before ZAP scan
- Check network connectivity between containers
- Verify DNS resolution

---

## Additional Resources

- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Trivy GitHub](https://github.com/aquasecurity/trivy)
- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [OWASP Top 10](https://owasp.org/Top10/)
- [CWE Top 25](https://cwe.mitre.org/top25/)

---

## Support Commands

```bash
# Check Docker service status
docker-compose ps

# View logs for specific service
docker-compose logs sonarqube
docker-compose logs api
docker-compose logs web

# Stop all services
docker-compose down

# Remove volumes (careful!)
docker-compose down -v

# Restart services
docker-compose restart
```
