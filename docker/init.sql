-- Create databases for microservices
CREATE DATABASE IF NOT EXISTS catalog_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS checkout_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS email_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant permissions to appuser
GRANT ALL PRIVILEGES ON catalog_db.* TO 'appuser'@'%';
GRANT ALL PRIVILEGES ON checkout_db.* TO 'appuser'@'%';
GRANT ALL PRIVILEGES ON email_db.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
