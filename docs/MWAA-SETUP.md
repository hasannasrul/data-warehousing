# AWS MWAA Setup Guide

## Complete Infrastructure Deployment with CloudFormation

This guide walks you through deploying a production-ready big data processing infrastructure using AWS Managed Workflows for Apache Airflow (MWAA), EMR, and CloudFormation in a private VPC.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                           │
│                                                             │
│  ┌────────────────────────────────────────────────────┐     │
│  │                  VPC (Private)                     │     │
│  │                                                    │     │
│  │  ┌──────────────┐        ┌──────────────┐          │     │
│  │  │   MWAA       │────────│  EMR Cluster │          │     │
│  │  │  (Airflow)   │        │   (Spark)    │          │     │
│  │  └──────────────┘        └──────────────┘          │     │
│  │         │                        │                 │     │
│  │         │                        │                 │     │
│  │  ┌──────▼────────────────────────▼──────┐          │     │
│  │  │         S3 VPC Endpoint               │         │     │
│  │  └───────────────────────────────────────┘         │     │
│  │                                                    │     │
│  │  NAT Gateway ──► Internet Gateway                  │     │
│  └────────────────────────────────────────────────────┘     │
│                            │                                │
│  ┌─────────────────────────▼──────────────────────┐         │
│  │              S3 Buckets                         │        │
│  │  • Data Bucket (raw/processed)                  │        │
│  │  • MWAA Bucket (DAGs/plugins)                   │        │
│  │  • EMR Logs Bucket                              │        │
│  └─────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## Infrastructure Components

### 1. **VPC Infrastructure** (`01-vpc-infrastructure.yaml`)

- Private VPC with 2 private subnets (Multi-AZ)
- 2 public subnets for NAT Gateway
- NAT Gateway for outbound internet access
- S3 VPC Gateway Endpoint (cost-free S3 access)
- Security Groups for MWAA and EMR
- VPC Flow Logs for monitoring

### 2. **IAM Roles** (`02-iam-roles.yaml`)

- **MWAA Execution Role**: Least privilege for Airflow operations
- **EMR Service Role**: EMR cluster management
- **EMR EC2 Role**: Instance-level permissions for Spark jobs
- **Lambda Execution Role**: For future automation

### 3. **S3 Buckets** (`03-s3-buckets.yaml`)

- **Data Bucket**: Raw and processed data with lifecycle policies
- **MWAA Bucket**: DAGs, plugins, requirements with versioning
- **EMR Logs Bucket**: Cluster logs with auto-archival
- **Athena Results Bucket**: Query results (optional)
- All buckets encrypted with SSE-S3
- Public access blocked

### 4. **MWAA Environment** (`04-mwaa-environment.yaml`)

- Managed Apache Airflow 2.7.2
- Private web server access
- Auto-scaling workers (1-2 workers)
- CloudWatch logging enabled
- SNS alerts for failures

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured:
   ```bash
   aws configure
   ```
3. **IAM Permissions** to create:
   - VPC resources
   - IAM roles and policies
   - S3 buckets
   - MWAA environments
   - EMR clusters
   - CloudFormation stacks

## Quick Start (5 Steps)

### Step 1: Deploy Infrastructure

```bash
cd scripts
./deploy-infrastructure.sh dev us-east-1
```

**Parameters:**

- `dev` - Environment name (dev/staging/prod)
- `us-east-1` - AWS region

**Duration:** ~30-40 minutes (MWAA takes 20-30 min)

**What it does:**

1. Creates VPC with subnets and networking
2. Creates S3 buckets with encryption
3. Creates IAM roles with least privilege
4. Deploys MWAA environment
5. Saves configuration to `config/aws-infrastructure.env`

### Step 2: Load Configuration

```bash
source ../config/aws-infrastructure.env
```

This loads all environment variables for subsequent commands.

### Step 3: Upload DAGs and Files

```bash
./upload-to-mwaa.sh
```

**What it uploads:**

- DAGs to MWAA S3 bucket
- Requirements.txt for Python dependencies
- Plugins (utils package)
- Spark processing script
- Sample data to data bucket

### Step 4: Access MWAA

Get the MWAA web URL:

```bash
echo $MWAA_WEBSERVER_URL
```

**Authentication:**

- Uses AWS IAM authentication
- Access via AWS Console → MWAA → Open Airflow UI
- Or use AWS CLI to get temporary login token

