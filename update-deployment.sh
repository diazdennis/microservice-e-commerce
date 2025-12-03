#!/bin/bash
# Script to update deployment after pulling latest code
# This ensures frontend is rebuilt and Docker containers are refreshed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}[*] Starting deployment update...${NC}"

# Check if we're in the project directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}[X] Error: docker-compose.yml not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Step 1: Pull latest code (if not already done)
echo -e "${CYAN}[*] Checking for latest code...${NC}"
if [ -d ".git" ]; then
    echo -e "${YELLOW}[*] Pulling latest changes from git...${NC}"
    git pull origin main || git pull origin master || echo -e "${YELLOW}[!] Git pull failed or already up to date${NC}"
else
    echo -e "${YELLOW}[!] Not a git repository, skipping git pull${NC}"
fi

# Step 2: Rebuild frontend
echo -e "${CYAN}[*] Rebuilding frontend...${NC}"
if [ -d "frontend" ]; then
    cd frontend
    
    # Remove old build
    if [ -d "dist" ]; then
        echo -e "${YELLOW}[*] Removing old frontend build...${NC}"
        rm -rf dist
    fi
    
    # Install dependencies
    echo -e "${CYAN}[*] Installing frontend dependencies...${NC}"
    npm install
    
    # Build frontend (without localhost URLs - use default /api paths)
    echo -e "${CYAN}[*] Building frontend (this may take a minute)...${NC}"
    # Unset any localhost environment variables to ensure /api paths are used
    unset VITE_CATALOG_API
    unset VITE_CHECKOUT_API
    npm run build
    
    if [ ! -d "dist" ] || [ -z "$(ls -A dist)" ]; then
        echo -e "${RED}[X] Frontend build failed! dist directory is empty.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[OK] Frontend built successfully${NC}"
    cd ..
else
    echo -e "${RED}[X] Frontend directory not found!${NC}"
    exit 1
fi

# Step 3: Stop existing containers
echo -e "${CYAN}[*] Stopping existing Docker containers...${NC}"
docker-compose down

# Step 4: Remove old images (optional but recommended for clean rebuild)
echo -e "${CYAN}[*] Removing old Docker images...${NC}"
docker-compose rm -f || true

# Step 5: Rebuild Docker images (with no cache to ensure fresh builds)
echo -e "${CYAN}[*] Rebuilding Docker images (this will take several minutes)...${NC}"
docker-compose build --no-cache

# Step 6: Start services
echo -e "${CYAN}[*] Starting Docker containers...${NC}"
docker-compose up -d

# Step 7: Wait for services to be ready
echo -e "${CYAN}[*] Waiting for services to be ready...${NC}"
sleep 15

# Step 8: Check service status
echo -e "${CYAN}[*] Checking service status...${NC}"
docker-compose ps

# Step 9: Run migrations if needed (optional)
read -p "Do you want to run database migrations? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}[*] Running database migrations...${NC}"
    docker-compose exec -T catalog php artisan migrate --seed || echo -e "${YELLOW}[!] Catalog migration failed or already up to date${NC}"
    docker-compose exec -T checkout php artisan migrate || echo -e "${YELLOW}[!] Checkout migration failed or already up to date${NC}"
    docker-compose exec -T email php artisan migrate || echo -e "${YELLOW}[!] Email migration failed or already up to date${NC}"
fi

# Get public IP if on EC2
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DEPLOYMENT UPDATE COMPLETE!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Application URL: http://${PUBLIC_IP}${NC}"
echo ""
echo -e "${YELLOW}Note: If you're still seeing old content, try:${NC}"
echo -e "  1. Hard refresh your browser (Ctrl+Shift+R or Cmd+Shift+R)"
echo -e "  2. Clear browser cache"
echo -e "  3. Check if nginx is serving the correct files:"
echo -e "     docker-compose exec frontend ls -la /var/www/frontend/dist"
echo ""
echo -e "${GREEN}[OK] All done!${NC}"

