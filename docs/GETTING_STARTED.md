#!/usr/bin/env bash

# Getting Started with Data Warehousing Project

# This script provides an interactive setup guide

cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════╗
║ ║
║ 🎯 DATA WAREHOUSING INFRASTRUCTURE - GETTING STARTED ║
║ ║
╚══════════════════════════════════════════════════════════════════════╝

Welcome! This project provides a complete, production-ready data
warehousing solution on AWS using CloudFormation.

📋 PROJECT STRUCTURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

data-warehousing/
├── 📖 Documentation
│ ├── INDEX.md ...................... Project index & navigation
│ ├── README.md ..................... Complete guide (25+ sections)
│ ├── PROJECT_SUMMARY.md ............ Quick overview
│ └── QUICK_REFERENCE.md ........... Common commands
│
├── 📁 cloudformation/ ................ CloudFormation IaC
│ ├── 00-master-stack.yaml ......... Main orchestration
│ ├── 01-s3-bucket.yaml ........... Data Lake (S3)
│ ├── 02-rds-database.yaml ........ Database (RDS)
│ ├── 03-glue-jobs.yaml ........... ETL Jobs (Glue)
│ └── 04-redshift-cluster.yaml .... Warehouse (Redshift)
│
├── 🔧 scripts/ ....................... Deployment & Setup
│ ├── deploy.sh ................... Main deployment
│ ├── cleanup.sh .................. Stack deletion
│ ├── validate.sh ................. Project validation
│ ├── rds-init.sql ............... RDS initialization
│ └── redshift-init.sql .......... Redshift setup
│
├── 🐍 glue/ .......................... ETL Scripts
│ ├── rds-to-s3.py ................ Extract job
│ ├── s3-processing.py ............ Transform job
│ └── s3-to-redshift.py .......... Load job
│
└── ⚙️ config.env ................... Configuration

