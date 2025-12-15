#!/bin/bash
# Deploy CloudFormation stacks for Big Data Processing Infrastructure
# This script deploys VPC, IAM Roles, S3 Buckets, and MWAA Environment

set -e  # Exit on error

# Configuration
PROJECT_NAME="big-data-processing"
ENVIRONMENT="${1:-dev}"  # Default to dev if not specified
AWS_REGION="${2:-us-east-1}"  # Default to us-east-1 if not specified
USE_SEPARATE_BUCKETS="${3:-no}"  # Default to no if not specified

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Big Data Processing Infrastructure Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "AWS Region: $AWS_REGION"
echo "Separate Buckets: $USE_SEPARATE_BUCKETS"
echo ""

# Function to wait for stack creation/update
wait_for_stack() {
    local stack_name=$1
    echo -e "${YELLOW}Waiting for stack $stack_name to complete...${NC}"
    aws cloudformation wait stack-create-complete \
        --stack-name "$stack_name" \
        --region "$AWS_REGION" 2>/dev/null || \
    aws cloudformation wait stack-update-complete \
        --stack-name "$stack_name" \
        --region "$AWS_REGION" 2>/dev/null || true
}

# Function to deploy stack
deploy_stack() {
    local stack_name=$1
    local template_file=$2
    local parameters=$3
    
    echo -e "${YELLOW}Deploying stack: $stack_name${NC}"
    echo "Template: $template_file"
    
    if aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo "Stack exists, updating..."
        aws cloudformation update-stack \
            --stack-name "$stack_name" \
            --template-body "file://$template_file" \
            --parameters $parameters \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$AWS_REGION" 2>/dev/null || echo "No updates to perform"
    else
        echo "Creating new stack..."
        aws cloudformation create-stack \
            --stack-name "$stack_name" \
            --template-body "file://$template_file" \
            --parameters $parameters \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$AWS_REGION"
    fi
    
    wait_for_stack "$stack_name"
    echo -e "${GREEN}✓ Stack $stack_name deployed successfully${NC}\n"
}

# Change to cloudformation directory
cd "$(dirname "$0")/../cloudformation"

# Step 1: Deploy VPC Infrastructure
echo -e "${GREEN}Step 1: Deploying VPC Infrastructure${NC}"
deploy_stack \
    "${PROJECT_NAME}-${ENVIRONMENT}-vpc" \
    "01-vpc-infrastructure.yaml" \
    "ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME ParameterKey=Environment,ParameterValue=$ENVIRONMENT"

# Step 2: Deploy S3 Buckets (must be before IAM roles due to bucket names)
echo -e "${GREEN}Step 2: Deploying S3 Buckets${NC}"
deploy_stack \
    "${PROJECT_NAME}-${ENVIRONMENT}-s3" \
    "03-s3-buckets.yaml" \
    "ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME ParameterKey=Environment,ParameterValue=$ENVIRONMENT ParameterKey=UseSeparateProcessedBucket,ParameterValue=$USE_SEPARATE_BUCKETS"

# Get bucket names from stack outputs
DATA_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-s3" \
    --query "Stacks[0].Outputs[?OutputKey=='DataBucketName'].OutputValue" \
    --output text \
    --region "$AWS_REGION")

PROCESSED_BUCKET=""
if [ "$USE_SEPARATE_BUCKETS" == "yes" ]; then
    PROCESSED_BUCKET=$(aws cloudformation describe-stacks \
        --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-s3" \
        --query "Stacks[0].Outputs[?OutputKey=='ProcessedDataBucketName'].OutputValue" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "")
fi

echo "Data Bucket: $DATA_BUCKET"
if [ -n "$PROCESSED_BUCKET" ] && [ "$PROCESSED_BUCKET" != "None" ]; then
    echo "Processed Data Bucket: $PROCESSED_BUCKET"
fi

# Step 3: Deploy IAM Roles
echo -e "${GREEN}Step 3: Deploying IAM Roles${NC}"
if [ -n "$PROCESSED_BUCKET" ] && [ "$PROCESSED_BUCKET" != "None" ]; then
    deploy_stack \
        "${PROJECT_NAME}-${ENVIRONMENT}-iam" \
        "02-iam-roles.yaml" \
        "ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME ParameterKey=Environment,ParameterValue=$ENVIRONMENT ParameterKey=DataBucketName,ParameterValue=$DATA_BUCKET ParameterKey=ProcessedDataBucketName,ParameterValue=$PROCESSED_BUCKET"
else
    deploy_stack \
        "${PROJECT_NAME}-${ENVIRONMENT}-iam" \
        "02-iam-roles.yaml" \
        "ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME ParameterKey=Environment,ParameterValue=$ENVIRONMENT ParameterKey=DataBucketName,ParameterValue=$DATA_BUCKET ParameterKey=ProcessedDataBucketName,ParameterValue=''"
fi

# Step 4: Deploy MWAA Environment
echo -e "${GREEN}Step 4: Deploying MWAA Environment${NC}"
echo -e "${YELLOW}Note: MWAA deployment takes 20-30 minutes${NC}"
deploy_stack \
    "${PROJECT_NAME}-${ENVIRONMENT}-mwaa" \
    "04-mwaa-environment.yaml" \
    "ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME ParameterKey=Environment,ParameterValue=$ENVIRONMENT"

# Get stack outputs
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Stack Outputs:"
echo ""

# VPC Outputs
VPC_ID=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-vpc" \
    --query "Stacks[0].Outputs[?OutputKey=='VPCId'].OutputValue" \
    --output text \
    --region "$AWS_REGION")
echo "VPC ID: $VPC_ID"

PRIVATE_SUBNET_1=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-vpc" \
    --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet1Id'].OutputValue" \
    --output text \
    --region "$AWS_REGION")
