# Big Data Processing with AWS MWAA, EMR, and CloudFormation

Complete infrastructure-as-code solution for production big data processing using AWS Managed Workflows for Apache Airflow (MWAA), EMR, and S3 in a private VPC.

## 📚 Documentation

See [docs/](docs/) directory for comprehensive documentation:

| Document                                                             | Purpose                           |
| -------------------------------------------------------------------- | --------------------------------- |
| [docs/QUICKSTART.md](docs/QUICKSTART.md)                             | Local Airflow development         |
| [docs/MWAA-SETUP.md](docs/MWAA-SETUP.md)                             | Complete MWAA deployment guide    |
| [docs/CI-CD-SETUP-SUMMARY.md](docs/CI-CD-SETUP-SUMMARY.md)           | CI/CD quick start                 |
| [docs/CI-CD-GUIDE.md](docs/CI-CD-GUIDE.md)                           | Complete GitHub Actions setup     |
| [docs/GITHUB-ACTIONS-QUICK-REF.md](docs/GITHUB-ACTIONS-QUICK-REF.md) | Workflows quick reference         |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)                         | Code style and contribution guide |
| [.github/workflows/README.md](.github/workflows/README.md)           | Workflow details                  |
| [tests/README.md](tests/README.md)                                   | Unit testing guide                |

## 🎯 What's New - MWAA & CloudFormation Support

### AWS MWAA (Managed Airflow)

- ✅ Fully managed Apache Airflow 2.7.2
- ✅ Private VPC deployment with security groups
- ✅ Auto-scaling workers (1-2 workers)
- ✅ CloudWatch logging and monitoring
- ✅ AWS IAM authentication

### CloudFormation Infrastructure

- ✅ Complete IaC with 4 modular templates
- ✅ Private VPC with NAT Gateway and S3 VPC Endpoint
- ✅ Least-privilege IAM roles for MWAA and EMR
- ✅ Encrypted S3 buckets with lifecycle policies
- ✅ Security groups and network isolation

### Security & Compliance

- ✅ All resources in private subnets
- ✅ S3 encryption at rest (SSE-S3)
- ✅ VPC Flow Logs enabled
- ✅ Public access blocked on all S3 buckets
- ✅ TLS required for data transfer

### CI/CD Pipeline

- ✅ Automated testing with GitHub Actions
- ✅ Code validation and linting
- ✅ CloudFormation template validation
- ✅ Security scanning for vulnerabilities
- ✅ Automated development deployment
- ✅ Manual production deployment with approval
- ✅ Automated release management

## 🚀 Quick Start - MWAA Deployment

### Deploy Infrastructure (3 Commands)

```bash
# 1. Deploy CloudFormation stacks (30-40 min)
cd scripts
./deploy-infrastructure.sh dev us-east-1

# 2. Load configuration
source ../config/aws-infrastructure.env

# 3. Upload DAGs and files to MWAA
./upload-to-mwaa.sh
```

### Access MWAA

```bash
# Get MWAA URL
echo $MWAA_WEBSERVER_URL

# Or open via AWS Console
# MWAA → Environments → Open Airflow UI
```

## 🏗️ Architecture

### MWAA Architecture (Private VPC)

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │               VPC (10.0.0.0/16)                    │    │
│  │                                                     │    │
│  │  ┌──────────────┐        ┌──────────────┐        │    │
│  │  │   MWAA       │────────│  EMR Cluster │        │    │
│  │  │  (Airflow)   │  Jobs  │   (Spark)    │        │    │
│  │  │  Private     │        │   Private    │        │    │
│  │  └──────┬───────┘        └──────┬───────┘        │    │
│  │         │                        │                 │    │
│  │         └────────┬───────────────┘                │    │
│  │                  │                                 │    │
│  │         ┌────────▼──────────┐                     │    │
│  │         │  S3 VPC Endpoint  │                     │    │
│  │         └───────────────────┘                     │    │
│  │                                                     │    │
│  │  NAT Gateway ──► Internet Gateway                 │    │
│  │  (Outbound only)                                   │    │
│  └────────────────────────────────────────────────────┘    │
│                            │                                │
│  ┌─────────────────────────▼──────────────────────┐       │
│  │              S3 Buckets (Encrypted)             │       │
│  │  • Data Bucket (raw/processed)                  │       │
│  │  • MWAA Bucket (DAGs/plugins/requirements)      │       │
│  │  • EMR Logs Bucket                              │       │
│  └─────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### Local Docker Architecture (Alternative)

