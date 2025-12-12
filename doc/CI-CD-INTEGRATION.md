# CI/CD Integration Examples

This document shows how to integrate SonarQube, OWASP, and Trivy into popular CI/CD platforms.

---

## GitHub Actions

### Complete Security Pipeline

Create `.github/workflows/security.yml`:

```yaml
name: Security Scanning Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  sonarqube:
    name: SonarQube Code Quality
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13-alpine
        env:
          POSTGRES_DB: sonar
          POSTGRES_USER: sonar
          POSTGRES_PASSWORD: sonar
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      sonarqube:
        image: sonarqube:latest
        env:
          SONAR_JDBC_URL: jdbc:postgresql://postgres:5432/sonar
          SONAR_JDBC_USERNAME: sonar
          SONAR_JDBC_PASSWORD: sonar
        options: >-
          --health-cmd "curl -f http://localhost:9000/api/system/status"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '14'
      
      - name: Install dependencies
        run: |
          npm install -g sonarqube-scanner
          cd frontend && npm ci && cd ..
          cd backend && npm ci && cd ..
      
      - name: SonarQube Scan
        env:
          SONAR_HOST_URL: http://sonarqube:9000
          SONAR_LOGIN: admin
          SONAR_PASSWORD: admin
        run: |
          sonar-scanner \
            -Dsonar.projectKey=docker-app \
            -Dsonar.projectName="Docker Frontend Backend Application" \
            -Dsonar.sources=backend,frontend \
            -Dsonar.exclusions="**/node_modules/**,**/dist/**,**/build/**"

  trivy-fs:
    name: Trivy Filesystem Scan
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  trivy-docker:
    name: Trivy Docker Image Scan
    runs-on: ubuntu-latest
    strategy:
      matrix:
        image:
          - image: node:14-alpine
            name: frontend-base
          - image: node:10-alpine
            name: backend-base
          - image: mongo:latest
            name: mongodb
    
    steps:
      - name: Run Trivy vulnerability scanner for ${{ matrix.image.name }}
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ matrix.image.image }}
          format: 'sarif'
          output: '${{ matrix.image.name }}-trivy-results.sarif'
      
      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: '${{ matrix.image.name }}-trivy-results.sarif'

  owasp-zap:
    name: OWASP ZAP Security Scan
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and start services
        run: docker-compose up -d
      
      - name: Wait for application
        run: sleep 30
      
      - name: Run OWASP ZAP scan
        uses: zaproxy/action-baseline@v0.7.0
        with:
          target: 'http://localhost:3000'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'
      
      - name: Upload ZAP results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: zap-scan-results
          path: report_html.html
```

---

## GitLab CI/CD

### Complete Pipeline

Create `.gitlab-ci.yml`:

```yaml
stages:
  - scan
  - report

sonarqube-scan:
  stage: scan
  image: node:14-alpine
  services:
    - postgres:13-alpine
    - sonarqube:latest
  script:
    - npm install -g sonarqube-scanner
    - cd frontend && npm ci && cd ..
    - cd backend && npm ci && cd ..
    - sonar-scanner 
        -Dsonar.projectKey=docker-app
        -Dsonar.projectName="Docker Frontend Backend Application"
        -Dsonar.sources=backend,frontend
        -Dsonar.exclusions="**/node_modules/**,**/dist/**,**/build/**"

trivy-filesystem:
  stage: scan
  image: aquasecurity/trivy:latest
  script:
    - trivy fs --format json --output trivy-fs-results.json .
  artifacts:
    paths:
      - trivy-fs-results.json

trivy-docker:
  stage: scan
  image: aquasecurity/trivy:latest
  services:
    - docker:dind
  script:
    - docker build -t frontend:latest ./frontend
    - docker build -t backend:latest ./backend
    - trivy image --format json --output trivy-frontend-results.json frontend:latest
    - trivy image --format json --output trivy-backend-results.json backend:latest
```

---

## Jenkins Pipeline

Create `Jenkinsfile`:

```groovy
pipeline {
    agent any
    
    environment {
        SONAR_HOST_URL = 'http://localhost:9000'
        SONAR_LOGIN = 'admin'
        SONAR_PASSWORD = 'admin'
    }
    
    stages {
        stage('SonarQube Scan') {
            steps {
                sh '''
                    npm install -g sonarqube-scanner
                    cd frontend && npm ci && cd ..
                    cd backend && npm ci && cd ..
                    sonar-scanner \
                        -Dsonar.projectKey=docker-app \
                        -Dsonar.projectName="Docker Frontend Backend Application" \
                        -Dsonar.sources=backend,frontend \
                        -Dsonar.exclusions="**/node_modules/**,**/dist/**,**/build/**"
                '''
            }
        }
        
        stage('Build Docker Images') {
            steps {
                sh 'docker-compose build'
            }
        }
        
        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    trivy fs --format json --output trivy-fs.json .
                    trivy fs --format sarif --output trivy-fs.sarif .
                '''
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'security/**', allowEmptyArchive: true
        }
    }
}
```

---

## Environment Variables

Add these to your CI/CD platform:

```
SONAR_HOST_URL=http://localhost:9000
SONAR_LOGIN=admin
SONAR_PASSWORD=admin
DOCKER_REGISTRY=localhost:5000
TRIVY_SEVERITY=HIGH,CRITICAL
```

---

## Quality Gates

### SonarQube Quality Gate Configuration

In SonarQube UI → Administration → Quality Gates:

- Code Coverage: > 80%
- Bugs: 0
- Critical Vulnerabilities: 0
- High Vulnerabilities: < 5
- Code Smells: < 20
- Duplicated Lines: < 5%

---

## Notifications

### Slack Notifications

```yaml
# GitHub Actions
- name: Send Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Security scans completed'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

This ensures continuous security scanning throughout your development lifecycle!
