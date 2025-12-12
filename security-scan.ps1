# Security scanning script for Windows PowerShell
# Runs: SonarQube, Trivy, and OWASP ZAP scans

param(
    [string]$ScanType = "all",  # all, sonarqube, trivy, owasp
    [string]$SonarHost = "http://localhost:9000",
    [string]$SonarLogin = "admin",
    [string]$SonarPassword = "admin"
)

# Colors for output
$colors = @{
    'Green'  = "`e[32m"
    'Yellow' = "`e[33m"
    'Red'    = "`e[31m"
    'Reset'  = "`e[0m"
}

function Write-Header {
    param([string]$Text)
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  $Text" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Yellow
}

function Write-Step {
    param([string]$Text)
    Write-Host ""
    Write-Host "$([char]27)[33mStep: $Text$([char]27)[0m" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "$([char]27)[32m✓ $Text$([char]27)[0m" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "$([char]27)[31m✗ $Text$([char]27)[0m" -ForegroundColor Red
}

# Start
Write-Header "Security Scanning Pipeline for Windows"

# Create security reports directory
Write-Step "Creating security reports directories..."
$reportDirs = @(
    "security\sonarqube-reports",
    "security\trivy-reports",
    "security\owasp-reports"
)

foreach ($dir in $reportDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "Created $dir"
    }
}

# Function to run SonarQube scan
function Invoke-SonarQubeScan {
    Write-Step "Running SonarQube Code Quality Scan..."
    
    # Check if sonar-scanner is installed
    $sonarScannerPath = (Get-Command sonar-scanner -ErrorAction SilentlyContinue).Source
    
    if (-not $sonarScannerPath) {
        Write-Host "Installing sonar-scanner globally..." -ForegroundColor Yellow
        npm install -g sonarqube-scanner
    }
    
    Write-Host "Waiting for SonarQube to be ready..." -ForegroundColor Yellow
    
    # Check SonarQube health
    $maxRetries = 30
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        try {
            $response = Invoke-WebRequest -Uri "$SonarHost/api/system/status" -UseBasicParsing -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $content = $response.Content | ConvertFrom-Json
                if ($content.status -eq "UP") {
                    Write-Success "SonarQube is ready!"
                    break
                }
            }
        }
        catch {
            # Silently continue
        }
        
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "Waiting... ($retryCount/$maxRetries)" -ForegroundColor Gray
            Start-Sleep -Seconds 2
        }
    }
    
    if ($retryCount -eq $maxRetries) {
        Write-Error-Custom "SonarQube did not become ready in time"
        return
    }
    
    # Run sonar-scanner
    Write-Host "Starting SonarQube scan..." -ForegroundColor Cyan
    sonar-scanner `
        -Dsonar.projectBaseDir=. `
        -Dsonar.host.url=$SonarHost `
        -Dsonar.login=$SonarLogin `
        -Dsonar.password=$SonarPassword `
        -Dsonar.projectKey=docker-app `
        -Dsonar.projectName="Docker Frontend Backend Application" `
        -Dsonar.sources=backend,frontend `
        -Dsonar.exclusions="**/node_modules/**,**/dist/**,**/build/**"
    
    Write-Success "SonarQube scan complete"
    Write-Host "Access results at: $SonarHost" -ForegroundColor Cyan
}

# Function to run Trivy scan
function Invoke-TrivyScan {
    Write-Step "Running Trivy Container Image Scans..."
    
    # Check if trivy is installed
    $trivyPath = (Get-Command trivy -ErrorAction SilentlyContinue).Source
    
    if (-not $trivyPath) {
        Write-Host "Trivy is not installed. Please install it from: https://github.com/aquasecurity/trivy/releases" -ForegroundColor Red
        Write-Host "After installation, run this script again." -ForegroundColor Yellow
        return
    }
    
    $images = @(
        @{Name = "Backend"; Image = "docker-frontend-backend-db-master-api:latest"; Output = "security\trivy-reports\backend-scan.json"},
        @{Name = "Frontend"; Image = "docker-frontend-backend-db-master-web:latest"; Output = "security\trivy-reports\frontend-scan.json"},
        @{Name = "MongoDB"; Image = "mongo:latest"; Output = "security\trivy-reports\mongodb-scan.json"}
    )
    
    foreach ($imageInfo in $images) {
        Write-Host "Scanning $($imageInfo.Name) image..." -ForegroundColor Cyan
        trivy image --severity HIGH,CRITICAL `
            --format json `
            --output $imageInfo.Output `
            $imageInfo.Image
        Write-Success "$($imageInfo.Name) scan complete"
    }
    
    Write-Success "Trivy scans complete. Reports saved to security/trivy-reports/"
}

# Function to run OWASP ZAP scan
function Invoke-OWASPScan {
    Write-Step "Setting up OWASP ZAP Scan..."
    
    Write-Host "OWASP ZAP is running on port 8080 (proxy) and 8090 (API)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To run an automated scan, use:" -ForegroundColor Yellow
    Write-Host 'docker exec $(docker-compose ps -q owasp-zap) zap-webdriver.py -t http://web:3000 -r /root/reports/owasp-report.html' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or for manual testing:" -ForegroundColor Yellow
    Write-Host "1. Configure your browser proxy to http://localhost:8080" -ForegroundColor Cyan
    Write-Host "2. Access http://localhost:3000" -ForegroundColor Cyan
    Write-Host "3. Use ZAP GUI at http://localhost:8090 to run scans" -ForegroundColor Cyan
    Write-Host "4. Export reports from ZAP" -ForegroundColor Cyan
}

# Function to generate summary report
function Generate-SummaryReport {
    Write-Step "Generating Security Summary Report..."
    
    $reportContent = @"
# Security Scan Report - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

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
"@
    
    Set-Content -Path "security\SECURITY-REPORT.md" -Value $reportContent
    Write-Success "Summary report generated at security/SECURITY-REPORT.md"
}

# Main execution
try {
    Write-Step "Starting Docker services..."
    $dockerStatus = docker-compose ps --services
    
    if ($dockerStatus) {
        Write-Success "Docker services are running"
    } else {
        Write-Host "Starting services with docker-compose up -d..." -ForegroundColor Yellow
        docker-compose up -d
        Start-Sleep -Seconds 15
    }
    
    # Run requested scans
    if ($ScanType -eq "all" -or $ScanType -eq "sonarqube") {
        Invoke-SonarQubeScan
    }
    
    if ($ScanType -eq "all" -or $ScanType -eq "trivy") {
        Invoke-TrivyScan
    }
    
    if ($ScanType -eq "all" -or $ScanType -eq "owasp") {
        Invoke-OWASPScan
    }
    
    # Generate summary
    Generate-SummaryReport
    
    Write-Host ""
    Write-Success "Security scanning setup complete!"
    Write-Host ""
    Write-Host "Access Points:" -ForegroundColor Green
    Write-Host "  - SonarQube Dashboard: http://localhost:9000" -ForegroundColor Cyan
    Write-Host "  - Frontend: http://localhost:3000" -ForegroundColor Cyan
    Write-Host "  - Backend API: http://localhost:3001" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To view logs: docker-compose logs -f [service-name]" -ForegroundColor Yellow
    Write-Host "To stop services: docker-compose down" -ForegroundColor Yellow
}
catch {
    Write-Error-Custom "An error occurred: $_"
    exit 1
}