```
Local Machine → Docker Airflow → EMR Cluster (Spark) → S3
```

## 📁 Project Structure

```
big-data-processing/
├── cloudformation/                    # Infrastructure as Code
│   ├── 01-vpc-infrastructure.yaml     # VPC, subnets, NAT, endpoints
│   ├── 02-iam-roles.yaml              # MWAA, EMR roles (least privilege)
│   ├── 03-s3-buckets.yaml             # Data, MWAA, logs buckets
│   └── 04-mwaa-environment.yaml       # MWAA environment setup
├── dags/                              # Airflow DAGs
│   └── big_data_processing_dag.py     # MWAA-compatible DAG
├── scripts/                           # Automation & processing
│   ├── deploy-infrastructure.sh       # Deploy all CloudFormation stacks
│   ├── upload-to-mwaa.sh             # Upload DAGs/files to MWAA S3
│   ├── destroy-infrastructure.sh      # Clean up all resources
│   ├── spark_processing.py            # PySpark job for EMR
│   ├── generate_sample_data.py        # Test data generator
│   └── upload_to_s3.py               # S3 upload utility
├── utils/                            # Python utilities
│   ├── s3_helper.py                  # S3 operations
│   └── config_loader.py              # Config management
├── config/
│   ├── config.yaml                   # Application configuration
│   └── aws-infrastructure.env        # Generated by deployment script
├── data/                             # Local data (for testing)
├── logs/                             # Application logs
├── requirements.txt                  # Python dependencies
├── docker-compose.yml                # Local Airflow setup (alternative)
├── .env.example                      # Environment template
├── docs/                             # Documentation
└── README.md                         # This file
```

## Prerequisites

### For MWAA Deployment

- AWS Account with IAM permissions
- AWS CLI configured (`aws configure`)
- Bash shell (Linux/macOS/WSL)

### For Local Development

- Python 3.8+
- Docker and Docker Compose
- AWS CLI configured

## 🔧 Setup Options

### Option 1: AWS MWAA (Recommended for Production)

**Advantages:**

- Fully managed Airflow
- Auto-scaling and high availability
- Integrated monitoring and logging
- Private VPC deployment
- No server maintenance

**See [docs/MWAA-SETUP.md](docs/MWAA-SETUP.md) for complete guide**

Quick deploy:

```bash
cd scripts
./deploy-infrastructure.sh dev us-east-1
source ../config/aws-infrastructure.env
./upload-to-mwaa.sh
```

### Option 2: Local Docker Airflow

**Advantages:**

- No AWS MWAA costs
- Fast iteration for development
- Full control over configuration

**See [docs/QUICKSTART.md](docs/QUICKSTART.md) for setup**

Quick start:

```bash
cp .env.example .env
# Edit .env with your AWS credentials
docker-compose up -d
# Access: http://localhost:8080
```

## 🏗️ Infrastructure Components (CloudFormation)

### 1. VPC Infrastructure (`01-vpc-infrastructure.yaml`)

- **VPC**: 10.0.0.0/16 with DNS enabled
- **Private Subnets**: 2 subnets (Multi-AZ) for MWAA/EMR
- **Public Subnets**: 2 subnets for NAT Gateway
- **NAT Gateway**: Outbound internet access
- **S3 VPC Endpoint**: Private S3 access (no data transfer costs)
- **Security Groups**: MWAA, EMR Master, EMR Worker
- **VPC Flow Logs**: Network monitoring

### 2. IAM Roles (`02-iam-roles.yaml`)

**Least Privilege Policies:**

