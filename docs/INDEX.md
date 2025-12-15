# 📊 Data Warehousing Project Index

Welcome to the **Data Warehousing Infrastructure** project! This is a complete, production-ready solution for building a scalable data warehouse on AWS using CloudFormation.

## 🚀 Quick Navigation

### 📖 Documentation (Start Here!)

1. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - High-level overview and getting started
2. **[README.md](README.md)** - Comprehensive guide (architecture, setup, usage, troubleshooting)
3. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Common commands and quick lookups

### 📋 CloudFormation Templates

Located in `cloudformation/`:

- **[00-master-stack.yaml](cloudformation/00-master-stack.yaml)** - Main orchestration template
- **[01-s3-bucket.yaml](cloudformation/01-s3-bucket.yaml)** - S3 Data Lake
- **[02-rds-database.yaml](cloudformation/02-rds-database.yaml)** - RDS PostgreSQL
- **[03-glue-jobs.yaml](cloudformation/03-glue-jobs.yaml)** - AWS Glue ETL
- **[04-redshift-cluster.yaml](cloudformation/04-redshift-cluster.yaml)** - Redshift DW

### 🔧 Deployment & Scripts

Located in `scripts/`:

- **[deploy.sh](scripts/deploy.sh)** - Automated deployment script
- **[cleanup.sh](scripts/cleanup.sh)** - Stack deletion with safety checks
- **[validate.sh](scripts/validate.sh)** - Project validation
- **[rds-init.sql](scripts/rds-init.sql)** - RDS database initialization
- **[redshift-init.sql](scripts/redshift-init.sql)** - Redshift setup
- **[parameters.json](scripts/parameters.json)** - Default parameters

### 🐍 Glue Job Scripts

Located in `glue/`:

- **[rds-to-s3.py](glue/rds-to-s3.py)** - Extract from RDS → S3 Raw
- **[s3-processing.py](glue/s3-processing.py)** - Transform & Clean
- **[s3-to-redshift.py](glue/s3-to-redshift.py)** - Prepare for Redshift

### ⚙️ Configuration

- **[config.env](config.env)** - Environment configuration settings

---

## 🎯 Getting Started (5 Minutes)

### Step 1: Check Prerequisites

```bash
# Verify AWS CLI is installed
aws --version

# Configure AWS credentials (if not already done)
aws configure
```

### Step 2: Review Project

```bash
# View project structure
ls -la

# Read PROJECT_SUMMARY.md for overview
cat PROJECT_SUMMARY.md
```

### Step 3: Deploy Infrastructure

```bash
# Make scripts executable (if needed)
chmod +x scripts/*.sh

# Deploy to development environment
./scripts/deploy.sh dev us-east-1

# Deployment will take 20-30 minutes
# Monitor progress in AWS CloudFormation Console
```

### Step 4: Initialize Databases

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' \
  --output text)

# Initialize RDS
psql -h $RDS_ENDPOINT -U admin -d warehouse -f scripts/rds-init.sql

# Note: Redshift initialization comes after data pipeline setup
```

---

## 📚 Documentation Guide

### For Different Audiences

**👨‍💼 Business Stakeholders**
→ Read: PROJECT_SUMMARY.md (Architecture Overview section)

**👨‍💻 DevOps/Infrastructure Engineers**
→ Read: README.md (Architecture Overview → Deployment sections)
→ Reference: QUICK_REFERENCE.md (CloudFormation commands)

**🔬 Data Engineers**
→ Read: README.md (Data Flow section)
→ Check: glue/ directory (ETL scripts)
→ Reference: QUICK_REFERENCE.md (Glue operations)

**🔍 System Administrators**
→ Read: README.md (Security, Monitoring sections)
→ Check: scripts/ directory (Database initialization)
→ Reference: QUICK_REFERENCE.md (Stack operations)

---

## 🏗️ Architecture Summary

```
Data Sources (RDS/S3)
         ↓
    AWS Glue Jobs
         ↓
    S3 Data Lake
    (Raw → Processed → Curated)
         ↓
   Amazon Redshift
(Data Warehouse & Analytics)
```

**Key Features:**

- ✅ Infrastructure as Code (CloudFormation)
- ✅ Multi-environment support (dev, staging, prod)
- ✅ Automated ETL pipelines (Glue)
- ✅ Enterprise-grade data warehouse (Redshift)
- ✅ Security best practices (encryption, IAM, monitoring)
- ✅ Scalable and cost-optimized

---

## 📂 Directory Structure

```
data-warehousing/
│
├── 📄 Index & Documentation
│   ├── INDEX.md                    ← You are here
│   ├── README.md                   ← Comprehensive guide
│   ├── PROJECT_SUMMARY.md          ← Quick overview
│   ├── QUICK_REFERENCE.md          ← Common commands
│   └── config.env                  ← Configuration
│
├── 📁 cloudformation/              ← IaC Templates
│   ├── 00-master-stack.yaml        ← Master/Orchestration
│   ├── 01-s3-bucket.yaml           ← Data Lake
│   ├── 02-rds-database.yaml        ← PostgreSQL
│   ├── 03-glue-jobs.yaml           ← ETL Pipeline
│   └── 04-redshift-cluster.yaml    ← Data Warehouse
│
├── 📁 scripts/                     ← Deployment & Setup
│   ├── deploy.sh                   ← Main deployment
│   ├── cleanup.sh                  ← Stack cleanup
│   ├── validate.sh                 ← Project validation
│   ├── rds-init.sql                ← RDS setup
│   ├── redshift-init.sql           ← Redshift setup
│   └── parameters.json             ← Default parameters
│
├── 📁 glue/                        ← ETL Scripts
│   ├── rds-to-s3.py                ← Ingestion job
│   ├── s3-processing.py            ← Transformation job
│   └── s3-to-redshift.py           ← Loading job
│
└── 📁 data/                        ← Sample data (empty)
    └── (Add your sample data here)
