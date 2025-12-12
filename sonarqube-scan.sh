#!/bin/bash

# SonarQube code quality and security scan script

echo "================================"
echo "SonarQube Code Quality Scan"
echo "================================"

# Install sonar-scanner if not present
if ! command -v sonar-scanner &> /dev/null; then
    echo "Installing sonar-scanner..."
    npm install -g sonarqube-scanner
fi

# Create reports directory
mkdir -p security/sonarqube-reports

# Run SonarQube scan
echo ""
echo "Starting SonarQube scan..."
sonar-scanner \
  -Dsonar.projectBaseDir=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin \
  -Dsonar.password=admin \
  -Dsonar.projectKey=docker-app \
  -Dsonar.projectName=Docker\ Frontend\ Backend\ Application \
  -Dsonar.sources=backend,frontend \
  -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/build/**

echo ""
echo "SonarQube scan complete. Access results at http://localhost:9000"
