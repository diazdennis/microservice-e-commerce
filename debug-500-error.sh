#!/bin/bash
# Script to debug 500 errors on EC2
# Run this on your EC2 instance to check Laravel configuration

echo "=========================================="
echo "Debugging 500 Server Error"
echo "=========================================="
echo ""

# Check container status
echo "[*] Checking container status..."
docker-compose ps
echo ""

# Check Laravel logs
echo "[*] Checking Laravel error logs..."
echo "--- Catalog Service Logs ---"
docker-compose exec -T catalog tail -n 50 /var/www/html/storage/logs/laravel.log 2>/dev/null || echo "No logs found or container not running"
echo ""

# Check if .env exists
echo "[*] Checking .env file..."
docker-compose exec -T catalog ls -la /var/www/html/.env 2>/dev/null || echo ".env file not found!"
echo ""

# Check APP_KEY
echo "[*] Checking APP_KEY..."
docker-compose exec -T catalog grep APP_KEY /var/www/html/.env 2>/dev/null | head -1 || echo "APP_KEY not found in .env"
echo ""

# Check database connection
echo "[*] Testing database connection..."
docker-compose exec -T catalog php artisan migrate:status 2>&1 | head -20
echo ""

# Check storage permissions
echo "[*] Checking storage permissions..."
docker-compose exec -T catalog ls -la /var/www/html/storage/logs/ 2>/dev/null | head -5
echo ""

# Check Apache error logs
echo "[*] Checking Apache error logs..."
docker-compose exec -T catalog tail -n 20 /var/log/apache2/error.log 2>/dev/null || echo "Apache error log not accessible"
echo ""

# Check if routes are registered
echo "[*] Checking registered routes..."
docker-compose exec -T catalog php artisan route:list 2>&1 | grep -E "api/products|api/categories" || echo "Routes not found or error occurred"
echo ""

# Test direct PHP execution
echo "[*] Testing PHP..."
docker-compose exec -T catalog php -v
echo ""

# Check Apache configuration
echo "[*] Checking Apache DocumentRoot..."
docker-compose exec -T catalog grep -A 2 DocumentRoot /etc/apache2/sites-available/000-default.conf 2>/dev/null || echo "Apache config not accessible"
echo ""

# Check if .htaccess exists
echo "[*] Checking .htaccess file..."
docker-compose exec -T catalog ls -la /var/www/html/public/.htaccess 2>/dev/null || echo ".htaccess file not found!"
echo ""

echo "=========================================="
echo "Common fixes:"
echo "1. Ensure .env file exists with APP_KEY"
echo "2. Run migrations: docker-compose exec catalog php artisan migrate"
echo "3. Set storage permissions: docker-compose exec catalog chmod -R 775 storage"
echo "4. Clear cache: docker-compose exec catalog php artisan config:clear"
echo "=========================================="