```

---

## ⚙️ Key Components

### CloudFormation Templates (5 files)

- **Master Stack** (00-master-stack.yaml): Orchestrates all other stacks
- **S3 Stack** (01-s3-bucket.yaml): Data lake with 4 layers (raw, processed, curated, logs)
- **RDS Stack** (02-rds-database.yaml): PostgreSQL transactional database
- **Glue Stack** (03-glue-jobs.yaml): 3 ETL jobs + Crawlers + Catalog
- **Redshift Stack** (04-redshift-cluster.yaml): Data warehouse cluster

### Glue Jobs (3 jobs)

- **rds-to-s3**: Extracts data from RDS → S3 Raw (runs on schedule)
- **s3-processing**: Transforms raw → processed (removes duplicates, validates)
- **s3-to-redshift**: Prepares processed → curated for Redshift loading

### Databases

- **RDS PostgreSQL**: Source system, transactional data
- **Redshift**: Analytics warehouse, optimized for complex queries

---

## 🔑 Important Parameters

Edit in `config.env` or pass during deployment:

| Parameter                   | Default     | Purpose                   |
| --------------------------- | ----------- | ------------------------- |
| ENVIRONMENT                 | dev         | dev, staging, or prod     |
| AWS_REGION                  | us-east-1   | AWS region for deployment |
| RDS_INSTANCE_CLASS          | db.t3.micro | Database server size      |
| RDS_ALLOCATED_STORAGE       | 20          | Database storage in GB    |
| REDSHIFT_NODE_TYPE          | dc2.large   | Redshift node type        |
| REDSHIFT_NODES              | 2           | Number of Redshift nodes  |
| REDSHIFT_SNAPSHOT_RETENTION | 7           | Backup retention days     |

---

## 🚀 Common Tasks

### Deploy

```bash
./scripts/deploy.sh dev us-east-1
```

### Check Status

```bash
aws cloudformation describe-stacks --stack-name data-warehouse-dev
```

### View Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table
```

### Run Glue Job

```bash
aws glue start-job-run --job-name rds-to-s3-dev
```

### Connect to RDS

```bash
psql -h <RDS_ENDPOINT> -U admin -d warehouse
```

### Delete Stack

```bash
./scripts/cleanup.sh dev us-east-1
```

---

## 📊 Project Statistics

| Metric                   | Value |
| ------------------------ | ----- |
| CloudFormation Templates | 5     |
| Total Resources          | 40+   |
| Glue Jobs                | 3     |
| Database Instances       | 2     |
| IAM Roles                | 4     |
| Lines of Code            | 3000+ |
| Documentation Pages      | 4     |

---

## 🎓 Learning Resources

**AWS Services Used:**

- [CloudFormation](https://docs.aws.amazon.com/cloudformation/)
- [S3 Data Lakes](https://aws.amazon.com/s3/data-lakes/)
- [RDS PostgreSQL](https://docs.aws.amazon.com/rds/latest/userguide/PostgreSQL.Concepts.General.DBInstances.html)
- [AWS Glue](https://docs.aws.amazon.com/glue/)
- [Amazon Redshift](https://docs.aws.amazon.com/redshift/)

**Reference Articles:**

- [AWS Data Lake Architecture](https://aws.amazon.com/solutions/implementations/data-lake-foundation/)
- [Data Warehouse Best Practices](https://docs.aws.amazon.com/redshift/latest/dg/best-practices.html)
- [Glue ETL Best Practices](https://docs.aws.amazon.com/glue/latest/dg/best-practices.html)

---

## ❓ FAQ

**Q: How long does deployment take?**
A: Approximately 25-35 minutes total (Redshift cluster takes longest)

**Q: What's the minimum cost?**
A: ~$1,900/month for dev environment (varies by region)

**Q: Can I use different regions?**
A: Yes, change REGION parameter in deploy script

**Q: How do I scale Redshift?**
A: Modify `RedshiftNumberOfNodes` parameter before deployment

**Q: Can I delete and redeploy easily?**
A: Yes, use cleanup.sh then deploy.sh again

---

## 🔗 Quick Links

| Resource         | Link                                           |
| ---------------- | ---------------------------------------------- |
| AWS Console      | https://console.aws.amazon.com                 |
| CloudFormation   | https://console.aws.amazon.com/cloudformation/ |
| RDS Console      | https://console.aws.amazon.com/rds/            |
| Glue Console     | https://console.aws.amazon.com/glue/           |
| Redshift Console | https://console.aws.amazon.com/redshiftv2/     |
| S3 Console       | https://console.aws.amazon.com/s3/             |

---

## 📞 Support

For issues or questions:

1. Check **README.md** (troubleshooting section)
2. Review **QUICK_REFERENCE.md** (common commands)
3. Check **CloudFormation Events** in AWS Console
4. Review logs in **CloudWatch**

---

**Ready to get started?**
→ Start with [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) or run `./scripts/deploy.sh dev us-east-1`

**Version**: 1.0.0  
**Last Updated**: December 2024  
**Status**: ✅ Production Ready
