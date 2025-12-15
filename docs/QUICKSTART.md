# Quick Start Guide

## Setup in 5 Minutes

### 1. Configure AWS

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your AWS credentials
nano .env
```

### 2. Update Configuration

Edit `config/config.yaml`:

- Replace `your-bucket-name` with your S3 bucket
- Replace `your-key-pair` with your EC2 key pair name

### 3. Create S3 Bucket

```bash
export BUCKET_NAME=your-bucket-name
aws s3 mb s3://$BUCKET_NAME
aws s3 mb s3://$BUCKET_NAME/raw-data
aws s3 mb s3://$BUCKET_NAME/processed-data
aws s3 mb s3://$BUCKET_NAME/scripts
aws s3 mb s3://$BUCKET_NAME/emr-logs
```

### 4. Upload Spark Script

```bash
aws s3 cp scripts/spark_processing.py s3://$BUCKET_NAME/scripts/
```

### 5. Generate Sample Data

```bash
python scripts/generate_sample_data.py
```

### 6. Upload Sample Data to S3

```bash
python scripts/upload_to_s3.py \
  --local-path data/sample_data.parquet \
  --s3-prefix raw-data/
```

### 7. Start Airflow with Docker

```bash
# Set Airflow UID
echo "AIRFLOW_UID=$(id -u)" > .env

# Start services
docker-compose up -d

# Wait for initialization (2-3 minutes)
docker-compose logs -f airflow-init
```

### 8. Access Airflow

- URL: http://localhost:8080
- Username: `admin`
- Password: `admin`

### 9. Configure Airflow Variables

In Airflow UI (Admin > Variables):

```
s3_bucket: your-bucket-name
input_prefix: raw-data/
output_prefix: processed-data/
aws_region: us-east-1
ec2_key_name: your-key-pair
```

### 10. Configure AWS Connection

In Airflow UI (Admin > Connections):

- Connection Id: `aws_default`
- Connection Type: `Amazon Web Services`
- AWS Access Key ID: (your key)
- AWS Secret Access Key: (your secret)
- Region Name: `us-east-1`

### 11. Run the Pipeline

- Go to DAGs page
- Find `big_data_processing_pipeline`
- Click the play button ▶️

## Monitor Progress

- View task progress in Airflow UI
- Check EMR cluster in AWS Console
- View logs: `docker-compose logs -f airflow-scheduler`

## Stop Airflow

```bash
docker-compose down
```

## Troubleshooting

**Issue**: Docker containers won't start
**Solution**: Ensure you have at least 4GB RAM allocated to Docker

**Issue**: Cannot access Airflow UI
**Solution**: Wait 2-3 minutes for initialization, check logs

**Issue**: EMR cluster fails to start
**Solution**: Verify IAM roles exist: `aws emr create-default-roles`

**Issue**: Spark job fails
**Solution**: Check input data exists in S3, verify data format

## Next Steps

- Customize `spark_processing.py` for your data
- Adjust EMR cluster size in `config/config.yaml`
- Set up email notifications
- Configure monitoring with CloudWatch
