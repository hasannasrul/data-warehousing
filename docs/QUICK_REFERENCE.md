# Data Warehousing Quick Reference Guide

## Common Commands

### Deployment

```bash
# Deploy to development
./scripts/deploy.sh dev us-east-1

# Deploy to staging
./scripts/deploy.sh staging us-east-1

# Deploy to production
./scripts/deploy.sh prod us-east-1
```

### Stack Information

```bash
# List all stacks
aws cloudformation list-stacks --region us-east-1

# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table

# Get stack events
aws cloudformation describe-stack-events \
  --stack-name data-warehouse-dev \
  --region us-east-1 | head -20
```

### Database Connections

```bash
# Get RDS endpoint
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' \
  --output text

# Get Redshift endpoint
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`RedshiftEndpoint`].OutputValue' \
  --output text

# Connect to RDS
psql -h <RDS_ENDPOINT> -U admin -d warehouse

# Connect to Redshift
psql -h <REDSHIFT_ENDPOINT> -U admin -d warehouse -p 5439
```

### S3 Operations

```bash
# Get bucket name
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
  --output text

# List S3 contents
aws s3 ls s3://<BUCKET_NAME>/ --recursive

# Upload Glue scripts
aws s3 cp glue/ s3://<BUCKET_NAME>/glue-scripts/ --recursive

# Upload sample data
aws s3 cp data/ s3://<BUCKET_NAME>/raw/sample-data/ --recursive
```

### Glue Operations

```bash
# List jobs
aws glue list-jobs --region us-east-1

# Start job
aws glue start-job-run \
  --job-name rds-to-s3-dev \
  --region us-east-1

# Get job run status
aws glue get-job-run \
  --job-name rds-to-s3-dev \
  --run-id <RUN_ID> \
  --region us-east-1

# List job runs
aws glue list-job-runs \
  --job-name rds-to-s3-dev \
  --region us-east-1
```

### Monitoring

```bash
# RDS Events
aws rds describe-events \
  --source-type db-instance \
  --region us-east-1

# Redshift Events
aws redshift describe-events \
  --region us-east-1

# CloudWatch Logs - RDS
aws logs tail /aws/rds/instance/warehouse-db-dev --follow

# CloudWatch Logs - Redshift
aws logs tail /aws/redshift/cluster/warehouse-cluster-dev --follow

# CloudWatch Logs - Glue
aws logs tail /aws-glue/jobs/rds-to-s3-dev --follow
```

### Cost Estimation

```bash
# Get RDS pricing
aws pricing get-products \
  --service-code AmazonRDS \
  --filters Type=TERM_MATCH Key=instanceType Value=db.t3.micro

# Get Redshift pricing
aws pricing get-products \
  --service-code AmazonRedshift \
  --filters Type=TERM_MATCH Key=instanceType Value=dc2.large
```

### Cleanup

```bash
# Delete stack (with confirmation)
./scripts/cleanup.sh dev us-east-1

# Delete stack (force - use with caution)
aws cloudformation delete-stack \
  --stack-name data-warehouse-dev \
  --region us-east-1

# Check deletion status
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --region us-east-1 || echo "Stack deleted"
```

## File Structure Overview

```
cloudformation/
├── 00-master-stack.yaml ........... Main orchestration template
├── 01-s3-bucket.yaml ............. Data lake S3 bucket
├── 02-rds-database.yaml .......... RDS PostgreSQL instance
├── 03-glue-jobs.yaml ............. Glue jobs and catalog
└── 04-redshift-cluster.yaml ....... Redshift cluster

glue/
├── rds-to-s3.py .................. Extract RDS → S3
├── s3-processing.py .............. Transform raw data
└── s3-to-redshift.py ............. Prepare for Redshift

scripts/
├── deploy.sh ..................... Main deployment script
├── cleanup.sh ..................... Stack deletion
└── parameters.json ............... Parameter defaults
```

## S3 Data Lake Structure

```
s3://bucket-name/
├── raw/                 # Raw data from sources
│   ├── rds-data/
│   └── sample-data/
├── processed/           # Cleaned, transformed data
├── curated/             # Aggregated, business-ready data
├── logs/                # Logs and monitoring data
│   ├── redshift-logs/
│   └── spark-logs/
└── glue-scripts/        # Glue job scripts
```

## Environment-Specific Changes

### Development (Small/Quick Testing)

```bash
# Use smallest resources
RDS: db.t3.micro (20GB)
Redshift: 2x dc2.large
```

### Staging (Pre-production)

```bash
# Use medium resources
RDS: db.t3.small (50GB)
Redshift: 4x dc2.large
```

### Production (Full Scale)

```bash
# Use larger resources
RDS: db.m5.xlarge (500GB+)
Redshift: 8+ dc2.8xlarge
```

## Troubleshooting Commands

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --query 'Stacks[0].StackStatus'

# Get failed resources
aws cloudformation describe-stack-resources \
  --stack-name data-warehouse-dev \
  --query 'StackResources[?ResourceStatus==`CREATE_FAILED`]'

# Validate template
aws cloudformation validate-template \
  --template-body file://cloudformation/00-master-stack.yaml

# Check IAM roles
aws iam list-roles | grep -i warehouse

# Check security groups
aws ec2 describe-security-groups | grep -i warehouse
```

## Performance Tuning

### RDS Optimization

```sql
-- Check active connections
SELECT COUNT(*) FROM pg_stat_activity;

-- Check slow queries
SELECT query_start, query FROM pg_stat_activity
WHERE state != 'idle' ORDER BY query_start DESC;
```

### Redshift Optimization

```sql
-- Check query performance
SELECT * FROM stl_query LIMIT 10;

-- Check table statistics
SELECT * FROM pg_tables WHERE schemaname = 'public';

-- Analyze table
ANALYZE table_name;
```

## Useful Links

- [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/)
- [AWS RDS Console](https://console.aws.amazon.com/rds/)
- [AWS Glue Console](https://console.aws.amazon.com/glue/)
- [AWS Redshift Console](https://console.aws.amazon.com/redshiftv2/)
- [AWS S3 Console](https://console.aws.amazon.com/s3/)
- [CloudWatch Logs Console](https://console.aws.amazon.com/logs/)

---

**For detailed information, see README.md**
