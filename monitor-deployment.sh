#!/bin/bash
# CloudFormation Stack Deployment Monitor
# Monitors stack creation progress and shows errors

STACK_NAME="${1:-ecommerce}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}CloudFormation Deployment Monitor${NC}"
echo -e "${CYAN}Stack: $STACK_NAME${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if stack exists
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME \
  --query 'Stacks[0].StackStatus' \
  --output text 2>/dev/null)

if [ $? -ne 0 ]; then
  echo -e "${RED}Error: Stack '$STACK_NAME' not found!${NC}"
  echo "Available stacks:"
  aws cloudformation list-stacks \
    --stack-status-filter CREATE_IN_PROGRESS CREATE_COMPLETE CREATE_FAILED ROLLBACK_IN_PROGRESS ROLLBACK_COMPLETE \
    --query 'StackSummaries[*].[StackName,StackStatus]' \
    --output table
  exit 1
fi

# Stack Status
echo -e "${CYAN}=== Stack Status ===${NC}"
if [ "$STACK_STATUS" = "CREATE_COMPLETE" ]; then
  echo -e "${GREEN}Status: $STACK_STATUS${NC}"
elif [ "$STACK_STATUS" = "CREATE_IN_PROGRESS" ]; then
  echo -e "${YELLOW}Status: $STACK_STATUS${NC}"
elif [[ "$STACK_STATUS" == *"FAILED"* ]] || [[ "$STACK_STATUS" == *"ROLLBACK"* ]]; then
  echo -e "${RED}Status: $STACK_STATUS${NC}"
else
  echo -e "Status: $STACK_STATUS"
fi
echo ""

# Recent Events
echo -e "${CYAN}=== Recent Events (Last 10) ===${NC}"
aws cloudformation describe-stack-events --stack-name $STACK_NAME \
  --query 'StackEvents[0:10].[Timestamp,ResourceType,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table
echo ""

# Failed Resources
echo -e "${CYAN}=== Failed Resources ===${NC}"
FAILED=$(aws cloudformation describe-stack-events --stack-name $STACK_NAME \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table)

if [ -z "$FAILED" ] || [ "$FAILED" = "None" ]; then
  echo -e "${GREEN}No failed resources${NC}"
else
  echo -e "${RED}$FAILED${NC}"
fi
echo ""

# EC2 Instance Status
echo -e "${CYAN}=== EC2 Instance Status ===${NC}"
INSTANCE_ID=$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME \
  --logical-resource-id EC2Instance \
  --query 'StackResources[0].PhysicalResourceId' \
  --output text 2>/dev/null)

if [ ! -z "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then
  INSTANCE_INFO=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress]' \
    --output table 2>/dev/null)
  
  if [ $? -eq 0 ]; then
    echo "$INSTANCE_INFO"
    
    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text 2>/dev/null)
    
    if [ ! -z "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
      echo ""
      echo -e "${CYAN}=== Application Status ===${NC}"
      echo "Testing: http://$PUBLIC_IP"
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://$PUBLIC_IP 2>/dev/null)
      
      if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Website is responding (HTTP $HTTP_CODE)${NC}"
      elif [ "$HTTP_CODE" = "000" ]; then
        echo -e "${YELLOW}⚠ Website not responding yet (still deploying...)${NC}"
      else
        echo -e "${YELLOW}⚠ Website returned HTTP $HTTP_CODE${NC}"
      fi
      
      echo ""
      echo -e "${CYAN}=== SSH Command ===${NC}"
      echo "ssh -i your-key-pair.pem ec2-user@$PUBLIC_IP"
      echo ""
      echo -e "${CYAN}=== Check UserData Logs ===${NC}"
      echo "ssh -i your-key-pair.pem ec2-user@$PUBLIC_IP 'tail -50 /var/log/cloud-init-output.log'"
    fi
  else
    echo "EC2 instance created but details not available yet..."
  fi
else
  echo "EC2 instance not created yet..."
fi

echo ""
echo -e "${CYAN}=== Stack Outputs ===${NC}"
OUTPUTS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs' \
  --output table 2>/dev/null)

if [ ! -z "$OUTPUTS" ] && [ "$OUTPUTS" != "None" ]; then
  echo "$OUTPUTS"
else
  echo "No outputs available yet (stack still creating...)"
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo "Run this script again to refresh: ./monitor-deployment.sh $STACK_NAME"
echo -e "${CYAN}========================================${NC}"

