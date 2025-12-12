# GitHub Actions Workflow - Visual Guide

## 🎬 Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                       │
│              "Deploy to EC2 with Terraform"                      │
└─────────────────────────────────────────────────────────────────┘

Step 1: Trigger Workflow (Manual)
    ↓
Step 2: Checkout Code
    ↓
Step 3: Setup Terraform
    ↓
Step 4: Configure AWS Credentials (from Secrets)
    ↓
Step 5: Terraform Init (Download plugins)
    ↓
Step 6: Terraform Validate (Check syntax)
    ↓
Step 7: Terraform Plan (Preview changes)
    ↓
Step 8: [CHOICE]
        ├─ Plan → Stop here, review output
        ├─ Apply → Continue to create resources
        └─ Destroy → Skip to destroy instead
    ↓
Step 9: Terraform Apply (Create resources)
    ↓
Step 10: Capture Outputs (Get IP and URLs)
    ↓
Step 11: Display Service URLs
    ↓
Step 12: Clean Up Secrets
    ↓
✅ Complete (Resources Created)
```

---

## 📊 Three Workflow Actions

### Action 1: PLAN
```
Purpose: Preview what will be created (NO RESOURCES CREATED)

When to use:
✓ First run to review changes
✓ Before applying any changes
✓ To validate configuration
✗ NOT for production yet

Steps:
  1. Checkout code
  2. Setup Terraform
  3. Configure AWS credentials
  4. Initialize Terraform
  5. Validate syntax
  6. Run terraform plan
  7. Save artifact for review
  
Output:
  → Artifact: terraform-plan.json
  → Logs: Detailed plan output
  → Time: 2-3 minutes
  
Next: Review → Run APPLY
```

### Action 2: APPLY
```
Purpose: Actually create EC2 infrastructure

When to use:
✓ After reviewing plan output
✓ When ready to deploy
✓ For production deployment
✗ NOT for preview

Steps:
  1. Checkout code
  2. Setup Terraform
  3. Configure AWS credentials
  4. Initialize Terraform
  5. Validate syntax
  6. Create plan
  7. Apply plan (CREATE RESOURCES)
  8. Display outputs
  
Output:
  → EC2 IP address
  → All service URLs
  → SSH connection command
  → Time: 5-10 minutes
  
Result: EC2 instance + services running
```

### Action 3: DESTROY
```
Purpose: Delete all AWS resources (CLEANUP)

When to use:
✓ When done with testing
✓ To stop incurring charges
✓ Before recreating infrastructure
✗ NOT for production without planning

⚠️  WARNING: This removes all resources!

Steps:
  1. Checkout code
  2. Setup Terraform
  3. Configure AWS credentials
  4. Initialize Terraform
  5. Destroy all resources
  
Output:
  → All resources deleted
  → Billing stopped
  → Time: 3-5 minutes
  
Result: Clean AWS account
```

---

## 🖼️ How to Trigger Workflow

### Via GitHub UI

```
1. Open your GitHub repository
   https://github.com/YOUR_USERNAME/YOUR_REPO

2. Click "Actions" tab (top navigation)
   ├─ Source Code
   ├─ Pull requests
   ├─ Actions  ← CLICK HERE
   ├─ Projects
   └─ ...

3. Left sidebar → Select workflow
   └─ "Deploy to EC2 with Terraform"

4. Click "Run workflow" button
   │
   └─ Choose action:
      ├─ plan   (Preview changes)
      ├─ apply  (Create resources)
      └─ destroy (Delete resources)

5. Click "Run workflow" button

6. Monitor execution
   └─ Watch status change:
      ├─ Queued (yellow)
      ├─ In Progress (blue)
      └─ Completed (green ✓ or red ✗)
```

### Via GitHub CLI

```bash
# List available workflows
gh workflow list

# Run workflow with plan action
gh workflow run deploy-to-ec2.yml -f action=plan

# Run workflow with apply action
gh workflow run deploy-to-ec2.yml -f action=apply

# Run workflow with destroy action
gh workflow run deploy-to-ec2.yml -f action=destroy
```

---

## 📈 Workflow Execution Timeline

### PLAN Action Timeline
```
Time    Action
0 min   Start workflow
0-1     Checkout code
1-2     Setup Terraform
2-3     Configure AWS
3-4     Terraform init
4-5     Terraform validate
5-15    Terraform plan
15-16   Save artifact
---
~16 min Total
```

### APPLY Action Timeline
```
Time    Action
0 min   Start workflow
0-1     Checkout code
1-2     Setup Terraform
2-3     Configure AWS
3-4     Terraform init
4-5     Terraform validate
5-15    Terraform plan
15-25   Terraform apply (CREATE RESOURCES)
         - VPC creation
         - Subnet creation
         - Security group creation
         - EC2 instance launch
         - Elastic IP allocation
         - User data execution
