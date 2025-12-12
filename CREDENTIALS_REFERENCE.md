# Jenkins Credentials Reference Guide

## Quick Lookup - Where to Set Each Credential

### 1. EC2 SSH Key (CRITICAL)
```
Name: ec2-ssh-credentials
Type: SSH Username with private key
Location: Jenkins → Manage Jenkins → Manage Credentials → Global
Input Fields:
  - Credentials ID: ec2-ssh-credentials
  - Username: ec2-user (for Amazon Linux) or ubuntu (for Ubuntu)
  - Private Key: [Paste your private SSH key]
  - Passphrase: [Leave empty or set your passphrase]
```

**How to create:**
1. Generate key locally: `ssh-keygen -t rsa -b 4096 -f ~/.ssh/ec2-devsecops`
2. Copy public key to EC2: `cat ~/.ssh/ec2-devsecops.pub >> ~/.ssh/authorized_keys` on EC2
3. Copy private key content to Jenkins: `cat ~/.ssh/ec2-devsecops`

---

### 2. SonarQube Token (CRITICAL)
```
Name: sonar-token (Optional - can pass as parameter)
Type: Secret text
Location: Jenkins → Manage Jenkins → Manage Credentials → Global
Input Fields:
  - Credentials ID: sonar-token
  - Secret: [Your SonarQube token starting with squ_]
```

**How to create:**
1. Go to SonarQube: http://localhost:9000
2. Login: admin / admin
3. Click your avatar (top right) → My Account
4. Go to Security tab
5. Scroll to Tokens section
6. Enter name: jenkins-token
7. Click Generate
8. Copy the token (looks like: `squ_1234567890abcdefghijklmnop...`)

**Format Example:**
```
squ_b0bbdaae27b077cc6b8e5c876f89a846ac35b6e2
```

---

### 3. GitHub Credentials (Optional - if using private repo)
```
Name: github-credentials
Type: Username with password
Location: Jenkins → Manage Jenkins → Manage Credentials → Global
Input Fields:
  - Credentials ID: github-credentials
  - Username: [Your GitHub username]
  - Password: [Your GitHub Personal Access Token]
```

**How to create:**
1. Go to GitHub: https://github.com/settings/tokens
2. Click Generate new token
3. Select scopes: repo, read:org
4. Copy token
5. Use as password in Jenkins

---

## Pipeline Parameters (Runtime)

These are asked when you click "Build with Parameters":

### Required Parameters:

**1. EC2_IP**
```
Type: String
Description: EC2 Instance IP Address
Example: 54.123.45.67
Where used: SSH connection to EC2
```

**2. EC2_USER**
```
Type: String
Default: ec2-user
Description: EC2 SSH User
Options: 
  - ec2-user (Amazon Linux 2)
  - ubuntu (Ubuntu)
Where used: SSH authentication username
```

**3. GITHUB_REPO**
```
Type: String
Default: https://github.com/ItsAnurag27/DevSecops-testing.git
Description: GitHub Repository URL
Where used: Git clone on EC2
```

**4. SONAR_HOST**
```
Type: String
Default: http://localhost:9000
Example: http://54.123.45.67:9000
Description: SonarQube Server URL
Where used: SonarQube scanner connection
```

**5. SONAR_TOKEN**
```
Type: String (Password)
Description: SonarQube Token
Example: squ_b0bbdaae27b077cc6b8e5c876f89a846ac35b6e2
Where used: SonarQube authentication
Sensitive: YES - shown as *** in logs
```

---

## Environment Variables in Jenkinsfile

These are defined in the pipeline code (no user input needed):

```groovy
environment {
    PROJECT_NAME = 'DevSecops-testing'           // Your project name
    DOCKER_REGISTRY = 'docker.io'                 // Docker Hub registry
    SONAR_PROJECT_KEY = 'docker-app'              // SonarQube project identifier
    EC2_DEPLOY_PATH = '/opt/devsecops'            // Where app is deployed on EC2
}
```

---

## Step-by-Step: Setting Up All Credentials

### Step 1: SSH Key Setup (FIRST - Required to connect to EC2)
```bash
# On your local machine
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ec2-devsecops
# Press Enter twice (no passphrase)

# Copy public key
cat ~/.ssh/ec2-devsecops.pub

# SSH to EC2 and add it
ssh -i your-ec2-key.pem ec2-user@your-ec2-ip
# On EC2:
echo "PASTE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit

# Get private key for Jenkins
cat ~/.ssh/ec2-devsecops
# Copy the entire output
```

### Step 2: Add SSH Credentials to Jenkins
```
Jenkins URL: http://your-jenkins-ip:8080 (or localhost:8080)

Navigate:
1. Manage Jenkins (left sidebar)
2. Manage Credentials
3. Global credentials (unrestricted)
4. Add Credentials

Form:
- Kind: SSH Username with private key
- Scope: Global
- ID: ec2-ssh-credentials
- Description: EC2 SSH Key for DevSecOps
- Username: ec2-user
- Private Key: ● [Select option] Paste directly
  [PASTE ENTIRE PRIVATE KEY HERE - include -----BEGIN RSA PRIVATE KEY----- and -----END RSA PRIVATE KEY-----)
- Passphrase: (leave empty)

Click: Create
```

