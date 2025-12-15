#!/bin/bash
# Upload DAGs, requirements, and scripts to MWAA S3 bucket

set -e

# Configuration
CONFIG_FILE="../config/aws-infrastructure.env"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Upload Files to MWAA${NC}"
echo -e "${GREEN}========================================${NC}"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "Loaded configuration from $CONFIG_FILE"
else
    echo -e "${RED}Error: Configuration file not found${NC}"
    echo "Run ./deploy-infrastructure.sh first"
    exit 1
fi

# Verify required variables
if [ -z "$MWAA_BUCKET_NAME" ] || [ -z "$DATA_BUCKET_NAME" ]; then
    echo -e "${RED}Error: Required environment variables not set${NC}"
    exit 1
fi

echo ""
echo "MWAA Bucket: $MWAA_BUCKET_NAME"
echo "Data Bucket: $DATA_BUCKET_NAME"
echo "AWS Region: $AWS_REGION"
echo ""

# Change to project root
cd "$(dirname "$0")/.."

# Step 1: Upload DAGs
echo -e "${YELLOW}Step 1: Uploading DAGs${NC}"
aws s3 sync dags/ "s3://${MWAA_BUCKET_NAME}/dags/" \
    --exclude "*.pyc" \
    --exclude "__pycache__/*" \
    --region "$AWS_REGION"
echo -e "${GREEN}✓ DAGs uploaded${NC}\n"

# Step 2: Create and upload requirements.txt for MWAA
echo -e "${YELLOW}Step 2: Creating MWAA requirements.txt${NC}"
cat > /tmp/mwaa-requirements.txt << 'EOF'
# MWAA Requirements
# Only include packages not already in MWAA base image

# AWS Providers (may already be included, check MWAA version)
apache-airflow-providers-amazon>=8.11.0

# Data Processing
pandas==2.1.4

# Configuration
pyyaml==6.0.1
python-dotenv==1.0.0
EOF

aws s3 cp /tmp/mwaa-requirements.txt "s3://${MWAA_BUCKET_NAME}/requirements.txt" \
    --region "$AWS_REGION"
echo -e "${GREEN}✓ Requirements uploaded${NC}\n"

# Step 3: Create and upload plugins (if any)
echo -e "${YELLOW}Step 3: Creating plugins package${NC}"
if [ -d "utils" ]; then
    # Create plugins directory structure
    mkdir -p /tmp/mwaa-plugins/utils
    cp -r utils/* /tmp/mwaa-plugins/utils/
    
    # Create plugins.zip
    cd /tmp/mwaa-plugins
    zip -r ../plugins.zip . -x "*.pyc" -x "*__pycache__*"
    cd -
    
    aws s3 cp /tmp/plugins.zip "s3://${MWAA_BUCKET_NAME}/plugins.zip" \
        --region "$AWS_REGION"
    echo -e "${GREEN}✓ Plugins uploaded${NC}\n"
    
    # Cleanup
    rm -rf /tmp/mwaa-plugins /tmp/plugins.zip
else
    echo "No plugins to upload"
fi

# Step 4: Upload Spark scripts to data bucket
echo -e "${YELLOW}Step 4: Uploading Spark scripts${NC}"
aws s3 cp scripts/spark_processing.py "s3://${MWAA_BUCKET_NAME}/scripts/spark_processing.py" \
    --region "$AWS_REGION"
echo -e "${GREEN}✓ Spark scripts uploaded${NC}\n"

# Step 5: Create sample data and upload
echo -e "${YELLOW}Step 5: Creating and uploading sample data${NC}"
if [ -f "scripts/generate_sample_data.py" ]; then
    echo "Generating sample data..."
    python3 scripts/generate_sample_data.py
    
    if [ -f "data/sample_data.parquet" ]; then
        aws s3 cp data/sample_data.parquet "s3://${DATA_BUCKET_NAME}/${INPUT_PREFIX}sample_data.parquet" \
            --region "$AWS_REGION"
        echo -e "${GREEN}✓ Sample data uploaded${NC}\n"
    fi
else
    echo "Sample data generator not found, skipping..."
fi

# Step 6: Verify uploads
echo -e "${YELLOW}Step 6: Verifying uploads${NC}"
echo ""
echo "MWAA Bucket Contents:"
aws s3 ls "s3://${MWAA_BUCKET_NAME}/" --recursive --region "$AWS_REGION" | head -20
echo ""
echo "Data Bucket Contents:"
aws s3 ls "s3://${DATA_BUCKET_NAME}/" --recursive --region "$AWS_REGION" | head -20
echo ""

# Step 7: Update MWAA environment (if requirements or plugins changed)
echo -e "${YELLOW}Step 7: MWAA environment will auto-update${NC}"
echo "MWAA will automatically detect and load new DAGs, requirements, and plugins"
echo "This may take a few minutes..."
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Upload Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next Steps:"
echo "1. Wait for MWAA to sync (2-5 minutes)"
echo "2. Access MWAA: ${MWAA_WEBSERVER_URL}"
echo "3. Check DAG: big_data_processing_pipeline"
echo ""
echo "To check MWAA environment status:"
echo "aws mwaa get-environment --name ${MWAA_ENVIRONMENT_NAME} --region ${AWS_REGION}"
echo ""
echo "To view MWAA logs:"
echo "aws logs tail /aws/mwaa/${MWAA_ENVIRONMENT_NAME} --follow --region ${AWS_REGION}"
