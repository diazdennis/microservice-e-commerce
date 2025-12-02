#!/bin/bash

# E-Commerce Microservices Local Development Script
# This script sets up and starts all services for local development on Linux/Mac

echo -e "\033[32m[*] Starting E-Commerce Microservices...\033[0m"

# Check if required tools are installed
echo -e "\033[33m[*] Checking prerequisites...\033[0m"

# Check PHP
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1,2)
    if [[ $(echo "$PHP_VERSION >= 8.1" | bc -l) -eq 1 ]]; then
        echo -e "\033[32m[OK] PHP 8.1+ found (v$PHP_VERSION)\033[0m"
    else
        echo -e "\033[31m[X] PHP 8.1+ required. Found: $PHP_VERSION\033[0m"
        exit 1
    fi
else
    echo -e "\033[31m[X] PHP not found. Please install PHP 8.1+\033[0m"
    exit 1
fi

# Check Composer
if command -v composer &> /dev/null; then
    echo -e "\033[32m[OK] Composer found\033[0m"
else
    echo -e "\033[31m[X] Composer not found. Please install Composer.\033[0m"
    exit 1
fi

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v | cut -d "v" -f 2 | cut -d "." -f 1)
    if [[ $NODE_VERSION -ge 18 ]]; then
        echo -e "\033[32m[OK] Node.js 18+ found (v$NODE_VERSION)\033[0m"
    else
        echo -e "\033[31m[X] Node.js 18+ required. Found: v$NODE_VERSION\033[0m"
        exit 1
    fi
else
    echo -e "\033[31m[X] Node.js not found. Please install Node.js 18+\033[0m"
    exit 1
fi

# Check MySQL
if command -v mysql &> /dev/null; then
    echo -e "\033[32m[OK] MySQL found\033[0m"
else
    echo -e "\033[33m[!] MySQL not found in PATH. Please ensure MySQL is installed and accessible.\033[0m"
fi

echo ""

# Setup databases
echo -e "\033[33m[*] Setting up databases...\033[0m"
echo -e "\033[36mPlease create these databases in MySQL:\033[0m"
echo "  - catalog_db"
echo "  - checkout_db"
echo "  - email_db"
echo ""
echo -e "\033[36mMySQL commands:\033[0m"
echo "  CREATE DATABASE catalog_db;"
echo "  CREATE DATABASE checkout_db;"
echo "  CREATE DATABASE email_db;"
echo ""

read -p "Press Enter after creating the databases..."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Setup Catalog Service
echo -e "\033[33m[*] Setting up Catalog Service...\033[0m"
cd "$SCRIPT_DIR/services/catalog"

if [ ! -d "vendor" ]; then
    echo -e "\033[36mInstalling PHP dependencies...\033[0m"
    composer install
fi

# Copy env file if it doesn't exist
if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        cp env.example .env
        echo -e "\033[32m[OK] Created .env file from env.example\033[0m"
    else
        echo -e "\033[33m[!] No env.example file found. Please create .env manually.\033[0m"
    fi
fi

# Generate app key if not set
if grep -q "APP_KEY=$" .env 2>/dev/null; then
    php artisan key:generate
fi

echo -e "\033[36mRunning migrations and seeders...\033[0m"
php artisan migrate --seed

cd "$SCRIPT_DIR"

# Setup Checkout Service
echo -e "\033[33m[*] Setting up Checkout Service...\033[0m"
cd "$SCRIPT_DIR/services/checkout"

if [ ! -d "vendor" ]; then
    echo -e "\033[36mInstalling PHP dependencies...\033[0m"
    composer install
fi

if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        cp env.example .env
        echo -e "\033[32m[OK] Created .env file from env.example\033[0m"
    else
        echo -e "\033[33m[!] No env.example file found. Please create .env manually.\033[0m"
    fi
fi

# Generate app key if not set
if grep -q "APP_KEY=$" .env 2>/dev/null; then
    php artisan key:generate
fi

echo -e "\033[36mRunning migrations...\033[0m"
php artisan migrate

cd "$SCRIPT_DIR"

# Setup Email Service
echo -e "\033[33m[*] Setting up Email Service...\033[0m"
cd "$SCRIPT_DIR/services/email"

if [ ! -d "vendor" ]; then
    echo -e "\033[36mInstalling PHP dependencies...\033[0m"
    composer install
fi

