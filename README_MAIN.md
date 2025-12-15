# Data Warehousing Infrastructure

A production-ready data warehousing solution on AWS using CloudFormation, with S3 → RDS → Glue → Redshift pipeline.

**Architecture**: `S3 Data Lake` → `RDS Source` → `AWS Glue` → `Amazon Redshift`

## Quick Start

```bash
# 1. View documentation
cat docs/GETTING_STARTED.md

# 2. Deploy infrastructure
./scripts/deploy.sh dev us-east-1

# 3. Monitor stack
aws cloudformation describe-stacks --stack-name data-warehouse-dev
```

## 📁 Project Structure

```
├── cloudformation/          # Infrastructure as Code
│   ├── 00-master-stack.yaml
│   ├── 01-s3-bucket.yaml
│   ├── 02-rds-database.yaml
│   ├── 03-glue-jobs.yaml
│   └── 04-redshift-cluster.yaml
├── glue/                    # ETL Scripts
│   ├── rds-to-s3.py
│   ├── s3-processing.py
│   └── s3-to-redshift.py
├── scripts/                 # Utilities
│   ├── deploy.sh
│   ├── cleanup.sh
│   ├── rds-init.sql
│   └── redshift-init.sql
├── .github/workflows/       # CI/CD Pipelines
│   ├── validate-cloudformation.yaml
│   ├── deploy.yaml
│   └── code-quality.yaml
├── docs/                    # Documentation
│   ├── README.md
│   ├── GETTING_STARTED.md
│   └── QUICK_REFERENCE.md
└── config.env               # Environment variables
```

## 📚 Documentation

- [**README**](docs/README.md) - Complete guide
- [**Getting Started**](docs/GETTING_STARTED.md) - Quick setup
- [**Quick Reference**](docs/QUICK_REFERENCE.md) - Common commands
- [**Project Summary**](docs/PROJECT_SUMMARY.md) - Overview
- [**Index**](docs/INDEX.md) - File reference

## 🚀 Features

✅ Infrastructure as Code (CloudFormation)  
✅ Automated CI/CD (GitHub Actions)  
✅ Data lake with raw/processed/curated layers  
✅ RDS PostgreSQL extraction  
✅ AWS Glue ETL jobs  
✅ Redshift data warehouse  
✅ SQL initialization scripts  
✅ Comprehensive documentation

## 🔧 Prerequisites

- AWS Account with appropriate permissions
- AWS CLI v2+
- Bash shell
- Git

## 📊 Data Flow

1. **Extract**: RDS → S3 (raw)
2. **Transform**: Glue processes raw → processed
3. **Refine**: Glue curates → final data layer
4. **Load**: Curated data → Redshift
5. **Analyze**: Query in Redshift

## ⚙️ Deployment

```bash
# Development
./scripts/deploy.sh dev us-east-1

# Staging
./scripts/deploy.sh staging us-east-1

# Production
./scripts/deploy.sh prod us-east-1
```

## 🧹 Cleanup

```bash
./scripts/cleanup.sh dev us-east-1
```

## 📖 Learn More

See [docs/README.md](docs/README.md) for:

- Detailed architecture
- Configuration options
- Monitoring setup
- Troubleshooting
- Cost estimation

## 🔄 CI/CD

This project includes GitHub Actions workflows for:

- **Validate CloudFormation** - Template validation on push/PR
- **Code Quality** - Python/YAML/Bash linting
- **Deploy** - Manual CloudFormation deployment

## 📝 License

This project is provided as-is for educational and commercial use.

---

**Repository**: https://github.com/hasannasrul/data-warehousing
