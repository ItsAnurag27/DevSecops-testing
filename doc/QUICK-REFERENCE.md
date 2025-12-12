# Quick Reference Guide - Security Tools

## Setup (Windows)

### 1. Install Prerequisites
```powershell
# Install Trivy
choco install trivy
# OR download from: https://github.com/aquasecurity/trivy/releases

# Install SonarQube Scanner globally
npm install -g sonarqube-scanner
```

### 2. Start Services
```powershell
cd c:\Users\ms\Downloads\docker-frontend-backend-db-master\docker-frontend-backend-db-master
docker-compose up -d
```

### 3. Run Security Scans
```powershell
# Run all scans (recommended first time)
.\security-scan.ps1

# Or run specific scans
.\security-scan.ps1 -ScanType sonarqube
.\security-scan.ps1 -ScanType trivy
.\security-scan.ps1 -ScanType owasp
```

## Access Dashboards

| Tool | URL | Credentials |
|------|-----|-------------|
| SonarQube | http://localhost:9000 | admin / admin |
| Frontend | http://localhost:3000 | - |
| Backend API | http://localhost:3001 | - |
| OWASP ZAP | http://localhost:8090 | - |

## Common Tasks

### View SonarQube Results
1. Open http://localhost:9000
2. Login with admin/admin
3. Click on "docker-app" project
4. Review issues, bugs, vulnerabilities, code smells

### View Trivy Results
```powershell
# View backend scan results
Get-Content security\trivy-reports\backend-scan.json | ConvertFrom-Json

# View in PowerShell
trivy image --severity HIGH,CRITICAL docker-frontend-backend-db-master-api:latest
```

### Run Manual OWASP ZAP Scan
```powershell
# Run automated scan
$containerId = docker ps -q --filter "ancestor=owasp/zap2docker-stable"
docker exec $containerId zap-webdriver.py -t http://web:3000 -r /root/reports/owasp-report.html

# View reports
explorer.exe security\owasp-reports\
```

## Troubleshooting

### SonarQube Won't Start
```powershell
# Check logs
docker-compose logs sonarqube

# Check if port 9000 is already in use
netstat -ano | findstr :9000

# Restart services
docker-compose down
docker-compose up -d
```

### Trivy Not Found
```powershell
# Add to PATH or run full path
C:\ProgramData\chocolatey\bin\trivy.exe image --version

# Or install again
choco install trivy --force
```

### Can't Connect to Services
```powershell
# Check all services are running
docker-compose ps

# Check network
docker network ls
docker network inspect docker-frontend-backend-db-master_network-backend

# Check firewall
# Allow port: 3000, 3001, 9000, 8080, 8090
```

## Docker Compose Commands

```powershell
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f sonarqube
docker-compose logs -f api
docker-compose logs -f web

# Restart a service
docker-compose restart sonarqube

# Remove volumes (be careful!)
docker-compose down -v

# Rebuild images
docker-compose build --no-cache
docker-compose up -d
```

## Security Checklist

- [ ] SonarQube installed and running
- [ ] First scan completed successfully
- [ ] SonarQube password changed from default
- [ ] Trivy scans completed for all images
- [ ] No critical vulnerabilities in images
- [ ] OWASP ZAP scan completed
- [ ] No critical web vulnerabilities found
- [ ] Code coverage > 80%
- [ ] All "blocker" issues in SonarQube fixed
- [ ] Security report generated and reviewed

## File Structure Created

```
.
├── docker-compose.yml                 (Updated with security services)
├── sonar-project.properties           (SonarQube configuration)
├── security-scan.ps1                  (PowerShell script for Windows)
├── security-scan.sh                   (Bash script for Linux/Mac)
├── sonarqube-scan.sh                  (SonarQube scanner script)
├── trivy-scan.sh                      (Trivy scanner script)
├── SECURITY-SETUP.md                  (Detailed setup guide)
├── QUICK-REFERENCE.md                 (This file)
└── security/                          (Reports directory)
    ├── sonarqube-reports/
    ├── trivy-reports/
    └── owasp-reports/
```

## Performance Notes

- **SonarQube**: Requires ~2GB RAM, may take 5-10 minutes on first scan
- **Trivy**: Fast scanning, < 1 minute per image
- **OWASP ZAP**: Depends on application size, 5-30 minutes for full scan

## Best Practices

1. **Run scans regularly**: Daily or with every commit
2. **Fix critical issues first**: Security > Code Quality
3. **Update dependencies**: Regular `npm audit fix`
4. **Monitor trends**: Track improvements over time
5. **Integrate with CI/CD**: Automate scanning in pipelines
6. **Review reports**: Don't ignore findings
7. **Use SonarQube quality gates**: Enforce standards

## Next Steps

1. Run the security-scan.ps1 script
2. Review findings in each tool
3. Create a remediation plan
4. Fix critical issues
5. Re-scan to verify fixes
6. Integrate into CI/CD pipeline