- **MWAA Execution Role**: S3, EMR, CloudWatch, IAM PassRole
- **EMR Service Role**: EC2, EMR cluster management
- **EMR EC2 Instance Profile**: S3 data access, CloudWatch, Glue Catalog
- **Lambda Execution Role**: Future automation support

### 3. S3 Buckets (`03-s3-buckets.yaml`)

**All buckets encrypted (AES-256) with versioning:**

- **Data Bucket**: Raw/processed data with lifecycle policies
  - Archive to Glacier after 90 days
  - Delete temp files after 7 days
- **MWAA Bucket**: DAGs, plugins, requirements
  - Version retention for 30 days
- **EMR Logs Bucket**: Cluster logs
  - Archive to Glacier after 14 days
  - Delete after 30 days
- **Athena Results Bucket**: Query results (optional)
  - Delete after 7 days

### 4. MWAA Environment (`04-mwaa-environment.yaml`)

- **Airflow Version**: 2.7.2
- **Environment Class**: mw1.small (scalable)
- **Workers**: 1-2 (auto-scaling)
- **Web Access**: Private (IAM authentication)
- **Logging**: All logs to CloudWatch
- **Monitoring**: CloudWatch alarms for health/failures

## 🔒 Security Features

### Network Security

✅ All compute in private subnets  
✅ No direct internet access  
✅ NAT Gateway for outbound only  
✅ S3 VPC Endpoint for private access  
✅ Security groups with least privilege  
✅ VPC Flow Logs enabled

### Data Security

✅ S3 encryption at rest (AES-256)  
✅ S3 versioning enabled  
✅ Public access blocked  
✅ TLS required for all S3 operations  
✅ Encrypted EMR clusters

### Access Control

✅ IAM roles (no access keys)  
✅ Least privilege policies  
✅ Resource-level permissions  
✅ PassRole restrictions  
✅ Service-specific policies

## 💰 Cost Estimates

### MWAA Environment

- **mw1.small**: ~$350/month (development)
- **mw1.medium**: ~$700/month (production)
- **mw1.large**: ~$1,400/month (high scale)

### EMR Processing

- **Per Job**: $1-3 for 1-2 hours
- Uses SPOT instances (70% savings)
- Auto-terminates after completion

### Networking

- **NAT Gateway**: ~$32/month + $0.045/GB
- **VPC Endpoint**: Free for S3 Gateway
- **Data Transfer**: $0.09/GB out to internet

### Storage

- **S3 Standard**: $0.023/GB/month
- **S3 Glacier**: $0.004/GB/month (with lifecycle)
- **CloudWatch Logs**: $0.50/GB ingested

**Total (Dev Environment):** ~$400-500/month

## 📊 Monitoring & Observability

### CloudWatch Logs

```bash
# MWAA logs
aws logs tail /aws/mwaa/$MWAA_ENVIRONMENT_NAME --follow

# EMR logs
aws s3 ls s3://$EMR_LOGS_BUCKET_NAME/ --recursive
```

### CloudWatch Metrics

- MWAA environment health
- Task success/failure rates
- Scheduler heartbeat
- Worker CPU/memory

### Pre-configured Alarms

- Environment unhealthy
- High task failure rate
- SNS notifications (configurable)

## 🛠️ Usage

### Deploy Full Stack

```bash
cd scripts
./deploy-infrastructure.sh <env> <region>
# Example: ./deploy-infrastructure.sh dev us-east-1
# Duration: 30-40 minutes
```

### Upload DAGs & Data

```bash
source ../config/aws-infrastructure.env
./upload-to-mwaa.sh
# Uploads: DAGs, requirements, plugins, sample data
```

### Access MWAA

```bash
echo $MWAA_WEBSERVER_URL
# Opens: https://xxxxxxxxxx.airflow.region.amazonaws.com/home
```

### Trigger Pipeline

1. Navigate to MWAA web UI
2. Find `big_data_processing_pipeline`
3. Unpause DAG
4. Click "Trigger DAG"

### Monitor Execution

- View in MWAA UI (Graph/Grid/Gantt)
- Check CloudWatch Logs
- Monitor EMR in AWS Console

