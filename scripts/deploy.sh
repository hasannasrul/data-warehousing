#!/bin/bash

# Data Warehousing CloudFormation Deployment Script
# This script deploys the complete data warehousing infrastructure

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}
TEMPLATE_DIR="./cloudformation"
STACK_PREFIX="data-warehouse"

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}Error: Environment must be dev, staging, or prod${NC}"
    exit 1
fi

# Function to print colored output
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    success "AWS CLI is installed"
}

# Function to validate AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity --region $REGION > /dev/null 2>&1; then
        error "AWS credentials are not configured or invalid"
        exit 1
    fi
    success "AWS credentials are valid"
}

# Function to upload templates to S3
upload_templates() {
    log "Uploading CloudFormation templates to S3..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    TEMPLATES_BUCKET="cf-templates-${ENVIRONMENT}-${ACCOUNT_ID}"
    
    # Create bucket if it doesn't exist
    if ! aws s3 ls "s3://${TEMPLATES_BUCKET}" --region $REGION 2>/dev/null; then
        log "Creating S3 bucket for templates: ${TEMPLATES_BUCKET}"
        aws s3 mb "s3://${TEMPLATES_BUCKET}" --region $REGION
        success "Template bucket created"
    else
        success "Template bucket already exists"
    fi
    
    # Upload templates
    for template in ${TEMPLATE_DIR}/*.yaml; do
        if [ -f "$template" ]; then
            filename=$(basename "$template")
            log "Uploading ${filename}..."
            aws s3 cp "$template" "s3://${TEMPLATES_BUCKET}/" --region $REGION
            success "Uploaded ${filename}"
        fi
    done
}

# Function to get RDS password from user
get_rds_password() {
    read -sp "Enter RDS master password (min 8 characters): " RDS_PASSWORD
    echo
    
    if [ ${#RDS_PASSWORD} -lt 8 ]; then
        error "Password must be at least 8 characters"
        exit 1
    fi
    
    read -sp "Confirm RDS password: " RDS_PASSWORD_CONFIRM
    echo
    
    if [ "$RDS_PASSWORD" != "$RDS_PASSWORD_CONFIRM" ]; then
        error "Passwords do not match"
        exit 1
    fi
}

# Function to get Redshift password from user
get_redshift_password() {
    read -sp "Enter Redshift master password (min 8 characters): " REDSHIFT_PASSWORD
    echo
    
    if [ ${#REDSHIFT_PASSWORD} -lt 8 ]; then
        error "Password must be at least 8 characters"
        exit 1
    fi
    
    read -sp "Confirm Redshift password: " REDSHIFT_PASSWORD_CONFIRM
    echo
    
    if [ "$REDSHIFT_PASSWORD" != "$REDSHIFT_PASSWORD_CONFIRM" ]; then
        error "Passwords do not match"
        exit 1
    fi
}

# Function to deploy CloudFormation stack
deploy_stack() {
    local stack_name="${STACK_PREFIX}-${ENVIRONMENT}"
    local template="${TEMPLATE_DIR}/00-master-stack.yaml"
    
    log "Deploying CloudFormation stack: ${stack_name}..."
    
    get_rds_password
    get_redshift_password
    
    aws cloudformation deploy \
        --template-file "$template" \
        --stack-name "$stack_name" \
        --region "$REGION" \
        --parameter-overrides \
            Environment="$ENVIRONMENT" \
            DBPassword="$RDS_PASSWORD" \
            RedshiftMasterPassword="$REDSHIFT_PASSWORD" \
        --capabilities CAPABILITY_NAMED_IAM \
        --no-fail-on-empty-changeset
    
    success "Stack deployment completed"
}

# Function to wait for stack completion
wait_for_stack() {
    local stack_name="${STACK_PREFIX}-${ENVIRONMENT}"
    
    log "Waiting for stack to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name "$stack_name" \
        --region "$REGION" || true
}

# Function to display stack outputs
show_outputs() {
    local stack_name="${STACK_PREFIX}-${ENVIRONMENT}"
    
    log "Stack Outputs:"
    aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
}

# Function to validate templates
validate_templates() {
    log "Validating CloudFormation templates..."
    
    for template in ${TEMPLATE_DIR}/*.yaml; do
        if [ -f "$template" ]; then
            filename=$(basename "$template")
            if aws cloudformation validate-template \
                --template-body "file://$template" \
                --region "$REGION" > /dev/null 2>&1; then
                success "Template ${filename} is valid"
            else
                error "Template ${filename} validation failed"
                exit 1
            fi
        fi
    done
}

# Main execution
main() {
    log "=========================================="
    log "Data Warehousing Infrastructure Deployment"
    log "=========================================="
    log "Environment: ${ENVIRONMENT}"
    log "Region: ${REGION}"
    
    check_aws_cli
    check_aws_credentials
    validate_templates
    upload_templates
    deploy_stack
    wait_for_stack
    show_outputs
    
    log "=========================================="
    success "Deployment completed successfully!"
    log "=========================================="
}

# Run main function
main