### Step 5: Trigger DAG

In MWAA UI:

1. Navigate to DAGs
2. Find `big_data_processing_pipeline`
3. Unpause the DAG
4. Click "Trigger DAG"

## Configuration

### Environment Variables

The DAG reads configuration from environment variables (set in MWAA):

```bash
# Project Configuration
PROJECT_NAME=big-data-processing
ENVIRONMENT=dev
AWS_REGION=us-east-1

# S3 Configuration
DATA_BUCKET_NAME=big-data-processing-dev-data-123456789
MWAA_BUCKET_NAME=big-data-processing-dev-mwaa-123456789
EMR_LOGS_BUCKET_NAME=big-data-processing-dev-emr-logs-123456789
INPUT_PREFIX=raw-data/
OUTPUT_PREFIX=processed-data/

# EMR Configuration
EMR_SERVICE_ROLE=big-data-processing-dev-emr-service-role
EMR_INSTANCE_PROFILE=big-data-processing-dev-emr-ec2-instance-profile
EMR_SUBNET_ID=subnet-xxxxx
EMR_MASTER_SECURITY_GROUP=sg-xxxxx
EMR_SLAVE_SECURITY_GROUP=sg-xxxxx
```

### Setting Environment Variables in MWAA

**Option 1: Via CloudFormation**
Update `04-mwaa-environment.yaml` and add to `AirflowConfigurationOptions`:

```yaml
AirflowConfigurationOptions:
  MY_VARIABLE: value
```

**Option 2: Via AWS Console**

1. Go to MWAA → Environments
2. Select your environment
3. Edit → Environment variables
4. Add key-value pairs
5. Save

**Option 3: Via AWS CLI**

```bash
aws mwaa update-environment \
  --name $MWAA_ENVIRONMENT_NAME \
  --airflow-configuration-options "MY_VARIABLE=value" \
  --region $AWS_REGION
```

## Security Features

### Network Security

- ✅ Private VPC with no direct internet access
- ✅ NAT Gateway for outbound-only traffic
- ✅ S3 VPC Endpoint for private S3 access
- ✅ Security groups with least privilege rules
- ✅ VPC Flow Logs enabled

### Data Security

- ✅ S3 bucket encryption (SSE-S3)
- ✅ S3 bucket versioning enabled
- ✅ Public access blocked on all buckets
- ✅ TLS required for all S3 operations
- ✅ EMR encryption in transit and at rest

### IAM Security

- ✅ Least privilege IAM policies
- ✅ Service-specific roles
- ✅ PassRole restrictions
- ✅ Resource-level permissions

## Cost Optimization

### MWAA Costs

- **mw1.small**: ~$0.49/hour (~$350/month)
- **mw1.medium**: ~$0.98/hour (~$700/month)
- **mw1.large**: ~$1.96/hour (~$1400/month)

**Tip:** Use `mw1.small` for dev, scale up for production

### EMR Costs

- Cluster auto-terminates after jobs
- Uses SPOT instances for worker nodes (~70% savings)
- Minimal master node (m5.xlarge)

**Estimated EMR cost per job run:** $1-3 for 1-2 hours

### S3 Costs

- Lifecycle policies archive old data to Glacier
- Delete temporary files after 7 days
- ~$0.023/GB/month (Standard)
- ~$0.004/GB/month (Glacier)

### NAT Gateway Costs

- ~$0.045/hour (~$32/month)
- ~$0.045/GB data processed

**Tip:** For production, consider VPC endpoints for AWS services

## Monitoring

### CloudWatch Logs

View MWAA logs:

```bash
aws logs tail /aws/mwaa/$MWAA_ENVIRONMENT_NAME --follow
```

View EMR logs:

```bash
aws s3 ls s3://$EMR_LOGS_BUCKET_NAME/ --recursive
```

### CloudWatch Metrics

MWAA metrics available:

- `EnvironmentHealth`
- `TasksFailed`
- `TasksSucceeded`
- `SchedulerHeartbeat`

### Alarms

Pre-configured CloudWatch alarms:

- MWAA environment unhealthy
- High task failure rate

Configure SNS topic for notifications.

## Troubleshooting

### MWAA Environment Fails to Create

**Check:**

1. Subnets are in different AZs
2. Security group allows self-referencing traffic
3. MWAA execution role has correct permissions
4. S3 bucket exists and is accessible

**View errors:**

```bash
aws mwaa get-environment --name $MWAA_ENVIRONMENT_NAME
```

