# Data Warehousing with AWS CloudFormation

A complete, production-ready data warehousing infrastructure built on AWS using CloudFormation. This solution orchestrates S3, RDS, AWS Glue, and Amazon Redshift to create a scalable, enterprise-grade data warehouse.

## Architecture Overview

```
┌─────────────┐
│   RDS       │
│ PostgreSQL  │
└──────┬──────┘
       │
       ├──────────────┐
       │              │
       │         ┌────▼────┐
       │         │ AWS Glue│
       │         │  Jobs   │
       │         └────┬────┘
       │              │
       │         ┌────▼────┐
┌──────▼──────┐  │   S3    │  ◄──────── Raw ──────► Processed ──────► Curated
│   S3 Data   │  │  Datalake│
│   Lake      │  └────┬────┘
└─────────────┘       │
                 ┌────▼──────────┐
                 │  Amazon       │
                 │  Redshift     │
                 │  Data Warehouse
                 └───────────────┘
```

## Data Flow

1. **Ingestion**: Data extracted from RDS → S3 (Raw layer)
2. **Processing**: Glue jobs transform and clean data → S3 (Processed layer)
3. **Curation**: Data refined and optimized → S3 (Curated layer)
4. **Analytics**: Data loaded into Redshift for analysis and reporting

## Project Structure

```
data-warehousing/
├── cloudformation/                 # CloudFormation templates
│   ├── 00-master-stack.yaml       # Master stack (orchestrates all)
│   ├── 01-s3-bucket.yaml          # S3 data lake bucket
│   ├── 02-rds-database.yaml       # RDS PostgreSQL database
│   ├── 03-glue-jobs.yaml          # Glue jobs and catalog
│   └── 04-redshift-cluster.yaml   # Redshift cluster
├── glue/                           # Glue job scripts
│   ├── rds-to-s3.py               # Extract from RDS → S3
│   ├── s3-processing.py           # Data transformation
│   └── s3-to-redshift.py          # Prepare for Redshift
├── scripts/                        # Deployment scripts
│   ├── deploy.sh                  # Main deployment script
│   ├── cleanup.sh                 # Stack deletion
│   └── parameters.json            # Deployment parameters
├── data/                           # Sample data
└── README.md                       # This file
```

## Prerequisites

1. **AWS Account**: Active AWS account with appropriate permissions
2. **AWS CLI**: Version 2.x or higher
3. **IAM Permissions**: CloudFormation, EC2, RDS, S3, Glue, Redshift, IAM
4. **Bash Shell**: For running deployment scripts
5. **Credentials**: AWS credentials configured (`aws configure`)

### Required IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "s3:*",
        "rds:*",
        "glue:*",
        "redshift:*",
        "ec2:*",
        "iam:*",
        "logs:*",
        "secretsmanager:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Quick Start

### 1. Clone or Download the Project

```bash
cd /path/to/data-warehousing
```

### 2. Make Deployment Script Executable

```bash
chmod +x scripts/deploy.sh
```

### 3. Deploy Infrastructure

```bash
# For development environment
./scripts/deploy.sh dev us-east-1

# For staging environment
./scripts/deploy.sh staging us-east-1

# For production environment
./scripts/deploy.sh prod us-east-1
```

The script will:

- Validate templates
- Upload templates to S3
- Prompt for RDS and Redshift passwords
- Create CloudFormation stack
- Display outputs

### 4. Monitor Deployment

```bash
# View stack events
aws cloudformation describe-stack-events \
  --stack-name data-warehouse-dev \
  --region us-east-1

# View stack status
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --region us-east-1
```

## Configuration

### S3 Bucket Configuration

The S3 bucket includes:

- **Data Lake Structure**: `raw/`, `processed/`, `curated/`, `logs/`
- **Encryption**: AES-256 enabled
- **Versioning**: Enabled for data recovery
- **Lifecycle Policies**: Transition old data to STANDARD_IA after 90 days, GLACIER after 180 days

### RDS Configuration

```yaml
Engine: PostgreSQL 14.7
Instance Types: t3.micro, t3.small, t3.medium, m5.large, m5.xlarge
Storage: 20-65536 GB
Backup Retention: 7 days
Encryption: Enabled
```

### Glue Jobs

Three main Glue jobs are created:

1. **rds-to-s3**: Extract data from RDS → S3 (raw)

   - Removes duplicates
   - Validates data integrity
   - Output format: Parquet

2. **s3-processing**: Transform raw → processed data

   - Data cleaning
   - Schema validation
   - Quality checks
   - Output format: Parquet with metadata

3. **s3-to-redshift**: Prepare data for Redshift
   - Aggregations and refinements
   - Optimal partitioning
   - Redshift-compatible format

### Redshift Configuration

```yaml
Node Types: dc2.large, dc2.8xlarge, ra3.xlplus, ra3.4xlarge, ra3.16xlarge
Cluster: 2+ nodes (configurable)
Database: warehouse
Port: 5439
Backups: Daily snapshots, 7-day retention
Enhanced Monitoring: Enabled
```

## Deployment Parameters

### Environment-Specific Parameters

| Parameter        | Dev         | Staging     | Prod         |
| ---------------- | ----------- | ----------- | ------------ |
| RDS Instance     | db.t3.micro | db.t3.small | db.m5.xlarge |
| RDS Storage      | 20 GB       | 50 GB       | 500 GB       |
| Redshift Nodes   | 2           | 4           | 8+           |
| Node Type        | dc2.large   | dc2.large   | dc2.8xlarge  |
| Backup Retention | 7 days      | 14 days     | 30 days      |

### Custom Parameters

Modify `cloudformation/parameters.json` or pass during deployment:

