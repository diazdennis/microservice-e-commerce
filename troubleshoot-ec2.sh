#!/bin/bash
# Troubleshooting Script for EC2 Deployment
# This script helps diagnose issues with the deployed application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}[*] Starting EC2 Deployment Troubleshooting...${NC}"

# Check required parameters
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}[X] Usage: $0 <PEM_FILE_PATH> <EC2_PUBLIC_IP> [EC2_USER]${NC}"
    echo -e "${YELLOW}    Example: $0 ~/.ssh/dennis-ec2.pem 54.206.80.148${NC}"
    exit 1
fi

PEM_FILE="$1"
EC2_IP="$2"
EC2_USER="${3:-ec2-user}"

# Validate PEM file exists
if [ ! -f "$PEM_FILE" ]; then
    echo -e "${RED}[X] PEM file not found: $PEM_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Connecting to EC2 instance: $EC2_USER@$EC2_IP${NC}"

# Create troubleshooting script
TROUBLESHOOT_SCRIPT=$(cat <<'TROUBLESHOOT_EOF'
#!/bin/bash

echo "=========================================="
echo "EC2 DEPLOYMENT TROUBLESHOOTING"
echo "=========================================="
echo ""

# Check Docker status
echo "[*] Checking Docker status..."
if command -v docker &> /dev/null; then
    echo "[OK] Docker is installed"
    sudo systemctl status docker --no-pager | head -5 || true
else
    echo "[X] Docker is NOT installed"
fi
echo ""

# Check Docker Compose status
echo "[*] Checking Docker Compose status..."
if command -v docker-compose &> /dev/null; then
    echo "[OK] Docker Compose is installed: $(docker-compose --version)"
else
    echo "[X] Docker Compose is NOT installed"
fi
echo ""

# Check if containers are running
echo "[*] Checking Docker containers..."
cd ~/microservice-e-commerce 2>/dev/null || cd ~/e-commerce-microservices 2>/dev/null || {
    echo "[!] Project directory not found in home directory"
    echo "    Looking for project..."
    find ~ -name "docker-compose.yml" -type f 2>/dev/null | head -1 | while read dir; do
        echo "    Found at: $(dirname $dir)"
        cd "$(dirname $dir)"
    done
}

if [ -f "docker-compose.yml" ]; then
    echo "[OK] Found docker-compose.yml"
    echo ""
    echo "[*] Container status:"
    docker-compose ps || docker ps
    echo ""
    
    echo "[*] Container logs (last 20 lines of each):"
    echo "--- Frontend (Nginx) ---"
    docker-compose logs --tail=20 frontend 2>/dev/null || echo "Frontend container not found"
    echo ""
    echo "--- Catalog Service ---"
    docker-compose logs --tail=20 catalog 2>/dev/null || echo "Catalog container not found"
    echo ""
    echo "--- Checkout Service ---"
    docker-compose logs --tail=20 checkout 2>/dev/null || echo "Checkout container not found"
    echo ""
    echo "--- Email Service ---"
    docker-compose logs --tail=20 email 2>/dev/null || echo "Email container not found"
    echo ""
    
    echo "[*] Checking if port 80 is listening:"
    sudo netstat -tlnp | grep :80 || sudo ss -tlnp | grep :80 || echo "Port 80 is not listening"
    echo ""
    
    echo "[*] Checking Nginx configuration:"
    docker-compose exec -T frontend cat /etc/nginx/conf.d/default.conf 2>/dev/null || echo "Cannot access Nginx config"
    echo ""
else
    echo "[X] docker-compose.yml not found in current directory"
    echo "    Current directory: $(pwd)"
fi

# Check if services are accessible internally
echo "[*] Testing internal service connectivity:"
echo "--- Testing Catalog Service ---"
curl -s http://localhost:8001/api/products 2>/dev/null | head -5 || echo "Catalog service not responding"
echo ""
echo "--- Testing Checkout Service ---"
curl -s http://localhost:8002/api/orders 2>/dev/null | head -5 || echo "Checkout service not responding"
echo ""

# Check security group (if we can)
echo "[*] Checking network configuration:"
echo "Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'N/A')"
echo "Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo 'N/A')"
echo ""

# Check if port 80 is accessible from outside
echo "[*] Checking firewall/iptables:"
sudo iptables -L -n | grep 80 || echo "No iptables rules found for port 80"
echo ""

# Check .env file
echo "[*] Checking .env file:"
if [ -f ".env" ]; then
    echo "[OK] .env file exists"
    echo "    Key variables present:"
    grep -E "APP_KEY|MYSQL|AWS_REGION" .env | sed 's/=.*/=***/' || true
else
    echo "[X] .env file NOT found"
fi
echo ""

# Check frontend build
echo "[*] Checking frontend build:"
if [ -d "frontend/dist" ]; then
    echo "[OK] Frontend dist directory exists"
    ls -la frontend/dist/ | head -10
else
    echo "[X] Frontend dist directory NOT found"
fi
echo ""

echo "=========================================="
echo "TROUBLESHOOTING COMPLETE"
echo "=========================================="
TROUBLESHOOT_EOF
)

# Write troubleshoot script to temporary file
TEMP_SCRIPT="/tmp/troubleshoot-ec2-$$.sh"
echo "$TROUBLESHOOT_SCRIPT" > "$TEMP_SCRIPT"
chmod +x "$TEMP_SCRIPT"

# Copy script to EC2 and execute
echo -e "${CYAN}[*] Running diagnostics on EC2 instance...${NC}"
scp -i "$PEM_FILE" -o StrictHostKeyChecking=no "$TEMP_SCRIPT" "$EC2_USER@$EC2_IP:/tmp/troubleshoot.sh"
ssh -i "$PEM_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "bash /tmp/troubleshoot.sh"

# Clean up
rm -f "$TEMP_SCRIPT"

echo ""
echo -e "${CYAN}[*] Checking AWS Security Group configuration...${NC}"
echo -e "${YELLOW}    Run this command to check your security group:${NC}"
echo "    aws ec2 describe-instances --instance-ids i-0eae6c8286ed501b7 --region ap-southeast-2 --query 'Reservations[0].Instances[0].SecurityGroups[*].[GroupId,GroupName]' --output table"
echo ""
echo -e "${YELLOW}    Then check security group rules:${NC}"
echo "    aws ec2 describe-security-groups --group-ids <GROUP_ID> --region ap-southeast-2 --query 'SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp]' --output table"