echo "Private Subnet 1: $PRIVATE_SUBNET_1"

PRIVATE_SUBNET_2=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-vpc" \
    --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet2Id'].OutputValue" \
    --output text \
    --region "$AWS_REGION")
echo "Private Subnet 2: $PRIVATE_SUBNET_2"

EMR_MASTER_SG=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-vpc" \
    --query "Stacks[0].Outputs[?OutputKey=='EMRMasterSecurityGroupId'].OutputValue" \
    --output text \
    --region "$AWS_REGION")
echo "EMR Master Security Group: $EMR_MASTER_SG"

EMR_SLAVE_SG=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-vpc" \
    --query "Stacks[0].Outputs[?OutputKey=='EMRSlaveSecurityGroupId'].OutputValue" \
    --output text \
    --region "$AWS_REGION")
echo "EMR Slave Security Group: $EMR_SLAVE_SG"

# S3 Outputs
MWAA_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-s3" \
    --query "Stacks[0].Outputs[?OutputKey=='MWAABucketName'].OutputValue" \
    --output text \
    --region "$AWS_REGION")
echo "MWAA Bucket: $MWAA_BUCKET"

EMR_LOGS_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-s3" \
    --query "Stacks[0].Outputs[?OutputKey=='EMRLogsBucketName'].OutputValue" \
    --output text \
    --region "$AWS_REGION")
echo "EMR Logs Bucket: $EMR_LOGS_BUCKET"

if [ -z "$PROCESSED_BUCKET" ] || [ "$PROCESSED_BUCKET" == "None" ]; then
    PROCESSED_BUCKET="$DATA_BUCKET"
fi
echo "Processed Data Bucket: $PROCESSED_BUCKET"

# IAM Outputs
EMR_SERVICE_ROLE=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-iam" \
    --query "Stacks[0].Outputs[?OutputKey=='EMRServiceRoleArn'].OutputValue" \
    --output text \
    --region "$AWS_REGION" | rev | cut -d'/' -f1 | rev)
echo "EMR Service Role: $EMR_SERVICE_ROLE"

EMR_INSTANCE_PROFILE=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-iam" \
    --query "Stacks[0].Outputs[?OutputKey=='EMREC2InstanceProfileName'].OutputValue" \
    --output text \
    --region "$AWS_REGION")
echo "EMR Instance Profile: $EMR_INSTANCE_PROFILE"

# MWAA Outputs
MWAA_ENV_NAME=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-mwaa" \
    --query "Stacks[0].Outputs[?OutputKey=='MWAAEnvironmentName'].OutputValue" \
    --output text \
    --region "$AWS_REGION" 2>/dev/null || echo "Pending...")
echo "MWAA Environment: $MWAA_ENV_NAME"

MWAA_URL=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-mwaa" \
    --query "Stacks[0].Outputs[?OutputKey=='MWAAWebserverUrl'].OutputValue" \
    --output text \
    --region "$AWS_REGION" 2>/dev/null || echo "Pending...")
echo "MWAA Web URL: $MWAA_URL"

# Save configuration to file
CONFIG_FILE="../config/aws-infrastructure.env"
echo ""
echo -e "${YELLOW}Saving configuration to $CONFIG_FILE${NC}"

cat > "$CONFIG_FILE" << EOF
# AWS Infrastructure Configuration
# Generated on $(date)

# Project Configuration
export PROJECT_NAME="$PROJECT_NAME"
export ENVIRONMENT="$ENVIRONMENT"
export AWS_REGION="$AWS_REGION"

# VPC Configuration
export VPC_ID="$VPC_ID"
export PRIVATE_SUBNET_1="$PRIVATE_SUBNET_1"
export PRIVATE_SUBNET_2="$PRIVATE_SUBNET_2"
export EMR_MASTER_SECURITY_GROUP="$EMR_MASTER_SG"
export EMR_SLAVE_SECURITY_GROUP="$EMR_SLAVE_SG"
export EMR_SUBNET_ID="$PRIVATE_SUBNET_1"

# S3 Configuration
export DATA_BUCKET_NAME="$DATA_BUCKET"
export MWAA_BUCKET_NAME="$MWAA_BUCKET"
export EMR_LOGS_BUCKET_NAME="$EMR_LOGS_BUCKET"
export PROCESSED_DATA_BUCKET_NAME="$PROCESSED_BUCKET"
export INPUT_PREFIX="raw-data/"
export OUTPUT_PREFIX="processed-data/"

# IAM Configuration
export EMR_SERVICE_ROLE="$EMR_SERVICE_ROLE"
export EMR_INSTANCE_PROFILE="$EMR_INSTANCE_PROFILE"

# MWAA Configuration
export MWAA_ENVIRONMENT_NAME="$MWAA_ENV_NAME"
export MWAA_WEBSERVER_URL="$MWAA_URL"
EOF

echo -e "${GREEN}✓ Configuration saved${NC}"
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${GREEN}========================================${NC}"
echo "1. Source the configuration: source $CONFIG_FILE"
echo "2. Upload DAGs to S3: ./scripts/upload-to-mwaa.sh"
echo "3. Access MWAA: $MWAA_URL"
echo ""
echo -e "${YELLOW}Note: MWAA environment may still be initializing (20-30 min)${NC}"
echo -e "${YELLOW}Check status: aws mwaa get-environment --name $MWAA_ENV_NAME --region $AWS_REGION${NC}"
