#!/bin/bash

# Data Warehousing CloudFormation Cleanup Script
# This script safely deletes the CloudFormation stacks

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}
STACK_PREFIX="data-warehouse"

# Functions
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

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    error "Environment must be dev, staging, or prod"
    exit 1
fi

# Confirm deletion
confirm_deletion() {
    local stack_name="${STACK_PREFIX}-${ENVIRONMENT}"
    
    echo -e "${YELLOW}"
    echo "=========================================="
    echo "⚠  WARNING: You are about to delete:"
    echo "    Stack: ${stack_name}"
    echo "    Region: ${REGION}"
    echo ""
    echo "This action cannot be undone!"
    echo "=========================================="
    echo -e "${NC}"
    
    read -p "Type 'DELETE' to confirm: " confirmation
    
    if [ "$confirmation" != "DELETE" ]; then
        error "Deletion cancelled"
        exit 0
    fi
}

# Delete stack
delete_stack() {
    local stack_name="${STACK_PREFIX}-${ENVIRONMENT}"
    
    log "Deleting stack: ${stack_name}..."
    
    aws cloudformation delete-stack \
        --stack-name "$stack_name" \
        --region "$REGION"
    
    success "Stack deletion initiated"
}

# Wait for deletion
wait_for_deletion() {
    local stack_name="${STACK_PREFIX}-${ENVIRONMENT}"
    
    log "Waiting for stack deletion to complete..."
    log "This may take several minutes..."
    
    aws cloudformation wait stack-delete-complete \
        --stack-name "$stack_name" \
        --region "$REGION" || true
    
    success "Stack deletion completed"
}

# Check if resources still exist
check_remaining_resources() {
    local stack_name="${STACK_PREFIX}-${ENVIRONMENT}"
    
    log "Checking for remaining resources..."
    
    # Try to describe stack
    if aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --region "$REGION" > /dev/null 2>&1; then
        warning "Stack still exists. Check AWS Console for details."
        return 1
    else
        success "Stack has been successfully deleted"
        return 0
    fi
}

# Main execution
main() {
    log "=========================================="
    log "Data Warehousing Stack Cleanup"
    log "=========================================="
    log "Environment: ${ENVIRONMENT}"
    log "Region: ${REGION}"
    
    confirm_deletion
    delete_stack
    wait_for_deletion
    check_remaining_resources
    
    log "=========================================="
    success "Cleanup completed!"
    log "=========================================="
}

# Run main
main