### DAGs Not Appearing

**Causes:**

1. Wrong S3 bucket or path
2. Python syntax errors in DAG
3. MWAA not synced yet (wait 2-5 min)

**Check:**

```bash
aws s3 ls s3://$MWAA_BUCKET_NAME/dags/
aws logs tail /aws/mwaa/$MWAA_ENVIRONMENT_NAME/dag-processing
```

### EMR Cluster Fails to Start

**Check:**

1. Subnet has route to NAT Gateway
2. Security groups allow EMR traffic
3. IAM roles exist and have permissions
4. EMR service limits not exceeded

**View logs:**

```bash
aws s3 ls s3://$EMR_LOGS_BUCKET_NAME/ --recursive
```

### Connection Refused Errors

**Causes:**

1. Security group rules missing
2. VPC endpoint not configured
3. NAT Gateway not working

**Fix:**

```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids $EMR_MASTER_SECURITY_GROUP

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID"
```

## Maintenance

### Update DAGs

```bash
# Make changes to DAG files
vi dags/big_data_processing_dag.py

# Upload to MWAA
./scripts/upload-to-mwaa.sh
```

### Update Requirements

```bash
# Edit requirements
vi /tmp/mwaa-requirements.txt

# Upload
aws s3 cp /tmp/mwaa-requirements.txt s3://$MWAA_BUCKET_NAME/requirements.txt
```

MWAA will automatically detect and apply changes (takes ~10 minutes).

### Update Infrastructure

```bash
# Make changes to CloudFormation templates
vi cloudformation/01-vpc-infrastructure.yaml

# Redeploy
./scripts/deploy-infrastructure.sh dev us-east-1
```

### Scale MWAA

Update in CloudFormation or via CLI:

```bash
aws mwaa update-environment \
  --name $MWAA_ENVIRONMENT_NAME \
  --max-workers 5 \
  --region $AWS_REGION
```

## Cleanup

### Destroy All Resources

```bash
./scripts/destroy-infrastructure.sh dev us-east-1
```

**Warning:** This deletes:

- All S3 data
- MWAA environment
- VPC and networking
- IAM roles

**Duration:** ~30 minutes

### Manual Cleanup (if script fails)

```bash
# Empty S3 buckets
aws s3 rm s3://$DATA_BUCKET_NAME --recursive
aws s3 rm s3://$MWAA_BUCKET_NAME --recursive
aws s3 rm s3://$EMR_LOGS_BUCKET_NAME --recursive

# Delete stacks in order
aws cloudformation delete-stack --stack-name big-data-processing-dev-mwaa
aws cloudformation delete-stack --stack-name big-data-processing-dev-iam
aws cloudformation delete-stack --stack-name big-data-processing-dev-s3
aws cloudformation delete-stack --stack-name big-data-processing-dev-vpc
```

## Production Considerations

### Multi-Environment Setup

Deploy separate stacks:

```bash
# Development
./deploy-infrastructure.sh dev us-east-1

# Staging
./deploy-infrastructure.sh staging us-east-1

# Production
./deploy-infrastructure.sh prod us-east-1
```

### High Availability

- Use multiple AZs (already configured)
- Increase MWAA workers for production
- Consider EMR cluster sizing
- Enable S3 Cross-Region Replication

### Disaster Recovery

- S3 versioning enabled (already)
- Regular EMR log backup
- Export MWAA metadata database
- Document runbooks

### Compliance

- Enable AWS CloudTrail
- Enable AWS Config
- Add resource tagging
- Implement backup strategy

## Best Practices

1. **Tagging**: Add tags for cost allocation
2. **Monitoring**: Set up CloudWatch dashboards
3. **Alerting**: Configure SNS for critical alerts
4. **Testing**: Test in dev before production
5. **Documentation**: Keep runbooks updated
6. **Access Control**: Use IAM roles, not keys
7. **Encryption**: Enable encryption everywhere
8. **Backups**: Regular S3 and metadata backups

## Support

For issues:

1. Check CloudWatch logs
2. Review CloudFormation events
3. Verify IAM permissions
4. Check AWS service quotas
5. Review AWS documentation

## Additional Resources

- [AWS MWAA Documentation](https://docs.aws.amazon.com/mwaa/)
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [AWS EMR Documentation](https://docs.aws.amazon.com/emr/)
- [CloudFormation Best Practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html)