🚀 QUICK START (4 STEPS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣ PREREQUISITES

    ✓ AWS Account (with appropriate permissions)
    ✓ AWS CLI installed (v2+)
      → Test: aws --version
      → Setup: aws configure

2️⃣ REVIEW PROJECT

    Start with one of these:
    → INDEX.md ..................... Quick navigation guide
    → PROJECT_SUMMARY.md ........... High-level overview
    → README.md .................... Comprehensive documentation

3️⃣ DEPLOY INFRASTRUCTURE

    Make scripts executable (first time only):
    $ chmod +x scripts/*.sh

    Deploy to development environment:
    $ ./scripts/deploy.sh dev us-east-1

    ⏱️  This takes 25-35 minutes
    📊 Monitor in: https://console.aws.amazon.com/cloudformation/

4️⃣ INITIALIZE DATABASES

    Get RDS endpoint:
    $ RDS=$(aws cloudformation describe-stacks \
        --stack-name data-warehouse-dev \
        --query 'Stacks[0].Outputs[?OutputKey==\`RDSEndpoint\`].OutputValue' \
        --output text)

    Run initialization:
    $ psql -h $RDS -U admin -d warehouse -f scripts/rds-init.sql

📚 DOCUMENTATION GUIDE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Who Are You? Read This
─────────────────────────────────────────────────────────────────────
I'm new here → INDEX.md + PROJECT_SUMMARY.md
I'm a DevOps eng → README.md (Setup) + QUICK_REFERENCE.md
I'm a Data eng → README.md (Architecture) + glue/ scripts
I'm an Admin → README.md (Security) + scripts/
I want quick help → QUICK_REFERENCE.md

🏗️ ARCHITECTURE OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Data Sources → AWS Glue (ETL) → S3 Data Lake → Redshift (DW) → Analytics

Components:
📦 S3 ........... Data Lake (raw, processed, curated)
🗄️ RDS ........... PostgreSQL database (data source)
🔄 Glue ......... ETL pipeline (3 jobs)
📊 Redshift ..... Data warehouse (analytics)
☁️ CloudFormation ... Infrastructure as Code (5 templates)

⚡ COMMON COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Deployment:
./scripts/deploy.sh dev us-east-1 # Deploy dev
./scripts/deploy.sh staging us-east-1 # Deploy staging
./scripts/deploy.sh prod us-east-1 # Deploy prod
./scripts/cleanup.sh dev us-east-1 # Delete dev

Stack Info:
aws cloudformation describe-stacks --stack-name data-warehouse-dev
aws cloudformation describe-stack-events --stack-name data-warehouse-dev

Connections:

# Get RDS endpoint

aws cloudformation describe-stacks \
 --stack-name data-warehouse-dev \
 --query 'Stacks[0].Outputs[?OutputKey==\`RDSEndpoint\`].OutputValue'

# Connect to RDS

psql -h <ENDPOINT> -U admin -d warehouse

# Connect to Redshift

psql -h <ENDPOINT> -U admin -d warehouse -p 5439

See QUICK_REFERENCE.md for more commands!

💡 TIPS & BEST PRACTICES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ DO:
• Start with dev environment for testing
• Read documentation before deploying
• Monitor CloudFormation events during deployment
• Use CloudWatch to monitor performance
• Set up CloudWatch alarms for production
• Backup databases regularly
• Test data pipelines in staging first

❌ DON'T:
• Skip the documentation
• Deploy directly to production
• Use simple passwords
• Leave public access enabled
• Forget to set up monitoring
• Ignore cost warnings

💰 COST ESTIMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Component Monthly Cost Notes
────────────────────────────────────────────────────────────────────
S3 (1TB) $23-50 Varies by region
RDS (t3.micro) $100-150 Smallest instance
Redshift (2x) $1,500-1,800 2 dc2.large nodes
Glue ETL $50-200 Depends on usage
Data Transfer $0-100 Varies

TOTAL (DEV): ~$1,700-2,300 monthly

💡 Save money in dev: Use smaller instances, delete after testing

🔐 SECURITY FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Encryption at rest (S3, RDS, Redshift)
✓ Encryption in transit (TLS/SSL)
✓ IAM roles with least privilege
✓ Secrets Manager for credentials
✓ VPC support available
✓ Audit logging enabled
✓ Multi-AZ deployments (RDS)
✓ Public access controls

❓ TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Problem Solution
────────────────────────────────────────────────────────────────────
Stack fails → Check CloudFormation events
Permission denied → Verify IAM permissions
Timeout → Check AWS limits
Connection refused → Verify security groups
Glue job fails → Check CloudWatch logs
High costs → Review resource sizes

See README.md for detailed troubleshooting!

📖 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Read INDEX.md or PROJECT_SUMMARY.md
2. Configure AWS credentials: aws configure
3. Review config.env parameters
4. Deploy: ./scripts/deploy.sh dev us-east-1
5. Monitor deployment in AWS Console
6. Initialize databases
7. Test data pipeline
8. Read full documentation
9. Customize for your data

🎯 PROJECT GOALS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Learn AWS cloud architecture
✓ Understand data warehousing
✓ Practice Infrastructure as Code
✓ Deploy production-grade infrastructure
✓ Implement ETL pipelines
✓ Master CloudFormation
✓ Learn Glue, RDS, and Redshift

📚 RESOURCES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AWS Documentation:
• CloudFormation: https://docs.aws.amazon.com/cloudformation/
• RDS: https://docs.aws.amazon.com/rds/
• Glue: https://docs.aws.amazon.com/glue/
• Redshift: https://docs.aws.amazon.com/redshift/
• S3: https://docs.aws.amazon.com/s3/

AWS Consoles:
• CloudFormation: https://console.aws.amazon.com/cloudformation/
• RDS: https://console.aws.amazon.com/rds/
• Glue: https://console.aws.amazon.com/glue/
• Redshift: https://console.aws.amazon.com/redshiftv2/

═══════════════════════════════════════════════════════════════════════

👉 READY? Start here:

1.  Read: cat INDEX.md
2.  Deploy: ./scripts/deploy.sh dev us-east-1

═══════════════════════════════════════════════════════════════════════

Questions? Check:
• INDEX.md ........... Navigation guide
• README.md .......... Full documentation
• QUICK_REFERENCE.md . Common commands
• PROJECT_SUMMARY.md . Overview

Good luck! 🚀

EOF