25-26   Capture outputs
26-27   Display service URLs
27-28   Cleanup secrets
---
~28 min Total (+ 5-10 min EC2 initialization)
```

---

## 🔐 Secrets Management

### Required Secrets (4 Total)

```
Secret Name: AWS_ACCESS_KEY_ID
├─ Value: Your AWS access key
├─ From: IAM user credentials
├─ Format: AKIA...XXXX (20 chars)
└─ Where: GitHub Settings → Secrets

Secret Name: AWS_SECRET_ACCESS_KEY
├─ Value: Your AWS secret key
├─ From: IAM user credentials
├─ Format: Long random string
└─ Where: GitHub Settings → Secrets
⚠️ KEEP CONFIDENTIAL!

Secret Name: EC2_KEY_PAIR_NAME
├─ Value: Name of EC2 key pair
├─ From: AWS EC2 → Key pairs
├─ Format: devsecops-key (no .pem)
└─ Where: GitHub Settings → Secrets

Secret Name: EC2_PRIVATE_KEY
├─ Value: Contents of .pem file
├─ From: Your local file
├─ Format: Full .pem file (including BEGIN/END)
└─ Where: GitHub Settings → Secrets
⚠️ KEEP SECURE!
```

### How Secrets Are Used

```
Workflow Execution
    │
    ├─ Needs AWS_ACCESS_KEY_ID
    │  └─ GitHub provides from Secrets (encrypted)
    │
    ├─ Needs AWS_SECRET_ACCESS_KEY
    │  └─ GitHub provides from Secrets (encrypted)
    │
    ├─ Needs EC2_KEY_PAIR_NAME
    │  └─ Passed to Terraform variable
    │
    ├─ Needs EC2_PRIVATE_KEY
    │  └─ Written to /tmp/ec2_key.pem (400 perms)
    │
    └─ After completion
       └─ All secrets cleaned up
       └─ No secrets left in logs
```

---

## 📊 Workflow Status Indicators

### Status Badges

```
┌─────────────────────────────────────────┐
│ Workflow Status                         │
├─────────────────────────────────────────┤
│                                         │
│ 🟡 Queued                              │
│    Waiting to start                     │
│    Usually < 1 minute                   │
│                                         │
│ 🔵 In Progress                         │
│    Currently running                    │
│    Watch steps complete                 │
│                                         │
│ 🟢 Completed (Success)                │
│    All steps passed                     │
│    Resources created/verified           │
│                                         │
│ 🔴 Failed                              │
│    One step failed                      │
│    Check logs for errors                │
│                                         │
│ ⚫ Skipped                              │
│    Workflow skipped                     │
│    Check conditions                     │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📝 Workflow Output Examples

### Plan Output (Sample)
```
Terraform Plan Summary:
  Resource Actions Summary:
    + Create (7 new resources)
      - aws_vpc
      - aws_subnet
      - aws_internet_gateway
      - aws_route_table
      - aws_route_table_association
      - aws_security_group
      - aws_instance
      - aws_elastic_ip

Changes will be made
Plan: 7 to add, 0 to change, 0 to destroy
```

### Apply Output (Sample)
```
Terraform Plan Summary:
  (same as plan)

Applying plan...
[100%] Complete

Outputs:
  ec2_public_ip = "54.123.45.67"
  ec2_instance_id = "i-0123456789abcdef0"
  sonarqube_url = "http://54.123.45.67:9000"
  frontend_url = "http://54.123.45.67:3000"
  backend_url = "http://54.123.45.67:3001"
  ssh_command = "ssh -i key.pem ec2-user@54.123.45.67"
```

---

## 🔍 Monitoring Workflow Progress

### Step-by-Step Monitoring

```
Step 1: Checkout code
├─ ✓ Complete
└─ Duration: 5 seconds

Step 2: Setup Terraform
├─ ✓ Complete
└─ Duration: 15 seconds

Step 3: Configure AWS credentials
├─ ✓ Complete (secrets masked in logs)
└─ Duration: 2 seconds

Step 4: Terraform Init
├─ ✓ Complete
└─ Duration: 30 seconds
   └─ Downloads plugins and modules

Step 5: Terraform Validate
├─ ✓ Complete
└─ Duration: 5 seconds
   └─ Checks syntax, no errors found

Step 6: Terraform Plan
├─ ⏳ In Progress... (2 min elapsed)
└─ Duration: ~10-15 minutes
   └─ Contacting AWS API
   └─ Calculating changes
   └─ Creating plan file

Step 7: Terraform Apply (if action=apply)
├─ ⏳ In Progress... (12 min elapsed)
└─ Duration: ~10-15 minutes
   └─ Creating VPC
   └─ Creating Subnet
   └─ Creating Security Group
   └─ Launching EC2 instance
   └─ Allocating Elastic IP
   └─ Running user data script
```

---

## 🚨 Workflow Error Handling

### Common Error Scenarios

