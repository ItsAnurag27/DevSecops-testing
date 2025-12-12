#!/bin/bash

# Trivy vulnerability scanning script for container images
# This script scans both frontend and backend Docker images

echo "================================"
echo "Trivy Security Scan"
echo "================================"

# Create reports directory
mkdir -p security/trivy-reports

echo ""
echo "Scanning backend image..."
trivy image --severity HIGH,CRITICAL \
  --format json \
  --output security/trivy-reports/backend-scan.json \
  docker-frontend-backend-db-master-api:latest

echo ""
echo "Scanning frontend image..."
trivy image --severity HIGH,CRITICAL \
  --format json \
  --output security/trivy-reports/frontend-scan.json \
  docker-frontend-backend-db-master-web:latest

echo ""
echo "Scanning MongoDB image..."
trivy image --severity HIGH,CRITICAL \
  --format json \
  --output security/trivy-reports/mongodb-scan.json \
  mongo:latest

echo ""
echo "Scan complete. Reports saved to security/trivy-reports/"
