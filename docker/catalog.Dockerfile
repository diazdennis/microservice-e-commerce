# Use PHP 8.2 with Apache
FROM php:8.2-apache

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy application code
COPY services/catalog/ .

# Create storage directories if they don't exist and set permissions
RUN mkdir -p /var/www/html/storage/framework/cache \
    && mkdir -p /var/www/html/storage/framework/sessions \
    && mkdir -p /var/www/html/storage/framework/views \
    && mkdir -p /var/www/html/storage/logs \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev

# Generate application key if .env exists
RUN if [ -f .env ]; then php artisan key:generate; fi

# Configure Apache for Laravel
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN a2enmod rewrite

# Set DocumentRoot to Laravel's public directory
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's|<Directory /var/www/html>|<Directory /var/www/html/public>|g' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's|AllowOverride None|AllowOverride All|g' /etc/apache2/sites-available/000-default.conf

# Create .htaccess file if it doesn't exist
RUN if [ ! -f /var/www/html/public/.htaccess ]; then \
    echo '<IfModule mod_rewrite.c>' > /var/www/html/public/.htaccess && \
    echo '    <IfModule mod_negotiation.c>' >> /var/www/html/public/.htaccess && \
    echo '        Options -MultiViews -Indexes' >> /var/www/html/public/.htaccess && \
    echo '    </IfModule>' >> /var/www/html/public/.htaccess && \
    echo '    RewriteEngine On' >> /var/www/html/public/.htaccess && \
    echo '    RewriteCond %{HTTP:Authorization} .' >> /var/www/html/public/.htaccess && \
    echo '    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]' >> /var/www/html/public/.htaccess && \
    echo '    RewriteCond %{REQUEST_FILENAME} !-d' >> /var/www/html/public/.htaccess && \
    echo '    RewriteCond %{REQUEST_URI} (.+)/$' >> /var/www/html/public/.htaccess && \
    echo '    RewriteRule ^ %1 [L,R=301]' >> /var/www/html/public/.htaccess && \
    echo '    RewriteCond %{REQUEST_FILENAME} !-d' >> /var/www/html/public/.htaccess && \
    echo '    RewriteCond %{REQUEST_FILENAME} !-f' >> /var/www/html/public/.htaccess && \
    echo '    RewriteRule ^ index.php [L]' >> /var/www/html/public/.htaccess && \
    echo '</IfModule>' >> /var/www/html/public/.htaccess; \
    fi

# Set permissions for .htaccess
RUN chown www-data:www-data /var/www/html/public/.htaccess && \
    chmod 644 /var/www/html/public/.htaccess

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
