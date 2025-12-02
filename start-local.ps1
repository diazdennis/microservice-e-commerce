# E-Commerce Microservices Local Development Script
# This script sets up and starts all services for local development

Write-Host "[*] Starting E-Commerce Microservices..." -ForegroundColor Green

# Check if required tools are installed
Write-Host "[*] Checking prerequisites..." -ForegroundColor Yellow

# Check PHP
try {
    $phpVersion = php -v 2>$null
    if ($phpVersion -match "PHP 8\.[0-9]+") {
        Write-Host "[OK] PHP 8.1+ found" -ForegroundColor Green
    } else {
        Write-Host "[X] PHP 8.1+ required. Please install PHP." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[X] PHP not found. Please install PHP 8.1+" -ForegroundColor Red
    exit 1
}

# Check Composer
try {
    composer -v >$null 2>&1
    Write-Host "[OK] Composer found" -ForegroundColor Green
} catch {
    Write-Host "[X] Composer not found. Please install Composer." -ForegroundColor Red
    exit 1
}

# Check Node.js
try {
    $nodeVersion = node -v 2>$null
    if ($nodeVersion) {
        # Extract major version number
        $majorVersion = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
        if ($majorVersion -ge 18) {
            Write-Host "[OK] Node.js $nodeVersion found (18+ required)" -ForegroundColor Green
        } else {
            Write-Host "[X] Node.js 18+ required. Found version $nodeVersion" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "[X] Node.js not found. Please install Node.js 18+" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[X] Node.js not found. Please install Node.js 18+" -ForegroundColor Red
    exit 1
}

# Check MySQL
try {
    $mysqlVersion = mysql -V 2>$null
    if ($mysqlVersion) {
        Write-Host "[OK] MySQL found" -ForegroundColor Green
    } else {
        Write-Host "[!] MySQL not found in PATH. Please ensure MySQL is installed and accessible." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[!] MySQL not found in PATH. Please ensure MySQL is installed (XAMPP/WAMP recommended)." -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White

# Setup databases
Write-Host "[*] Setting up databases..." -ForegroundColor Yellow

# Create databases (you may need to update credentials)
Write-Host "Please create these databases in MySQL:" -ForegroundColor Cyan
Write-Host "  - catalog_db" -ForegroundColor White
Write-Host "  - checkout_db" -ForegroundColor White
Write-Host "  - email_db" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "MySQL command:" -ForegroundColor Cyan
Write-Host "  CREATE DATABASE catalog_db;" -ForegroundColor White
Write-Host "  CREATE DATABASE checkout_db;" -ForegroundColor White
Write-Host "  CREATE DATABASE email_db;" -ForegroundColor White
Write-Host "" -ForegroundColor White

Read-Host "Press Enter after creating the databases"

# Setup Catalog Service
Write-Host "[*] Setting up Catalog Service..." -ForegroundColor Yellow
Set-Location "services\catalog"

if (!(Test-Path "vendor")) {
    Write-Host "Installing PHP dependencies..." -ForegroundColor Cyan
    composer install
}

# Copy env file if it doesn't exist
if (!(Test-Path ".env")) {
    if (Test-Path "env.example") {
        Copy-Item "env.example" ".env"
        Write-Host "[OK] Created .env file from env.example" -ForegroundColor Green
    } else {
        Write-Host "[!] No env.example file found. Please create .env manually." -ForegroundColor Yellow
    }
}

Write-Host "Running migrations and seeders..." -ForegroundColor Cyan
php artisan migrate --seed

Set-Location "..\.."

# Setup Checkout Service
Write-Host "[*] Setting up Checkout Service..." -ForegroundColor Yellow
Set-Location "services\checkout"

if (!(Test-Path "vendor")) {
    Write-Host "Installing PHP dependencies..." -ForegroundColor Cyan
    composer install
}

if (!(Test-Path ".env")) {
    if (Test-Path "env.example") {
        Copy-Item "env.example" ".env"
        Write-Host "[OK] Created .env file from env.example" -ForegroundColor Green
    } else {
        Write-Host "[!] No env.example file found. Please create .env manually." -ForegroundColor Yellow
    }
}

Write-Host "Running migrations..." -ForegroundColor Cyan
php artisan migrate

Set-Location "..\.."

# Setup Email Service
Write-Host "[*] Setting up Email Service..." -ForegroundColor Yellow
Set-Location "services\email"

if (!(Test-Path "vendor")) {
    Write-Host "Installing PHP dependencies..." -ForegroundColor Cyan
    composer install
}

if (!(Test-Path ".env")) {
    if (Test-Path "env.example") {
        Copy-Item "env.example" ".env"
        Write-Host "[OK] Created .env file from env.example" -ForegroundColor Green
    } else {
        Write-Host "[!] No env.example file found. Please create .env manually." -ForegroundColor Yellow
    }
}

Write-Host "Running migrations..." -ForegroundColor Cyan
php artisan migrate

Set-Location "..\.."

# Setup Frontend
Write-Host "[*] Setting up Frontend..." -ForegroundColor Yellow
Set-Location "frontend"

if (!(Test-Path "node_modules")) {
    Write-Host "Installing Node.js dependencies..." -ForegroundColor Cyan
    npm install
}

Set-Location ".."

Write-Host "" -ForegroundColor White
Write-Host "[OK] Setup complete!" -ForegroundColor Green
Write-Host "" -ForegroundColor White

# Start services
Write-Host "[*] Starting services in separate windows..." -ForegroundColor Yellow
Write-Host "" -ForegroundColor White

# Start Catalog Service
Write-Host "[*] Starting Catalog Service on port 8001..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD\services\catalog'; Write-Host 'Catalog Service - Port 8001' -ForegroundColor Green; php artisan serve --port=8001"

# Wait a moment before starting next service
Start-Sleep -Seconds 2

# Start Checkout Service
Write-Host "[*] Starting Checkout Service on port 8002..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD\services\checkout'; Write-Host 'Checkout Service - Port 8002' -ForegroundColor Green; php artisan serve --port=8002"

# Wait a moment before starting next service
Start-Sleep -Seconds 2

# Start Email Service
Write-Host "[*] Starting Email Service on port 8003..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD\services\email'; Write-Host 'Email Service - Port 8003' -ForegroundColor Green; php artisan serve --port=8003"

# Wait a moment before starting next service
Start-Sleep -Seconds 2

# Start Frontend
Write-Host "[*] Starting Frontend on port 5173..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD\frontend'; Write-Host 'Frontend - Port 5173' -ForegroundColor Green; npm run dev"

Write-Host "" -ForegroundColor White
Write-Host "[OK] All services are starting!" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "Services will open in separate PowerShell windows." -ForegroundColor Yellow
Write-Host "Frontend will be available at: http://localhost:5173" -ForegroundColor Cyan
Write-Host "" -ForegroundColor White
Write-Host "To stop services, close the respective PowerShell windows." -ForegroundColor Yellow
Write-Host "" -ForegroundColor White
Write-Host "[*] Happy coding!" -ForegroundColor Green
