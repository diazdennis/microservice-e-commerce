#!/bin/bash
# AWS CloudFormation Deployment Script for Linux/Mac
# This script helps deploy the e-commerce microservices to AWS

set -e

# Default values
STACK_NAME="${STACK_NAME:-ecommerce-app}"
REGION="${REGION:-ap-southeast-2}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}[*] Starting AWS CloudFormation Deployment...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}[X] AWS CLI not found. Please install AWS CLI first.${NC}"
    echo -e "${YELLOW}    Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] AWS CLI found: $(aws --version)${NC}"

# Check required parameters
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}[X] Usage: $0 <KeyName> <GitHubRepoUrl> [StackName] [Region]${NC}"
    echo -e "${YELLOW}    Example: $0 ecommerce-key https://github.com/username/e-commerce-microservices.git${NC}"
    exit 1
fi

KEY_NAME="$1"
GITHUB_REPO_URL="$2"
[ -n "$3" ] && STACK_NAME="$3"
[ -n "$4" ] && REGION="$4"

# Fetch latest AMI ID
echo -e "${CYAN}[*] Fetching latest Amazon Linux 2023 AMI ID...${NC}"
AMI_ID=""

# Try SSM Parameter Store first
SSM_OUTPUT=$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 --region "$REGION" --query 'Parameter.Value' --output text 2>&1)
if [ $? -eq 0 ] && [ -n "$SSM_OUTPUT" ] && [[ ! "$SSM_OUTPUT" =~ "AccessDenied" ]] && [[ ! "$SSM_OUTPUT" =~ "error" ]] && [[ ! "$SSM_OUTPUT" =~ "Error" ]]; then
    AMI_ID=$(echo "$SSM_OUTPUT" | tr -d '[:space:]')
    echo -e "${GREEN}[OK] Found AMI ID via SSM: $AMI_ID${NC}"
else
    echo -e "${YELLOW}[!] SSM access denied or unavailable. Trying alternative method...${NC}"
    
    # Try EC2 describe-images as alternative (uses ec2:DescribeImages permission)
    EC2_OUTPUT=$(aws ec2 describe-images --region "$REGION" --owners amazon --filters "Name=name,Values=al2023-ami-*-kernel-6.1-x86_64" "Name=state,Values=available" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text 2>&1)
    if [ $? -eq 0 ] && [ -n "$EC2_OUTPUT" ] && [[ ! "$EC2_OUTPUT" =~ "AccessDenied" ]] && [[ ! "$EC2_OUTPUT" =~ "error" ]] && [[ ! "$EC2_OUTPUT" =~ "Error" ]]; then
        AMI_ID=$(echo "$EC2_OUTPUT" | tr -d '[:space:]')
        echo -e "${GREEN}[OK] Found AMI ID via EC2: $AMI_ID${NC}"
    else
        echo -e "${YELLOW}[!] Could not automatically fetch AMI ID (insufficient permissions).${NC}"
        echo -e "${YELLOW}    You'll need to provide the AMI ID manually.${NC}"
    fi
fi

# If AMI ID not found, prompt for it
if [ -z "$AMI_ID" ]; then
    echo ""
    echo -e "${CYAN}To find the latest Amazon Linux 2023 AMI ID:${NC}"
    echo -e "  ${NC}1. Go to EC2 Console > Launch Instance > Amazon Linux 2023"
    echo -e "  ${NC}2. Or use AWS Console with a user that has SSM permissions"
    echo -e "  ${NC}3. Or ask your AWS administrator for the AMI ID"
    echo ""
    read -p "Enter Amazon Linux 2023 AMI ID (required): " AMI_ID
    if [ -z "$AMI_ID" ]; then
        echo -e "${RED}[X] AMI ID is required. Deployment cancelled.${NC}"
        exit 1
    fi
fi

# Generate App Key
echo -e "${CYAN}[*] Generating application key...${NC}"
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}[X] OpenSSL not found. Please install OpenSSL.${NC}"
    exit 1
fi

APP_KEY=$(openssl rand -base64 32)
if [ -z "$APP_KEY" ]; then
    echo -e "${RED}[X] Failed to generate app key.${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] App key generated${NC}"

# Prompt for passwords
echo -e "${CYAN}[*] Please enter database passwords:${NC}"
read -sp "MySQL Root Password (min 8 characters): " MYSQL_ROOT_PASSWORD
echo
read -sp "MySQL App User Password (min 8 characters): " MYSQL_APP_PASSWORD
echo

# Prompt for SES credentials (optional)
echo -e "${CYAN}[*] AWS SES Configuration (optional - can use placeholder):${NC}"
read -p "SES SMTP Username (or 'placeholder'): " SES_USERNAME
read -sp "SES SMTP Password (or 'placeholder'): " SES_PASSWORD
echo

if [ -z "$SES_USERNAME" ]; then
    SES_USERNAME="placeholder"
fi
if [ -z "$SES_PASSWORD" ]; then
    SES_PASSWORD="placeholder"
fi

# Deploy with CloudFormation
echo -e "${CYAN}[*] Deploying stack '$STACK_NAME' to region '$REGION'...${NC}"
echo -e "${YELLOW}    This will take 5-10 minutes...${NC}"

aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body file://infrastructure/cloudformation.yml \
    --parameters \
        ParameterKey=KeyName,ParameterValue="$KEY_NAME" \
        ParameterKey=LatestAmiId,ParameterValue="$AMI_ID" \
        ParameterKey=GitHubRepoUrl,ParameterValue="$GITHUB_REPO_URL" \
        ParameterKey=AppKey,ParameterValue="$APP_KEY" \
        ParameterKey=MySQLRootPassword,ParameterValue="$MYSQL_ROOT_PASSWORD" \
        ParameterKey=MySQLAppPassword,ParameterValue="$MYSQL_APP_PASSWORD" \
        ParameterKey=SESUsername,ParameterValue="$SES_USERNAME" \
        ParameterKey=SESPassword,ParameterValue="$SES_PASSWORD" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] Stack creation initiated!${NC}"
    echo -e "${YELLOW}[*] Waiting for stack to be created (this may take 5-10 minutes)...${NC}"
    
    # Wait for stack creation
    aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION"
    
    echo -e "${GREEN}[OK] Stack created successfully!${NC}"
    
    # Get outputs
    echo -e "${CYAN}[*] Retrieving deployment information...${NC}"
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}DEPLOYMENT SUCCESSFUL!${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    # Get and display outputs
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query "Stacks[0].Outputs" \
        --output table
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}Your application is now live!${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
else
    echo -e "${RED}[X] Deployment failed!${NC}"
    echo -e "${YELLOW}[*] To check stack status:${NC}"
    echo -e "    aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION"
    echo -e "${YELLOW}[*] To view stack events:${NC}"
    echo -e "    aws cloudformation describe-stack-events --stack-name $STACK_NAME --region $REGION"
    exit 1
fi

