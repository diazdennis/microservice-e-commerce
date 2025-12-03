#!/bin/bash
# Manual Deployment Script for E-Commerce Microservices
# Run this script on an EC2 instance to deploy manually

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Manual Deployment Script${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please do not run as root. Run as ec2-user.${NC}"
   exit 1
fi

# Step 1: Update System
echo -e "${CYAN}[*] Step 1: Updating system...${NC}"
sudo dnf update -y

# Step 2: Install Docker
echo -e "${CYAN}[*] Step 2: Installing Docker...${NC}"
sudo dnf install -y docker git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Wait a moment for group changes
sleep 2

# Activate docker group membership (allows docker commands without sudo)
# Note: This creates a new shell, so we'll need to handle this carefully
# For now, we'll use sudo for docker commands where needed

# Step 3: Install Docker Buildx
echo -e "${CYAN}[*] Step 3: Installing Docker Buildx...${NC}"
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  BUILDX_ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
  BUILDX_ARCH="arm64"
else
  BUILDX_ARCH="amd64"
fi

mkdir -p ~/.docker/cli-plugins
sudo mkdir -p /usr/local/lib/docker/cli-plugins
curl -L "https://github.com/docker/buildx/releases/latest/download/buildx-v0.17.0.linux-${BUILDX_ARCH}" -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx
sudo cp ~/.docker/cli-plugins/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

# Set up buildx builder (required for buildx to work)
sudo docker buildx install || echo -e "${YELLOW}[!] Buildx install command completed${NC}"
sudo docker buildx create --use --name builder 2>/dev/null || sudo docker buildx use builder 2>/dev/null || echo -e "${YELLOW}[!] Buildx builder setup completed${NC}"

docker buildx version || echo -e "${YELLOW}[!] Buildx verification skipped${NC}"

# Step 4: Install Docker Compose
echo -e "${CYAN}[*] Step 4: Installing Docker Compose...${NC}"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  COMPOSE_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ]; then
  COMPOSE_ARCH="aarch64"
else
  COMPOSE_ARCH="x86_64"
fi
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-${OS}-${COMPOSE_ARCH}" -o /tmp/docker-compose
sudo mv /tmp/docker-compose /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version || echo -e "${YELLOW}[!] Docker Compose verification skipped${NC}"

# Step 5: Install Node.js
echo -e "${CYAN}[*] Step 5: Installing Node.js and npm...${NC}"
sudo dnf install -y nodejs npm

# Step 6: Clone Repository
echo -e "${CYAN}[*] Step 6: Cloning repository...${NC}"
cd /home/$USER
if [ -d "microservice-e-commerce" ]; then
  echo -e "${YELLOW}[!] Repository already exists, pulling latest...${NC}"
  cd microservice-e-commerce
  git pull
