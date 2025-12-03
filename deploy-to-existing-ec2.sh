#!/bin/bash
# Deployment Script for Existing EC2 Instance
# This script deploys the e-commerce microservices to an existing EC2 instance via SSH

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}[*] Starting deployment to existing EC2 instance...${NC}"

# Check required parameters
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo -e "${RED}[X] Usage: $0 <PEM_FILE_PATH> <EC2_PUBLIC_IP> <GITHUB_REPO_URL>${NC}"
    echo -e "${YELLOW}    Example: $0 ~/.ssh/dennis-ec2.pem 54.206.80.148 https://github.com/diazdennis/microservice-e-commerce.git${NC}"
    exit 1
fi

PEM_FILE="$1"
EC2_IP="$2"
GITHUB_REPO_URL="$3"
EC2_USER="${4:-ec2-user}"  # Default to ec2-user, can be ubuntu for Ubuntu instances

# Validate PEM file exists
if [ ! -f "$PEM_FILE" ]; then
    echo -e "${RED}[X] PEM file not found: $PEM_FILE${NC}"
    exit 1
fi

# Set correct permissions for PEM file
chmod 400 "$PEM_FILE" 2>/dev/null || true

echo -e "${GREEN}[OK] Connecting to EC2 instance: $EC2_USER@$EC2_IP${NC}"

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
read -p "AWS Region for SES [us-east-1]: " AWS_REGION
AWS_REGION="${AWS_REGION:-us-east-1}"
read -p "SES SMTP Username (or 'placeholder'): " SES_USERNAME
read -sp "SES SMTP Password (or 'placeholder'): " SES_PASSWORD
echo
read -p "Mail From Address [noreply@example.com]: " MAIL_FROM_ADDRESS
MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-noreply@example.com}"
read -p "Mail From Name [E-Commerce Store]: " MAIL_FROM_NAME
MAIL_FROM_NAME="${MAIL_FROM_NAME:-E-Commerce Store}"

if [ -z "$SES_USERNAME" ]; then
    SES_USERNAME="placeholder"
fi
if [ -z "$SES_PASSWORD" ]; then
    SES_PASSWORD="placeholder"
fi

echo -e "${CYAN}[*] Deploying to EC2 instance...${NC}"

# Create deployment script to run on EC2
DEPLOY_SCRIPT=$(cat <<'DEPLOY_EOF'
#!/bin/bash
set -e

echo "[*] Starting deployment on EC2 instance..."

# Detect OS and package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "[X] Cannot detect OS"
    exit 1
fi

# Install dependencies based on OS
if [ "$OS" == "amzn" ] || [ "$OS" == "rhel" ] || [ "$OS" == "fedora" ]; then
    echo "[*] Detected Amazon Linux/RHEL/Fedora"
    
    # Update system
    sudo dnf update -y || sudo yum update -y
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo "[*] Installing Docker..."
        sudo dnf install -y docker git || sudo yum install -y docker git
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
    else
        echo "[OK] Docker already installed"
    fi
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "[*] Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "[OK] Docker Compose already installed"
    fi
    
    # Install Node.js and npm
    if ! command -v node &> /dev/null; then
        echo "[*] Installing Node.js..."
        sudo dnf install -y nodejs npm || sudo yum install -y nodejs npm
    else
        echo "[OK] Node.js already installed"
    fi
    
elif [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    echo "[*] Detected Ubuntu/Debian"
    
    # Update system
    sudo apt-get update -y
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo "[*] Installing Docker..."
        sudo apt-get install -y docker.io git
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
    else
        echo "[OK] Docker already installed"
    fi
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "[*] Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "[OK] Docker Compose already installed"
    fi
    
    # Install Node.js and npm
    if ! command -v node &> /dev/null; then
        echo "[*] Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        echo "[OK] Node.js already installed"
    fi
else
    echo "[X] Unsupported OS: $OS"
    exit 1
fi

# Navigate to home directory
cd ~

# Clone or update repository
if [ -d "microservice-e-commerce" ]; then
    echo "[*] Repository exists, pulling latest changes..."
    cd microservice-e-commerce
    git pull origin main || git pull origin master
else
    echo "[*] Cloning repository..."
    git clone REPO_URL_PLACEHOLDER microservice-e-commerce
    cd microservice-e-commerce
fi

# Build frontend (if frontend directory exists)
if [ -d "frontend" ]; then
    echo "[*] Building frontend..."
    cd frontend
    npm install || echo "[!] npm install failed, continuing..."
    npm run build || echo "[!] npm build failed, continuing..."
    cd ..
else
    echo "[!] Frontend directory not found, skipping build"
fi

# Create .env file
echo "[*] Creating .env file..."
cat > .env <<ENVFILE
# Application Key
APP_KEY=APP_KEY_PLACEHOLDER

# AWS SES Configuration
AWS_REGION=AWS_REGION_PLACEHOLDER
AWS_SES_SMTP_USERNAME=SES_USERNAME_PLACEHOLDER
AWS_SES_SMTP_PASSWORD=SES_PASSWORD_PLACEHOLDER
MAIL_FROM_ADDRESS=MAIL_FROM_ADDRESS_PLACEHOLDER
MAIL_FROM_NAME=MAIL_FROM_NAME_PLACEHOLDER

# Database Configuration
MYSQL_ROOT_PASSWORD=MYSQL_ROOT_PASSWORD_PLACEHOLDER
MYSQL_USER=appuser
MYSQL_PASSWORD=MYSQL_APP_PASSWORD_PLACEHOLDER
ENVFILE

# Stop existing containers if running
echo "[*] Stopping existing containers..."
docker-compose down || true

# Wait for Docker to be ready
echo "[*] Waiting for Docker to be ready..."
sleep 5

# Start services
echo "[*] Starting Docker Compose services..."
docker-compose up -d --build || {
    echo "[X] Docker Compose failed, checking logs..."
    docker-compose logs
    exit 1
}

# Wait for services to be ready
echo "[*] Waiting for services to be ready..."
sleep 30

# Run database migrations
echo "[*] Running database migrations..."
docker-compose exec -T catalog php artisan migrate --seed || echo "[!] Catalog migration failed"
docker-compose exec -T checkout php artisan migrate || echo "[!] Checkout migration failed"
docker-compose exec -T email php artisan migrate || echo "[!] Email migration failed"

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "N/A")

# Log completion
echo "[OK] Deployment completed successfully!"
echo "Application URL: http://$PUBLIC_IP" > ~/deployment-status.txt
echo "Deployment completed at: $(date)" >> ~/deployment-status.txt

echo ""
echo "=========================================="
echo "DEPLOYMENT SUCCESSFUL!"
echo "=========================================="
echo "Application URL: http://$PUBLIC_IP"
echo "=========================================="
DEPLOY_EOF
)

