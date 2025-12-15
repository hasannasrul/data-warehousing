#!/bin/bash

# Data Warehousing Project Validation Script
# Checks if all project files and configurations are in place

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Functions
check_file() {
    local file=$1
    local description=$2
    
    ((TOTAL_CHECKS++))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASSED_CHECKS++))
    else
        echo -e "${RED}✗${NC} $description (Missing: $file)"
        ((FAILED_CHECKS++))
    fi
}

check_directory() {
    local dir=$1
    local description=$2
    
    ((TOTAL_CHECKS++))
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASSED_CHECKS++))
    else
        echo -e "${RED}✗${NC} $description (Missing: $dir)"
        ((FAILED_CHECKS++))
    fi
}

check_executable() {
    local file=$1
    local description=$2
    
    ((TOTAL_CHECKS++))
    
    if [ -x "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASSED_CHECKS++))
    else
        echo -e "${RED}✗${NC} $description (Not executable: $file)"
        ((FAILED_CHECKS++))
    fi
}

check_aws_cli() {
    ((TOTAL_CHECKS++))
    
    if command -v aws &> /dev/null; then
        echo -e "${GREEN}✓${NC} AWS CLI installed"
        ((PASSED_CHECKS++))
    else
        echo -e "${YELLOW}⚠${NC} AWS CLI not installed (optional, but recommended)"
        ((FAILED_CHECKS++))
    fi
}

# Header
echo -e "${BLUE}"
echo "=========================================="
echo "Data Warehousing Project Validation"
echo "=========================================="
echo -e "${NC}"

# Get project root (parent of scripts directory)
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo -e "\n${BLUE}[1] Checking Project Structure${NC}"
check_directory "$PROJECT_ROOT/cloudformation" "CloudFormation templates directory"
check_directory "$PROJECT_ROOT/scripts" "Scripts directory"
check_directory "$PROJECT_ROOT/glue" "Glue jobs directory"
check_directory "$PROJECT_ROOT/data" "Data directory"

echo -e "\n${BLUE}[2] Checking CloudFormation Templates${NC}"
check_file "$PROJECT_ROOT/cloudformation/00-master-stack.yaml" "Master stack template"
check_file "$PROJECT_ROOT/cloudformation/01-s3-bucket.yaml" "S3 bucket template"
check_file "$PROJECT_ROOT/cloudformation/02-rds-database.yaml" "RDS template"
check_file "$PROJECT_ROOT/cloudformation/03-glue-jobs.yaml" "Glue jobs template"
check_file "$PROJECT_ROOT/cloudformation/04-redshift-cluster.yaml" "Redshift template"

echo -e "\n${BLUE}[3] Checking Deployment Scripts${NC}"
check_executable "$PROJECT_ROOT/scripts/deploy.sh" "Deploy script"
check_executable "$PROJECT_ROOT/scripts/cleanup.sh" "Cleanup script"
check_file "$PROJECT_ROOT/scripts/parameters.json" "Parameters file"
check_file "$PROJECT_ROOT/scripts/rds-init.sql" "RDS initialization script"
check_file "$PROJECT_ROOT/scripts/redshift-init.sql" "Redshift initialization script"

echo -e "\n${BLUE}[4] Checking Glue Job Scripts${NC}"
check_file "$PROJECT_ROOT/glue/rds-to-s3.py" "RDS to S3 job"
check_file "$PROJECT_ROOT/glue/s3-processing.py" "S3 processing job"
check_file "$PROJECT_ROOT/glue/s3-to-redshift.py" "S3 to Redshift job"

echo -e "\n${BLUE}[5] Checking Documentation${NC}"
check_file "$PROJECT_ROOT/README.md" "README documentation"
check_file "$PROJECT_ROOT/QUICK_REFERENCE.md" "Quick reference guide"
check_file "$PROJECT_ROOT/PROJECT_SUMMARY.md" "Project summary"

echo -e "\n${BLUE}[6] Checking Configuration Files${NC}"
check_file "$PROJECT_ROOT/config.env" "Environment configuration"

echo -e "\n${BLUE}[7] Checking System Requirements${NC}"
check_aws_cli

# Summary
echo -e "\n${BLUE}=========================================="
echo "Validation Summary"
echo "==========================================${NC}"
echo "Total Checks: $TOTAL_CHECKS"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
else
    echo -e "${GREEN}Failed: $FAILED_CHECKS${NC}"
fi

# Recommendations
echo -e "\n${BLUE}[Recommendations]${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Project is ready for deployment.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Configure AWS credentials: aws configure"
    echo "2. Review parameters in config.env"
    echo "3. Deploy: ./scripts/deploy.sh dev us-east-1"
else
    echo -e "${RED}✗ Some checks failed. Please fix the issues above.${NC}"
    echo ""
    echo "For help:"
    echo "• Check README.md for detailed documentation"
    echo "• Review PROJECT_SUMMARY.md for project overview"
    echo "• See QUICK_REFERENCE.md for common commands"
fi

echo ""
echo "Documentation:"
echo "• Full Guide: $PROJECT_ROOT/README.md"
echo "• Quick Ref: $PROJECT_ROOT/QUICK_REFERENCE.md"
echo "• Summary: $PROJECT_ROOT/PROJECT_SUMMARY.md"
echo ""

# Exit code
if [ $FAILED_CHECKS -eq 0 ]; then
    exit 0
else
    exit 1
fi