### Destroy Everything

```bash
./scripts/destroy-infrastructure.sh <env> <region>
# Warning: Deletes all resources!
```

## 🔄 Pipeline Flow

1. **List S3 Files** → Validates input data exists
2. **Validate Data** → Pre-processing checks
3. **Create EMR Cluster** → Provisions compute in private VPC
4. **Submit Spark Job** → Processes data with PySpark
5. **Wait for Completion** → Monitors job status (polls every 60s)
6. **Terminate Cluster** → Auto-cleanup (cost optimization)
7. **Notify** → Completion notification (extensible)

## ⚙️ Configuration

### Environment Variables (MWAA)

Set in `04-mwaa-environment.yaml` or via AWS Console:

```yaml
PROJECT_NAME: big-data-processing
ENVIRONMENT: dev
AWS_REGION: us-east-1
DATA_BUCKET_NAME: <auto-generated-bucket-name>
MWAA_BUCKET_NAME: <auto-generated-bucket-name>
EMR_LOGS_BUCKET_NAME: <auto-generated-bucket-name>
INPUT_PREFIX: raw-data/
OUTPUT_PREFIX: processed-data/
EMR_SERVICE_ROLE: <role-name-from-cloudformation>
EMR_INSTANCE_PROFILE: <profile-name-from-cloudformation>
EMR_SUBNET_ID: <private-subnet-id>
EMR_MASTER_SECURITY_GROUP: <sg-id>
EMR_SLAVE_SECURITY_GROUP: <sg-id>
```

DAG automatically reads these from environment.

## 🎓 Key Features

### DAG Features

✅ MWAA-compatible (env vars)  
✅ Backward compatible with local Airflow  
✅ Dynamic config from environment  
✅ VPC-aware EMR provisioning  
✅ Auto-cleanup and cost optimization  
✅ Retry logic with exponential backoff

### Spark Job Features

✅ Multi-format support (Parquet/CSV/JSON)  
✅ Data cleaning & deduplication  
✅ Configurable transformations  
✅ Aggregation support  
✅ Summary statistics  
✅ Partitioned output for efficiency

## 🚦 Multi-Environment Support

Deploy isolated environments:

```bash
# Development
./deploy-infrastructure.sh dev us-east-1

# Staging
./deploy-infrastructure.sh staging us-east-1

# Production
./deploy-infrastructure.sh prod us-east-1
```

Each gets separate: VPC, S3 buckets, IAM roles, MWAA environment

## 🔍 Troubleshooting

### MWAA Environment Won't Create

- Check subnets in different AZs
- Verify security group self-referencing rule
- Check MWAA execution role permissions
- Review CloudFormation events

### DAGs Not Appearing

- Wait 2-5 minutes for MWAA sync
- Check S3 path: `s3://bucket/dags/`
- Review dag-processing logs in CloudWatch
- Verify no Python syntax errors

### EMR Cluster Fails

- Verify subnet has NAT Gateway route
- Check security group rules (master ↔ slave)
- Verify IAM roles exist
- Check EMR service limits

**See [docs/MWAA-SETUP.md](docs/MWAA-SETUP.md) for detailed troubleshooting**

## 📝 Best Practices

1. **Use Environment Variables** - Never hardcode values
2. **Tag All Resources** - Enable cost allocation
3. **Enable Monitoring** - CloudWatch dashboards
4. **Test in Dev First** - Validate before production
5. **Regular Backups** - S3 versioning + cross-region replication
6. **Least Privilege IAM** - Granular permissions
7. **SPOT for EMR Workers** - 70% cost savings
8. **Auto-terminate Clusters** - No idle compute costs
9. **Lifecycle Policies** - Archive old data to Glacier
10. **VPC Endpoints** - Reduce NAT Gateway costs

## 🆚 MWAA vs Local Airflow