```bash
./scripts/deploy.sh dev us-east-1 \
  --parameter-overrides \
    RDSInstanceClass=db.t3.medium \
    RedshiftNumberOfNodes=4
```

## Using the Infrastructure

### Connecting to RDS

```bash
# Get RDS endpoint
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' \
  --output text

# Connect using psql
psql -h <RDS_ENDPOINT> -U admin -d warehouse
```

### Connecting to Redshift

```bash
# Get Redshift endpoint
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`RedshiftEndpoint`].OutputValue' \
  --output text

# Connect using psql
psql -h <REDSHIFT_ENDPOINT> -U admin -d warehouse -p 5439
```

### Uploading Glue Scripts to S3

```bash
BUCKET=$(aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
  --output text)

aws s3 cp glue/rds-to-s3.py s3://$BUCKET/glue-scripts/
aws s3 cp glue/s3-processing.py s3://$BUCKET/glue-scripts/
aws s3 cp glue/s3-to-redshift.py s3://$BUCKET/glue-scripts/
```

### Running Glue Jobs

```bash
# Start RDS to S3 job
aws glue start-job-run \
  --job-name rds-to-s3-dev \
  --region us-east-1

# Monitor job execution
aws glue get-job-run \
  --job-name rds-to-s3-dev \
  --run-id <RUN_ID> \
  --region us-east-1
```

## Scaling Considerations

### For Larger Data Volumes

1. **Increase RDS Storage**: Modify `RDSAllocatedStorage` parameter
2. **Scale Redshift**: Increase `RedshiftNumberOfNodes`
3. **Optimize Glue Jobs**: Adjust executor count in job configurations
4. **S3 Lifecycle**: Adjust transition timelines for cost optimization

### Cost Optimization

- Use **Reserved Instances** for RDS and Redshift in production
- Enable **S3 Intelligent-Tiering** for long-term data retention
- Archive old data to **S3 Glacier**
- Use **Glue job bookmarks** to process only new data
- Monitor CloudWatch metrics and set up budget alerts

## Monitoring and Logging

### CloudWatch Logs

```bash
# RDS logs
aws logs tail /aws/rds/instance/warehouse-db-dev --follow

# Redshift logs
aws logs tail /aws/redshift/cluster/warehouse-cluster-dev --follow

# Glue job logs
aws logs tail /aws-glue/jobs/<JOB_NAME> --follow
```

### CloudWatch Metrics

Monitor:

- **RDS**: CPU, Connections, Read/Write IOPS
- **Redshift**: CPU, Query Performance, Storage
- **Glue**: Job run duration, success rate
- **S3**: Request metrics, storage size

## Cleanup

To delete all infrastructure:

```bash
# Delete main stack (automatically deletes nested stacks)
aws cloudformation delete-stack \
  --stack-name data-warehouse-dev \
  --region us-east-1

# Monitor deletion
aws cloudformation wait stack-delete-complete \
  --stack-name data-warehouse-dev \
  --region us-east-1
```

## Troubleshooting

### Common Issues

**Issue**: Stack creation fails with "Insufficient capacity"

- **Solution**: Reduce node count or change instance type

**Issue**: RDS connection timeout

- **Solution**: Check security group rules allow your IP

**Issue**: Glue job fails to connect to RDS

- **Solution**: Verify RDS endpoint and credentials in Secrets Manager

**Issue**: S3 access denied for Glue jobs

- **Solution**: Verify IAM role policies and S3 bucket permissions

### Debug Commands

```bash
# Validate template
aws cloudformation validate-template \
  --template-body file://cloudformation/01-s3-bucket.yaml

# Get stack events
aws cloudformation describe-stack-events \
  --stack-name data-warehouse-dev

# Check stack status
aws cloudformation describe-stacks \
  --stack-name data-warehouse-dev

# View IAM role attached policies
aws iam list-role-policies --role-name GlueServiceRole-dev
```

## Best Practices

1. **Secrets Management**: Store sensitive data in AWS Secrets Manager
2. **VPC**: Deploy in private VPC with NAT Gateway for security
3. **Backup**: Enable automated backups for RDS and Redshift
4. **Monitoring**: Set up CloudWatch alarms for critical metrics
5. **Testing**: Validate data quality in each pipeline stage
6. **Versioning**: Use parameter store for environment-specific configs
7. **Documentation**: Maintain data dictionary and transformation logic
8. **Access Control**: Implement least privilege IAM policies

## Security Considerations

- Enable encryption at rest and in transit
- Use IAM roles instead of long-term credentials
- Implement VPC endpoints for private connectivity
- Enable multi-factor authentication (MFA) for AWS account
- Regularly rotate database passwords
- Monitor API calls with AWS CloudTrail
- Enable VPC Flow Logs for network monitoring

## Cost Estimation (Monthly)

| Component     | Type         | Estimated Cost    |
| ------------- | ------------ | ----------------- |
| S3            | 1TB storage  | ~$23              |
| RDS           | db.t3.small  | ~$100-150         |
| Redshift      | 2x dc2.large | ~$1,500-2,000     |
| Glue          | Job runs     | ~$50-200          |
| Data Transfer | Out of AWS   | varies            |
| **Total**     |              | **~$1,700-2,400** |

_Costs vary by region and usage patterns. Use AWS Pricing Calculator for accurate estimates._

## Additional Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [Amazon RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Amazon Redshift Documentation](https://docs.aws.amazon.com/redshift/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## Support & Contributing

For issues or questions:

1. Check the troubleshooting section
2. Review CloudFormation events for errors
3. Check AWS service logs
4. Consult AWS documentation

## License

This project is provided as-is for educational and commercial use.

## Version History

- **v1.0** (2024): Initial release with S3, RDS, Glue, and Redshift support

---

**Last Updated**: December 2024
