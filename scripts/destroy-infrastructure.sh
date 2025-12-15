#!/bin/bash
# Delete all CloudFormation stacks in reverse order

set -e

PROJECT_NAME="big-data-processing"
ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}DESTROY Infrastructure${NC}"
echo -e "${RED}========================================${NC}"
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "AWS Region: $AWS_REGION"
echo ""
echo -e "${RED}WARNING: This will delete all resources!${NC}"
read -p "Are you sure? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

# Function to wait for stack deletion
wait_for_deletion() {
    local stack_name=$1
    echo -e "${YELLOW}Waiting for $stack_name to be deleted...${NC}"
    aws cloudformation wait stack-delete-complete \
        --stack-name "$stack_name" \
        --region "$AWS_REGION" 2>/dev/null || true
}

# Function to delete stack
delete_stack() {
    local stack_name=$1
    
    if aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${YELLOW}Deleting stack: $stack_name${NC}"
        aws cloudformation delete-stack \
            --stack-name "$stack_name" \
            --region "$AWS_REGION"
        wait_for_deletion "$stack_name"
        echo -e "${GREEN}✓ Stack $stack_name deleted${NC}\n"
    else
        echo "Stack $stack_name does not exist, skipping..."
    fi
}

# Get bucket names before deletion
DATA_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-s3" \
    --query "Stacks[0].Outputs[?OutputKey=='DataBucketName'].OutputValue" \
    --output text \
    --region "$AWS_REGION" 2>/dev/null || echo "")

MWAA_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-s3" \
    --query "Stacks[0].Outputs[?OutputKey=='MWAABucketName'].OutputValue" \
    --output text \
    --region "$AWS_REGION" 2>/dev/null || echo "")

EMR_LOGS_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-s3" \
    --query "Stacks[0].Outputs[?OutputKey=='EMRLogsBucketName'].OutputValue" \
    --output text \
    --region "$AWS_REGION" 2>/dev/null || echo "")

ATHENA_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-s3" \
    --query "Stacks[0].Outputs[?OutputKey=='AthenaResultsBucketName'].OutputValue" \
    --output text \
    --region "$AWS_REGION" 2>/dev/null || echo "")

# Empty S3 buckets before deletion
if [ -n "$DATA_BUCKET" ]; then
    echo -e "${YELLOW}Emptying bucket: $DATA_BUCKET${NC}"
    aws s3 rm "s3://${DATA_BUCKET}/" --recursive --region "$AWS_REGION" 2>/dev/null || true
fi

if [ -n "$MWAA_BUCKET" ]; then
    echo -e "${YELLOW}Emptying bucket: $MWAA_BUCKET${NC}"
    aws s3 rm "s3://${MWAA_BUCKET}/" --recursive --region "$AWS_REGION" 2>/dev/null || true
fi

if [ -n "$EMR_LOGS_BUCKET" ]; then
    echo -e "${YELLOW}Emptying bucket: $EMR_LOGS_BUCKET${NC}"
    aws s3 rm "s3://${EMR_LOGS_BUCKET}/" --recursive --region "$AWS_REGION" 2>/dev/null || true
fi

if [ -n "$ATHENA_BUCKET" ]; then
    echo -e "${YELLOW}Emptying bucket: $ATHENA_BUCKET${NC}"
    aws s3 rm "s3://${ATHENA_BUCKET}/" --recursive --region "$AWS_REGION" 2>/dev/null || true
fi

# Delete stacks in reverse order
echo ""
echo "Deleting stacks in reverse order..."
echo ""

# Step 1: Delete MWAA (takes longest)
delete_stack "${PROJECT_NAME}-${ENVIRONMENT}-mwaa"

# Step 2: Delete IAM roles
delete_stack "${PROJECT_NAME}-${ENVIRONMENT}-iam"

# Step 3: Delete S3 buckets
delete_stack "${PROJECT_NAME}-${ENVIRONMENT}-s3"

# Step 4: Delete VPC
delete_stack "${PROJECT_NAME}-${ENVIRONMENT}-vpc"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All stacks deleted successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
