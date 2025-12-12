pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }
    
    parameters {
        string(name: 'EC2_IP', defaultValue: '', description: 'EC2 Instance IP Address')
        string(name: 'EC2_USER', defaultValue: 'ec2-user', description: 'EC2 SSH User')
        string(name: 'GITHUB_REPO', defaultValue: 'https://github.com/ItsAnurag27/DevSecops-testing.git', description: 'GitHub Repository URL')
        string(name: 'SONAR_HOST', defaultValue: 'http://localhost:9000', description: 'SonarQube Host URL')
        string(name: 'SONAR_TOKEN', defaultValue: '', description: 'SonarQube Token', password: true)
    }
    
    environment {
        PROJECT_NAME = 'DevSecops-testing'
        DOCKER_REGISTRY = 'docker.io'
        SONAR_PROJECT_KEY = 'docker-app'
        EC2_DEPLOY_PATH = '/opt/devsecops'
    }
    
    stages {
        stage('Validate Inputs') {
            steps {
                script {
                    echo "=== Validating Inputs ==="
                    if (params.EC2_IP.isEmpty()) {
                        error("EC2_IP parameter is required!")
                    }
                    if (params.SONAR_TOKEN.isEmpty()) {
                        error("SONAR_TOKEN parameter is required!")
                    }
                    echo "✓ EC2 IP: ${params.EC2_IP}"
                    echo "✓ GitHub Repo: ${params.GITHUB_REPO}"
                }
            }
        }
        
        stage('Checkout Code') {
            steps {
                script {
                    echo "=== Cloning Repository ==="
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        userRemoteConfigs: [[url: params.GITHUB_REPO]]
                    ])
                    echo "✓ Code checked out successfully"
                }
            }
        }
        
        stage('Prepare EC2') {
            steps {
                script {
                    echo "=== Setting Up EC2 Instance ==="
                    sshagent(['ec2-ssh-credentials']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'EOF'
                                # Update system
                                sudo yum update -y
                                
                                # Install Docker
                                sudo yum install -y docker
                                sudo systemctl start docker
                                sudo systemctl enable docker
                                sudo usermod -a -G docker ${EC2_USER}
                                
                                # Install Docker Compose
                                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                                sudo chmod +x /usr/local/bin/docker-compose
                                
                                # Install Git
                                sudo yum install -y git
                                
                                # Create deployment directory
                                sudo mkdir -p ${EC2_DEPLOY_PATH}
                                sudo chown ${EC2_USER}:${EC2_USER} ${EC2_DEPLOY_PATH}
                                
                                echo "✓ EC2 Instance prepared successfully"
                            EOF
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                script {
                    echo "=== Deploying Application to EC2 ==="
                    sshagent(['ec2-ssh-credentials']) {
                        sh '''
                            # Copy project to EC2
                            scp -o StrictHostKeyChecking=no -r . ${EC2_USER}@${EC2_IP}:${EC2_DEPLOY_PATH}/
                            
                            # Start services
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'EOF'
                                cd ${EC2_DEPLOY_PATH}
                                
                                # Pull latest changes
                                git pull origin main
                                
                                # Start Docker services
                                docker-compose down || true
                                docker-compose up -d
                                
                                # Wait for services to start
                                sleep 30
                                
                                echo "✓ Services deployed and started"
                            EOF
                        '''
                    }
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "=== Running Health Checks ==="
                    sshagent(['ec2-ssh-credentials']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'EOF'
                                echo "Checking services status..."
                                docker-compose ps
                                
                                # Check Frontend
                                echo "Checking Frontend..."
                                curl -f http://localhost:3000 > /dev/null && echo "✓ Frontend is running" || echo "✗ Frontend failed"
                                
                                # Check Backend
                                echo "Checking Backend..."
                                curl -f http://localhost:3001/api/todos > /dev/null && echo "✓ Backend is running" || echo "✗ Backend failed"
                                
                                # Check SonarQube
                                echo "Checking SonarQube..."
                                curl -f http://localhost:9000/api/system/status > /dev/null && echo "✓ SonarQube is running" || echo "✗ SonarQube failed"
                                
                                # Check OWASP ZAP
                                echo "Checking OWASP ZAP..."
                                curl -f http://localhost:8082 > /dev/null && echo "✓ OWASP ZAP is running" || echo "✗ OWASP ZAP failed"
                            EOF
                        '''
                    }
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                script {
                    echo "=== Running SonarQube Analysis ==="
                    sshagent(['ec2-ssh-credentials']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'EOF'
                                cd ${EC2_DEPLOY_PATH}
                                
                                # Run Docker SonarQube Scanner
                                docker run --rm \
                                  -e SONAR_HOST_URL=${SONAR_HOST} \
                                  -e SONAR_TOKEN=${SONAR_TOKEN} \
                                  -v $(pwd):/usr/src \
                                  sonarsource/sonar-scanner-cli
                                
                                echo "✓ SonarQube analysis completed"
                            EOF
                        '''
                    }
                }
            }
        }
        
        stage('Trivy Scan') {
            steps {
                script {
                    echo "=== Running Trivy Vulnerability Scan ==="
                    sshagent(['ec2-ssh-credentials']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'EOF'
                                cd ${EC2_DEPLOY_PATH}
                                
                                # Install Trivy if not present
                                if ! command -v trivy &> /dev/null; then
                                    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                                    echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
                                    sudo apt-get update
                                    sudo apt-get install -y trivy
                                fi
                                
                                # Scan Docker images
                                echo "Scanning frontend image..."
                                trivy image docker-frontend-backend-db-master-web:latest || true
                                
                                echo "Scanning backend image..."
                                trivy image docker-frontend-backend-db-master-api:latest || true
                                
                                # Scan Dockerfiles
                                echo "Scanning Dockerfiles..."
                                trivy config ./frontend/Dockerfile || true
                                trivy config ./backend/Dockerfile || true
                                
                                echo "✓ Trivy scan completed"
                            EOF
                        '''
                    }
                }
            }
        }
        
        stage('OWASP ZAP Scan') {
            steps {
                script {
                    echo "=== Running OWASP ZAP Security Scan ==="
                    sshagent(['ec2-ssh-credentials']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'EOF'
                                # Verify OWASP ZAP is running
                                curl -s http://localhost:8082 > /dev/null
                                
                                if [ $? -eq 0 ]; then
                                    echo "✓ OWASP ZAP is accessible on port 8082"
                                    echo "Frontend URL: http://$(hostname -I | awk '{print $1}'):3000"
                                    echo "Backend API: http://$(hostname -I | awk '{print $1}'):3001/api"
                                    echo "SonarQube: http://$(hostname -I | awk '{print $1}'):9000"
                                    echo "OWASP ZAP: http://$(hostname -I | awk '{print $1}'):8082"
                                else
                                    echo "✗ OWASP ZAP is not responding"
                                    exit 1
                                fi
                            EOF
                        '''
                    }
                }
            }
        }
        
        stage('Generate Report') {
            steps {
                script {
                    echo "=== Generating Deployment Report ==="
                    sshagent(['ec2-ssh-credentials']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'EOF'
                                cat > /tmp/deployment-report.txt << 'REPORT'
========================================
DEVSECOPS DEPLOYMENT REPORT
========================================

Deployment Date: $(date)
EC2 Instance IP: ${EC2_IP}
Project: ${PROJECT_NAME}

SERVICES STATUS:
$(docker-compose ps)

URLS TO ACCESS:
- Frontend: http://${EC2_IP}:3000
- Backend API: http://${EC2_IP}:3001/api
- SonarQube: http://${EC2_IP}:9000
- OWASP ZAP: http://${EC2_IP}:8082

SECURITY TOOLS:
✓ SonarQube - Code Quality Analysis
✓ Trivy - Container Vulnerability Scanning
✓ OWASP ZAP - Web Application Security Testing

NEXT STEPS:
1. Access SonarQube at http://${EC2_IP}:9000
2. Login with admin/admin
3. Check code analysis results
4. Review Trivy vulnerability reports
5. Configure OWASP ZAP for active scanning

========================================
REPORT
                                cat /tmp/deployment-report.txt
                            EOF
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "=== Cleaning Up Workspace ==="
            cleanWs()
        }
        success {
            echo "✓ Pipeline completed successfully!"
            echo "Access your application at: http://${EC2_IP}:3000"
        }
        failure {
            echo "✗ Pipeline failed. Check logs for details."
        }
    }
}