| Feature           | MWAA                  | Local Docker        |
| ----------------- | --------------------- | ------------------- |
| Setup Time        | 30 min                | 5 min               |
| Maintenance       | AWS managed           | Self-managed        |
| Scaling           | Automatic             | Manual              |
| High Availability | Built-in 99.9% SLA    | Requires setup      |
| Security          | VPC, IAM integrated   | Self-configured     |
| Monitoring        | CloudWatch integrated | Custom setup        |
| Cost              | ~$350/mo minimum      | Infrastructure only |
| Updates           | Automatic             | Manual              |
| Use Case          | Production            | Development         |

## 📚 Documentation

- **[docs/MWAA-SETUP.md](docs/MWAA-SETUP.md)** - Complete MWAA deployment guide with troubleshooting
- **[QUICKSTART.md](QUICKSTART.md)** - Local Docker Airflow setup
- **CloudFormation templates** - Inline documentation in YAML files

## 📖 Additional Resources

- [AWS MWAA Documentation](https://docs.aws.amazon.com/mwaa/)
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [AWS EMR Best Practices](https://docs.aws.amazon.com/emr/)
- [CloudFormation Templates](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-guide.html)

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Test infrastructure changes in dev
4. Update documentation
5. Submit pull request

## 📄 License

MIT License - Free to use for your projects

## ⚠️ Important Notes

- **MWAA deployment takes 20-30 minutes** - Be patient!
- **NAT Gateway costs** ~$32/month minimum - Consider VPC endpoints
- **Always use private subnets** for security compliance
- **Test destroy script in dev** before using in production
- **Enable CloudTrail** for audit logging
- **Configure SNS** for production alerts

## 🎬 Getting Started

**For Production (MWAA):**

```bash
cd scripts
./deploy-infrastructure.sh dev us-east-1
source ../config/aws-infrastructure.env
./upload-to-mwaa.sh
# Access MWAA UI via $MWAA_WEBSERVER_URL
```

**For Development (Local):**

```bash
cp .env.example .env
# Edit .env with AWS credentials
docker-compose up -d
# Access: http://localhost:8080 (admin/admin)
```

---

**Questions?** See [MWAA-SETUP.md](MWAA-SETUP.md) for comprehensive documentation.

**Need Help?** Check troubleshooting section or review CloudWatch logs.

## AWS Setup

### 1. S3 Buckets

Create an S3 bucket for storing data and scripts:

```bash
aws s3 mb s3://your-bucket-name
aws s3 mb s3://your-bucket-name/raw-data
aws s3 mb s3://your-bucket-name/processed-data
aws s3 mb s3://your-bucket-name/scripts
aws s3 mb s3://your-bucket-name/emr-logs
```

### 2. IAM Roles

Create necessary IAM roles for EMR:

**EMR Service Role** (`EMR_DefaultRole`):

- Allows EMR to access EC2, S3, and other AWS services

**EMR EC2 Instance Profile** (`EMR_EC2_DefaultRole`):

- Allows EC2 instances to access S3 and other required services

```bash
aws emr create-default-roles
```

### 3. EC2 Key Pair

Create an EC2 key pair for SSH access to EMR cluster:

```bash
aws ec2 create-key-pair --key-name your-key-pair --query 'KeyMaterial' --output text > your-key-pair.pem
chmod 400 your-key-pair.pem
```

## Installation

### 1. Clone and Setup

```bash
cd big-data-processing
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your AWS credentials and configuration
```

### 3. Update Configuration

Edit `config/config.yaml` and update:

- S3 bucket names
- EC2 key pair name
- AWS region
- EMR cluster configuration

### 4. Upload Scripts to S3

```bash
aws s3 cp scripts/spark_processing.py s3://your-bucket-name/scripts/
```

## Running with Docker (Local Airflow)

### 1. Start Airflow

```bash
docker-compose up -d
```

### 2. Access Airflow UI

Open browser and navigate to: `http://localhost:8080`

- Username: `admin`
- Password: `admin`

### 3. Configure Airflow Variables

In Airflow UI, go to Admin > Variables and add:

- `s3_bucket`: your-bucket-name
- `input_prefix`: raw-data/
- `output_prefix`: processed-data/
- `aws_region`: us-east-1
- `ec2_key_name`: your-key-pair

### 4. Configure AWS Connection

In Airflow UI, go to Admin > Connections:

- Connection Id: `aws_default`
- Connection Type: `Amazon Web Services`
- AWS Access Key ID: your_access_key
- AWS Secret Access Key: your_secret_key
- Region Name: us-east-1

## Usage

### 1. Upload Sample Data

```bash
# Upload your raw data to S3
aws s3 cp your-data.parquet s3://your-bucket-name/raw-data/
```

### 2. Trigger DAG

In Airflow UI:

- Navigate to DAGs
- Find `big_data_processing_pipeline`
- Click the play button to trigger

Or via CLI:

```bash
airflow dags trigger big_data_processing_pipeline
```

### 3. Monitor Progress

- Monitor in Airflow UI
- Check EMR cluster in AWS Console
- View logs in CloudWatch

### 4. Retrieve Results

```bash
# Download processed data
aws s3 sync s3://your-bucket-name/processed-data/ ./local-results/
```

## Pipeline Stages

1. **List S3 Files**: Validates input data exists
2. **Validate Data**: Performs pre-processing checks
3. **Create EMR Cluster**: Provisions EMR cluster
4. **Add Spark Step**: Submits PySpark job to cluster
5. **Wait for Completion**: Monitors job execution
6. **Terminate Cluster**: Cleans up EMR resources
7. **Notify**: Sends completion notification

## Spark Processing

The PySpark job performs:

- Data ingestion from S3
- Data cleaning (deduplication, null handling)
- Data transformation (business logic)
- Data aggregation
- Results storage to S3

Supported formats: Parquet, CSV, JSON

## Configuration

### S3 Bucket Strategy

You have two options for storing processed data:

#### Option 1: Single Bucket (Default)

All data (raw input and processed output) stored in the same S3 bucket. Cost-efficient and simple to manage.

**Use case**: Development, testing, small-scale deployments

**Deployment**:

```bash
./scripts/deploy-infrastructure.sh dev us-east-1 no
```

**Configuration**:

```yaml
# config/config.yaml
s3:
  data_bucket: my-data-bucket
  use_separate_processed_bucket: false
  processed_bucket: my-data-bucket
```

#### Option 2: Separate Buckets

Raw input data and processed output stored in different buckets. Better for compliance, cost allocation, and organizational separation.

**Use case**: Production, compliance requirements, multi-team setups

**Deployment**:

```bash
./scripts/deploy-infrastructure.sh dev us-east-1 yes
```

**Configuration**:

```yaml
# config/config.yaml
s3:
  data_bucket: my-data-bucket
  use_separate_processed_bucket: true
  processed_bucket: my-processed-bucket
```

**Cost Comparison**:

- Single bucket: $0.023/GB storage (storage cost only)
- Separate buckets: $0.046/GB storage (double storage cost but better organization)

### EMR Cluster

- **Master Node**: 1x m5.xlarge (on-demand)
- **Worker Nodes**: 2x m5.xlarge (spot instances)
- **Applications**: Spark, Hadoop

Customize in `config/config.yaml` or DAG file.

### Spark Configuration

- Adaptive Query Execution enabled
- Dynamic allocation enabled
- Snappy compression for Parquet

## Cost Optimization

- Uses SPOT instances for worker nodes
- Terminates cluster after job completion
- Enables auto-scaling (optional)
- Compressed storage format (Parquet with Snappy)

## Monitoring

- Airflow task logs
- EMR cluster logs in S3
- CloudWatch metrics (optional)
- SNS notifications (optional)

## Troubleshooting

### EMR Cluster Fails to Start

- Check IAM roles are created
- Verify subnet and security group settings
- Check AWS service quotas

### Spark Job Fails

- Check input data path in S3
- Verify data format matches configuration
- Review EMR logs in S3
- Check Spark driver/executor memory settings

### Airflow Connection Issues

- Verify AWS credentials in connection
- Check AWS permissions for Airflow IAM user
- Ensure security groups allow necessary traffic

## Sample Data Format

Expected input data structure (CSV example):

```csv
id,timestamp,category,amount,status
1,2025-01-01 00:00:00,A,100.50,active
2,2025-01-01 01:00:00,B,200.75,inactive
```

## Development

### Local Testing

Test Spark job locally before deploying:

```bash
spark-submit \
  --master local[*] \
  scripts/spark_processing.py \
  --input-path data/sample_input/ \
  --output-path data/sample_output/ \
  --input-format csv
```

### Adding Custom Transformations

Edit `scripts/spark_processing.py` and modify:

- `transform_data()` function for business logic
- `aggregate_data()` function for aggregations

## CI/CD Pipeline (GitHub Actions)

Automated testing, validation, and deployment using GitHub Actions.

### Workflows

| Workflow                | Trigger                    | Purpose                                          |
| ----------------------- | -------------------------- | ------------------------------------------------ |
| **Validate**            | Push/PR to main/develop    | Python code validation, linting, unit tests      |
| **CloudFormation Lint** | Changes to cloudformation/ | Template syntax and best practice validation     |
| **Security Scan**       | Push/PR, Weekly            | Detect secrets, vulnerabilities, security issues |
| **DAG Syntax Check**    | Changes to dags/           | Airflow DAG parsing and syntax validation        |
| **Deploy to Dev**       | Push to develop            | Automated deployment to development environment  |
| **Deploy to Prod**      | Manual workflow_dispatch   | Manual production deployment with approval       |
| **Release**             | Push version tag (v\*)     | Create releases and publish artifacts            |

### Setup

1. **Configure AWS OIDC** in GitHub and AWS for credential-free authentication
2. **Add GitHub Secrets**:
   ```
   AWS_ROLE_TO_ASSUME=arn:aws:iam::DEV_ACCOUNT:role/GitHubActionsRole
   AWS_ROLE_TO_ASSUME_PROD=arn:aws:iam::PROD_ACCOUNT:role/GitHubActionsRole
   ```
3. **Set Branch Protection** on main branch requiring status checks
4. **Create CODEOWNERS** for review requirements

### Quick Start

**Deploy to Development**:

```bash
# Push to develop branch
git checkout -b feature/my-feature
git commit -m "Add feature"
git push origin feature/my-feature

# Create pull request - validates automatically
# After merge to develop - deploys automatically
```

**Deploy to Production**:

```bash
# Manual workflow dispatch
# Go to GitHub Actions → Deploy to Production
# Select separate_buckets option
# Confirm deployment
```

**Create Release**:

```bash
# Tag a version
git tag v1.0.0
git push origin v1.0.0

# Release workflow runs automatically
```

### Status Checks

All workflows must pass before merging to `main`:

- ✅ Code validation (Black, isort, Flake8, Pylint)
- ✅ Unit tests with coverage > 80%
- ✅ CloudFormation templates valid
- ✅ DAG syntax valid
- ✅ No hardcoded secrets or credentials
- ✅ No dependency vulnerabilities

See `.github/workflows/README.md` for detailed workflow documentation.

## Security Best Practices

- Use IAM roles instead of hardcoded credentials
- Enable S3 bucket encryption
- Use VPC for EMR cluster
- Implement least privilege access
- Enable CloudTrail logging
- Use AWS Secrets Manager for sensitive data

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## License

MIT License - feel free to use for your projects

## Support

For issues and questions:

- Check troubleshooting section
- Review AWS EMR documentation
- Review Apache Airflow documentation

## Future Enhancements

- [ ] Add data quality validation with Great Expectations
- [ ] Implement incremental processing
- [ ] Add Athena integration for querying results
- [x] Set up CI/CD pipeline (GitHub Actions)
- [ ] Add more comprehensive unit tests
- [ ] Implement data lineage tracking
- [ ] Add Glue Catalog integration

## References

- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [AWS EMR Documentation](https://docs.aws.amazon.com/emr/)
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Airflow AWS Provider](https://airflow.apache.org/docs/apache-airflow-providers-amazon/)