if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        cp env.example .env
        echo -e "\033[32m[OK] Created .env file from env.example\033[0m"
    else
        echo -e "\033[33m[!] No env.example file found. Please create .env manually.\033[0m"
    fi
fi

# Generate app key if not set
if grep -q "APP_KEY=$" .env 2>/dev/null; then
    php artisan key:generate
fi

echo -e "\033[36mRunning migrations...\033[0m"
php artisan migrate

cd "$SCRIPT_DIR"

# Setup Frontend
echo -e "\033[33m[*] Setting up Frontend...\033[0m"
cd "$SCRIPT_DIR/frontend"

if [ ! -d "node_modules" ]; then
    echo -e "\033[36mInstalling Node.js dependencies...\033[0m"
    npm install
fi

cd "$SCRIPT_DIR"

echo ""
echo -e "\033[32m[OK] Setup complete!\033[0m"
echo ""

# Start services
echo -e "\033[33m[*] Starting services in separate terminal windows...\033[0m"
echo ""

# Function to start service in new terminal
start_service() {
    local service_name=$1
    local service_path=$2
    local command=$3
    local port=$4
    
    echo -e "\033[36m[*] Starting $service_name on port $port...\033[0m"
    
    # Detect OS and desktop environment
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - use osascript to open Terminal
        osascript -e "tell application \"Terminal\" to do script \"cd '$SCRIPT_DIR/$service_path' && echo '[OK] $service_name - Port $port' && $command\""
    elif command -v gnome-terminal &> /dev/null; then
        # GNOME Terminal (Ubuntu, Debian, etc.)
        gnome-terminal --tab --title="$service_name" -- bash -c "cd '$SCRIPT_DIR/$service_path' && echo -e '\033[32m[OK] $service_name - Port $port\033[0m' && $command; exec bash"
    elif command -v xterm &> /dev/null; then
        # xterm (fallback)
        xterm -T "$service_name" -e bash -c "cd '$SCRIPT_DIR/$service_path' && echo '[OK] $service_name - Port $port' && $command; exec bash" &
    elif command -v konsole &> /dev/null; then
        # Konsole (KDE)
        konsole --new-tab -e bash -c "cd '$SCRIPT_DIR/$service_path' && echo '[OK] $service_name - Port $port' && $command; exec bash" &
    elif command -v screen &> /dev/null; then
        # Use screen as fallback
        screen -dmS "$service_name" bash -c "cd '$SCRIPT_DIR/$service_path' && $command"
        echo -e "\033[33m[!] Started $service_name in screen session. Use 'screen -r $service_name' to view.\033[0m"
    else
        # Last resort: run in background
        cd "$SCRIPT_DIR/$service_path"
        nohup bash -c "$command" > "/tmp/${service_name}.log" 2>&1 &
        echo -e "\033[33m[!] Started $service_name in background. Log: /tmp/${service_name}.log\033[0m"
        cd "$SCRIPT_DIR"
    fi
    
    sleep 2
}

# Start Catalog Service
start_service "Catalog Service" "services/catalog" "php artisan serve --port=8001" "8001"

# Start Checkout Service
start_service "Checkout Service" "services/checkout" "php artisan serve --port=8002" "8002"

# Start Email Service
start_service "Email Service" "services/email" "php artisan serve --port=8003" "8003"

# Start Frontend
start_service "Frontend" "frontend" "npm run dev" "5173"

echo ""
echo -e "\033[32m[OK] All services are starting!\033[0m"
echo ""
echo -e "\033[33m[*] Services will open in separate terminal windows/tabs.\033[0m"
echo -e "\033[36m[*] Frontend will be available at: http://localhost:5173\033[0m"
echo ""
echo -e "\033[33m[*] To stop services:\033[0m"
if command -v screen &> /dev/null && screen -list | grep -q "Catalog Service\|Checkout Service\|Email Service\|Frontend"; then
    echo "  - Use 'screen -r <service_name>' to view a service"
    echo "  - Press Ctrl+A then K to kill a screen session"
    echo "  - Or use 'pkill -f \"php artisan serve\"' and 'pkill -f \"npm run dev\"'"
else
    echo "  - Close the terminal windows/tabs for each service"
    echo "  - Or use 'pkill -f \"php artisan serve\"' and 'pkill -f \"npm run dev\"'"
fi
echo ""
echo -e "\033[32m[*] Happy coding!\033[0m"