### Step 3: Create SonarQube Token
```
SonarQube URL: http://your-sonarqube-ip:9000

Navigate:
1. Login as admin
2. Click avatar (top right)
3. My Account
4. Security tab
5. Tokens section
6. Input: jenkins-token
7. Click: Generate
8. Copy token value (starts with squ_)
```

### Step 4: Add SonarQube Token to Jenkins (Optional)
```
Jenkins URL: http://your-jenkins-ip:8080

Navigate:
1. Manage Jenkins
2. Manage Credentials
3. Global credentials (unrestricted)
4. Add Credentials

Form:
- Kind: Secret text
- Scope: Global
- ID: sonar-token
- Description: SonarQube API Token
- Secret: squ_b0bbdaae27b077cc6b8e5c876f89a846ac35b6e2

Click: Create

Note: Or pass token as pipeline parameter instead
```

### Step 5: Create Jenkins Pipeline Job
```
Jenkins URL: http://your-jenkins-ip:8080

Navigate:
1. New Item
2. Job name: DeployToEC2-DevSecOps
3. Select: Pipeline
4. Click: OK

Configure:
1. Scroll to Pipeline section
2. Definition: Pipeline script from SCM
3. SCM: Git
4. Repository URL: https://github.com/ItsAnurag27/DevSecops-testing.git
5. Credentials: (Select the GitHub credential if private repo, or leave for public)
6. Branch: */main
7. Script Path: Jenkinsfile

Click: Save
```

### Step 6: Run Pipeline with Parameters
```
Jenkins URL: http://your-jenkins-ip:8080

Navigate:
1. Find job: DeployToEC2-DevSecOps
2. Click: Build with Parameters

Fill in Parameters:
- EC2_IP: 54.123.45.67
- EC2_USER: ec2-user
- GITHUB_REPO: https://github.com/ItsAnurag27/DevSecops-testing.git
- SONAR_HOST: http://54.123.45.67:9000
- SONAR_TOKEN: squ_b0bbdaae27b077cc6b8e5c876f89a846ac35b6e2

Click: Build
```

---

## Troubleshooting Credential Issues

### Error: "Permission denied (publickey)"
**Cause**: SSH key not in EC2 authorized_keys
**Fix**: 
```bash
# SSH to EC2 with original key pair
ssh -i original-key.pem ec2-user@your-ip

# Add new public key
echo "PASTE_YOUR_JENKINS_PUBLIC_KEY" >> ~/.ssh/authorized_keys
```

### Error: "SonarQube token invalid"
**Cause**: Token expired or incorrect format
**Fix**:
1. Generate new token in SonarQube (must start with `squ_`)
2. Update Jenkins credential with new token
3. Re-run pipeline

### Error: "Jenkins credentials not found"
**Cause**: Credentials ID doesn't match
**Fix**: Use exact ID: `ec2-ssh-credentials`

### Error: "GitHub authentication failed"
**Cause**: Token not updated or expired
**Fix**:
1. Go to GitHub settings
2. Generate new Personal Access Token
3. Update Jenkins GitHub credential
4. Make sure it has `repo` scope

---

## Security Checklist

- [ ] SSH key is not committed to GitHub
- [ ] SonarQube token is stored as Jenkins secret, not in code
- [ ] EC2 security group restricts SSH to your IP
- [ ] Jenkins enforces authentication
- [ ] Credentials are rotated every 90 days
- [ ] No secrets in Jenkinsfile (use Jenkins Credentials Store)
- [ ] EC2 has security updates applied
- [ ] MongoDB credentials are strong (if exposed)

---

## Reference Table

| Credential | Type | Where | Used By |
|-----------|------|-------|---------|
| ec2-ssh-credentials | SSH Key | Jenkins Credentials | Pipeline SSH stages |
| sonar-token | Secret | Jenkins Credentials | SonarQube analysis stage |
| github-credentials | Username+Token | Jenkins Credentials | Git checkout stage |
| EC2_IP | Parameter | Pipeline Parameters | All SSH stages |
| SONAR_TOKEN | Parameter | Pipeline Parameters | SonarQube scanner |

---

## One-Liner Commands

```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ec2-devsecops -N ""

# Get private key for Jenkins
cat ~/.ssh/ec2-devsecops

# Get public key to add to EC2
cat ~/.ssh/ec2-devsecops.pub

# Test SSH connection
ssh -i ~/.ssh/ec2-devsecops ec2-user@your-ec2-ip

# Add public key to EC2 (run this ON the EC2 instance)
echo "PASTE_KEY_HERE" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
```