```
ERROR: AWS credentials not found
├─ Cause: Missing or wrong GitHub Secrets
├─ Fix: Check all 4 secrets are set correctly
├─ Check: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
└─ Steps:
   1. Go to Settings → Secrets
   2. Verify secret names (exact match)
   3. Verify values are correct
   4. Re-run workflow

ERROR: Key pair not found
├─ Cause: EC2_KEY_PAIR_NAME doesn't exist in AWS
├─ Fix: Create key pair or use different name
└─ Steps:
   1. AWS Console → EC2 → Key pairs
   2. Verify key pair exists
   3. Update secret if needed
   4. Re-run workflow

ERROR: Terraform validation failed
├─ Cause: Syntax error in Terraform files
├─ Fix: Check terraform.tfvars configuration
└─ Steps:
   1. Review terraform/README.md
   2. Check terraform.tfvars
   3. Verify no typos or syntax errors
   4. Commit and re-run workflow

ERROR: EC2 instance failed to initialize
├─ Cause: Docker installation failed
├─ Fix: SSH to instance and check logs
└─ Steps:
   1. SSH: ssh -i key.pem ec2-user@IP
   2. Check: tail /var/log/cloud-init-output.log
   3. Verify: docker --version, docker-compose ps
   4. Restart if needed: docker-compose restart
```

---

## 📊 Workflow Cost Impact

```
GitHub Actions Cost:
├─ Free tier: 2,000 minutes/month
├─ This workflow: ~30 minutes per run
├─ Monthly allowance: ~66 free runs
├─ Cost for overages: $0.008/minute
└─ For typical usage: FREE ✓

AWS Cost (While EC2 Running):
├─ EC2 t2.large: $70/month
├─ Storage: $2.50/month
├─ Total: ~$72.50/month
└─ Stopped instance: ~$2.50/month

Cost Optimization:
├─ Run plan first (preview)
├─ Review before apply
├─ Destroy when not needed
├─ Stop instead of destroy (saves data)
└─ Use smaller instance for testing
```

---

## 🎯 Workflow Decision Tree

```
                START
                  │
                  ↓
         Need to deploy EC2?
         /              \
       YES               NO
        │                └─→ Done
        ↓
   Run PLAN action
        │
        ↓
   Review plan output
   /            \
LOOKS GOOD   ISSUES
   │             │
   ↓             ↓
Run APPLY    Fix config
   │          │
   ↓          ↓
Wait 5-10    Push changes
min          │
   │         ↓
   ↓      Re-run PLAN
EC2                │
Created        └─→ [review again]
   │
   ↓
Access
Services
   │
   ↓
Done? 
 /   \
YES   NO
 │     └─→ Keep running (pay costs)
 ↓
Run DESTROY
 │
 ↓
Resources deleted
 │
 ↓
✓ Complete
```

---

## 📋 Pre-Workflow Checklist

Before running any workflow:

```
☑ GitHub Secrets Setup
  ☐ AWS_ACCESS_KEY_ID set
  ☐ AWS_SECRET_ACCESS_KEY set
  ☐ EC2_KEY_PAIR_NAME set
  ☐ EC2_PRIVATE_KEY set

☑ Terraform Configuration
  ☐ terraform.tfvars customized
  ☐ key_pair_name matches AWS
  ☐ github_repo URL correct
  ☐ allowed_ssh_cidr reviewed

☑ AWS Preparation
  ☐ EC2 key pair created
  ☐ AWS credentials obtained
  ☐ IAM user with proper permissions

☑ Repository Setup
  ☐ Code pushed to main branch
  ☐ Actions enabled
  ☐ .github/workflows/deploy-to-ec2.yml present
  ☐ terraform/ directory with all files

✓ Ready to run workflow!
```

---

## 🎬 Example Workflow Run

### Run 1: PLAN
```
15:00 Start
15:05 Complete
Output:
  Plan: 7 to add, 0 to change, 0 to destroy
Status: ✅ PASSED

Decision: Review shows correct resources → Proceed
```

### Run 2: APPLY  
```
15:10 Start
15:40 Complete
Output:
  ec2_public_ip = "54.123.45.67"
  frontend_url = "http://54.123.45.67:3000"
  backend_url = "http://54.123.45.67:3001"
  ssh_command = "ssh -i key.pem ec2-user@54.123.45.67"
Status: ✅ PASSED

Action: Services accessible via URLs
```

### Run 3: Use Services
```
15:45 EC2 fully initialized
15:45 Access Frontend: http://54.123.45.67:3000
15:45 Test Backend: curl http://54.123.45.67:3001/api/todos
15:45 SonarQube: http://54.123.45.67:9000
Status: ✅ ALL SERVICES RUNNING
```

### Run 4: DESTROY (Optional)
```
16:00 Start
16:10 Complete
Output:
  Destroy complete
  All resources deleted
Status: ✅ PASSED

Cost: Charges stopped ✓
```

---

## 📞 Support Quick Links

- Workflow stuck? → Check: GitHub Actions logs
- Need help? → Read: GITHUB_ACTIONS_SETUP.md  
- Terraform issue? → Read: terraform/README.md
- Deployment problem? → Read: DEPLOYMENT_CHECKLIST.md
- Quick overview? → Read: QUICK_START.md

---

**Need help? See the documentation files for detailed instructions and troubleshooting.**