# Replace placeholders in deploy script
DEPLOY_SCRIPT=$(echo "$DEPLOY_SCRIPT" | sed "s|REPO_URL_PLACEHOLDER|$GITHUB_REPO_URL|g")
DEPLOY_SCRIPT=$(echo "$DEPLOY_SCRIPT" | sed "s|APP_KEY_PLACEHOLDER|$APP_KEY|g")
DEPLOY_SCRIPT=$(echo "$DEPLOY_SCRIPT" | sed "s|AWS_REGION_PLACEHOLDER|$AWS_REGION|g")
DEPLOY_SCRIPT=$(echo "$DEPLOY_SCRIPT" | sed "s|SES_USERNAME_PLACEHOLDER|$SES_USERNAME|g")
DEPLOY_SCRIPT=$(echo "$DEPLOY_SCRIPT" | sed "s|SES_PASSWORD_PLACEHOLDER|$SES_PASSWORD|g")
DEPLOY_SCRIPT=$(echo "$DEPLOY_SCRIPT" | sed "s|MAIL_FROM_ADDRESS_PLACEHOLDER|$MAIL_FROM_ADDRESS|g")
DEPLOY_SCRIPT=$(echo "$DEPLOY_SCRIPT" | sed "s|MAIL_FROM_NAME_PLACEHOLDER|$MAIL_FROM_NAME|g")
DEPLOY_SCRIPT=$(echo "$DEPLOY_SCRIPT" | sed "s|MYSQL_ROOT_PASSWORD_PLACEHOLDER|$MYSQL_ROOT_PASSWORD|g")
DEPLOY_SCRIPT=$(echo "$DEPLOY_SCRIPT" | sed "s|MYSQL_APP_PASSWORD_PLACEHOLDER|$MYSQL_APP_PASSWORD|g")

# Write deploy script to temporary file
TEMP_SCRIPT="/tmp/deploy-ec2-$$.sh"
echo "$DEPLOY_SCRIPT" > "$TEMP_SCRIPT"
chmod +x "$TEMP_SCRIPT"

# Copy script to EC2 and execute
echo -e "${CYAN}[*] Copying deployment script to EC2...${NC}"
scp -i "$PEM_FILE" -o StrictHostKeyChecking=no "$TEMP_SCRIPT" "$EC2_USER@$EC2_IP:/tmp/deploy.sh"

echo -e "${CYAN}[*] Executing deployment on EC2 instance...${NC}"
echo -e "${YELLOW}    This will take 5-10 minutes...${NC}"

# Execute the script on EC2
ssh -i "$PEM_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "bash /tmp/deploy.sh"

# Clean up
rm -f "$TEMP_SCRIPT"

echo -e "${GREEN}[OK] Deployment completed!${NC}"
echo -e "${CYAN}[*] Your application should be available at: http://$EC2_IP${NC}"

