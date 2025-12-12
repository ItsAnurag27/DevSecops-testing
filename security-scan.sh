#!/bin/bash

# Complete security scanning script
# Runs: SonarQube, Trivy, and OWASP ZAP scans

set -e

echo "╔════════════════════════════════════════════════════╗"
echo "║   Security Scanning Pipeline - Full Automation    ║"
echo "╚════════════════════════════════════════════════════╝"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create security reports directory
mkdir -p security/{sonarqube-reports,trivy-reports,owasp-reports}

# Step 1: Start Docker containers
echo -e "\n${YELLOW}Step 1: Starting Docker services...${NC}"
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 15

# Step 2: Run Trivy image scans
echo -e "\n${YELLOW}Step 2: Running Trivy container image scans...${NC}"
bash trivy-scan.sh

# Step 3: Run SonarQube scan
echo -e "\n${YELLOW}Step 3: Running SonarQube code quality scan...${NC}"
# Wait for SonarQube to be ready
echo "Waiting for SonarQube to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:9000/api/system/status | grep -q '"status":"UP"'; then
    echo "SonarQube is ready!"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done

bash sonarqube-scan.sh

# Step 4: OWASP ZAP scan (optional - requires manual setup)
echo -e "\n${YELLOW}Step 4: OWASP ZAP scan available${NC}"
echo "To run OWASP ZAP scanning:"
echo "  1. Ensure the application is running (docker-compose up)"
echo "  2. Run: docker exec docker-app-owasp-zap zap-webdriver.py -t http://web:3000 -r /root/reports/owasp-report.html"
echo "  3. Results will be available in security/owasp-reports/"

# Step 5: Generate summary report
echo -e "\n${YELLOW}Step 5: Generating security summary...${NC}"
cat > security/SECURITY-REPORT.md << 'EOF'
# Security Scan Report

## Summary
This report contains results from automated security scanning tools.

## Tools Used
1. **SonarQube** - Code quality and security analysis
   - URL: http://localhost:9000
   - Default credentials: admin/admin

2. **Trivy** - Container image vulnerability scanning
   - Reports: security/trivy-reports/

3. **OWASP ZAP** - Web application security scanning
   - Reports: security/owasp-reports/

## Reports Location
- SonarQube Reports: security/sonarqube-reports/
- Trivy Reports: security/trivy-reports/
- OWASP Reports: security/owasp-reports/

## Next Steps
1. Review SonarQube findings at http://localhost:9000
2. Check Trivy reports for container vulnerabilities
3. Run OWASP ZAP for web application testing
4. Address critical and high-severity issues

## Recommendations
- Update vulnerable dependencies
- Fix code quality issues identified by SonarQube
- Implement security headers in frontend/backend
- Add authentication and authorization checks
- Enable HTTPS in production
EOF

echo -e "\n${GREEN}✓ Security scanning setup complete!${NC}"
echo ""
echo "Access Points:"
echo "  - SonarQube Dashboard: http://localhost:9000"
echo "  - Frontend: http://localhost:3000"
echo "  - Backend API: http://localhost:3001"
echo ""
echo "Next steps:"
echo "  1. Review SonarQube findings"
echo "  2. Check Trivy reports for vulnerabilities"
echo "  3. Run OWASP ZAP for web application testing"