else
  read -p "Enter GitHub repository URL (or press Enter for default): " REPO_URL
  REPO_URL=${REPO_URL:-https://github.com/diazdennis/microservice-e-commerce.git}
  git clone $REPO_URL microservice-e-commerce
  cd microservice-e-commerce
fi

# Step 7: Build Frontend
echo -e "${CYAN}[*] Step 7: Building frontend...${NC}"
if [ -d "frontend" ]; then
  cd frontend
  npm install
  npm run build
  cd ..
  
  if [ ! -d "frontend/dist" ] || [ -z "$(ls -A frontend/dist)" ]; then
    echo -e "${RED}[X] Frontend build failed!${NC}"
    exit 1
  fi
  echo -e "${GREEN}[OK] Frontend built successfully${NC}"
else
  echo -e "${RED}[X] Frontend directory not found!${NC}"
  exit 1
fi

# Step 8: Create Environment Files
echo -e "${CYAN}[*] Step 8: Creating environment files...${NC}"

# Prompt for values
read -p "Enter MySQL root password: " MYSQL_ROOT_PASS
read -p "Enter MySQL app password: " MYSQL_APP_PASS
read -p "Enter Laravel APP_KEY (or press Enter to generate): " APP_KEY_INPUT
APP_KEY=${APP_KEY_INPUT:-$(openssl rand -base64 32)}

read -p "Enter AWS Region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

read -p "Enter SES SMTP Username: " SES_USERNAME
read -s -p "Enter SES SMTP Password: " SES_PASSWORD
echo ""
read -p "Enter Mail From Address: " MAIL_FROM
read -p "Enter Mail From Name (default: E-Commerce Store): " MAIL_FROM_NAME
MAIL_FROM_NAME=${MAIL_FROM_NAME:-E-Commerce Store}

# Create root .env
cat > .env << EOF
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASS
MYSQL_USER=appuser
MYSQL_PASSWORD=$MYSQL_APP_PASS
APP_KEY=base64:$APP_KEY
CORS_ALLOWED_ORIGINS=*
EOF

# Create catalog .env
mkdir -p services/catalog
cat > services/catalog/.env << EOF
APP_NAME="Catalog Service"
APP_ENV=production
APP_KEY=base64:$APP_KEY
APP_DEBUG=false
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=catalog_db
DB_USERNAME=appuser
DB_PASSWORD=$MYSQL_APP_PASS

CORS_ALLOWED_ORIGINS=*
EOF

# Create checkout .env
mkdir -p services/checkout
cat > services/checkout/.env << EOF
APP_NAME="Checkout Service"
APP_ENV=production
APP_KEY=base64:$APP_KEY
APP_DEBUG=false
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=checkout_db
DB_USERNAME=appuser
DB_PASSWORD=$MYSQL_APP_PASS

CATALOG_SERVICE_URL=http://catalog
EMAIL_SERVICE_URL=http://email

CORS_ALLOWED_ORIGINS=*
EOF

# Create email .env
mkdir -p services/email
cat > services/email/.env << EOF
APP_NAME="Email Service"
APP_ENV=production
APP_KEY=base64:$APP_KEY
APP_DEBUG=false
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=email_db
DB_USERNAME=appuser
DB_PASSWORD=$MYSQL_APP_PASS

MAIL_MAILER=smtp
MAIL_HOST=email-smtp.${AWS_REGION}.amazonaws.com
MAIL_PORT=587
MAIL_USERNAME=$SES_USERNAME
MAIL_PASSWORD=$SES_PASSWORD
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=$MAIL_FROM
MAIL_FROM_NAME="$MAIL_FROM_NAME"
AWS_REGION=$AWS_REGION

CORS_ALLOWED_ORIGINS=*
EOF

# Create frontend .env.production
mkdir -p frontend
cat > frontend/.env.production << EOF
VITE_CATALOG_API=/api
VITE_CHECKOUT_API=/api
EOF

echo -e "${GREEN}[OK] Environment files created${NC}"

# Step 9: Start Docker Services
echo -e "${CYAN}[*] Step 9: Starting Docker services...${NC}"
echo -e "${YELLOW}[!] This may take 10-15 minutes...${NC}"
# Check if docker works without sudo, otherwise use sudo
if docker info > /dev/null 2>&1; then
  DOCKER_CMD="docker"
  COMPOSE_CMD="docker-compose"
else
  echo -e "${YELLOW}[!] Using sudo for docker commands (group membership requires logout/login)${NC}"
  DOCKER_CMD="sudo docker"
  COMPOSE_CMD="sudo docker-compose"
fi

$COMPOSE_CMD up -d --build

if [ $? -ne 0 ]; then
  echo -e "${RED}[X] Docker Compose failed!${NC}"
  $COMPOSE_CMD logs
  exit 1
fi

# Step 10: Wait for services
echo -e "${CYAN}[*] Step 10: Waiting for services to be ready...${NC}"
sleep 30

# Step 11: Check status
echo -e "${CYAN}[*] Step 11: Checking service status...${NC}"
$COMPOSE_CMD ps

# Step 12: Run Migrations
echo -e "${CYAN}[*] Step 12: Running database migrations...${NC}"
$COMPOSE_CMD exec -T catalog php artisan migrate --seed || echo -e "${YELLOW}[!] Catalog migration failed or already up to date${NC}"
$COMPOSE_CMD exec -T checkout php artisan migrate || echo -e "${YELLOW}[!] Checkout migration failed or already up to date${NC}"
$COMPOSE_CMD exec -T email php artisan migrate || echo -e "${YELLOW}[!] Email migration failed or already up to date${NC}"

# Step 13: Get Public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")

# Step 14: Test Application
echo -e "${CYAN}[*] Step 14: Testing application...${NC}"
sleep 5
if curl -f http://localhost > /dev/null 2>&1; then
  echo -e "${GREEN}[OK] Application is responding!${NC}"
else
  echo -e "${YELLOW}[!] Application not responding yet, check logs:${NC}"
  echo "   docker-compose logs frontend"
fi

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DEPLOYMENT COMPLETE!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Application URL: http://$PUBLIC_IP${NC}"
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo "  docker-compose ps              # Check container status"
echo "  docker-compose logs -f         # View all logs"
echo "  docker-compose logs frontend   # View frontend logs"
echo "  docker-compose restart catalog # Restart catalog service"
echo ""
echo -e "${GREEN}[OK] All done!${NC}"

