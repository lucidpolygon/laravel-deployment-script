#!/bin/bash

# Exit on error
set -e

# Variables - you'll need to customize these
DB_NAME="laravel"
DB_USER="laravel_user"
DB_PASSWORD="your_secure_password"
GITHUB_REPO="https://github.com/yourusername/your-repo.git"
DOMAIN="yourdomain.com/server IP"
PROJECT_PATH="/var/www/laravel"
DEPLOY_PATH="$PROJECT_PATH/current"

# Versions
PHP=8.2
NPM_V=16.x

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting Laravel server setup...${NC}"

# Update system
apt-get update
apt-get upgrade -y

# Add PHP repository via ppa:ondrej
apt-get install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
apt-get update

# Install required packages
apt-get install -y \
    nginx \
    mysql-server \
    php${PHP_V}-fpm \
    php${PHP_V}-cli \
    php${PHP_V}-common \
    php${PHP_V}-mysql \
    php${PHP_V}-mbstring \
    php${PHP_V}-xml \
    php${PHP_V}-curl \
    php${PHP_V}-zip \
    php${PHP_V}-gd \
    php${PHP_V}-bcmath \
    php${PHP_V}-intl \
    composer \
    git \
    supervisor \
    unzip \
    acl


# Install Node.js and NPM
curl -fsSL https://deb.nodesource.com/setup_${NPM_V} | bash -
apt-get install -y nodejs
    
# Configure MySQL
mysql -e "CREATE DATABASE $DB_NAME;"
mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Configure PHP
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/${PHP_V}/fpm/php.ini
systemctl restart php${PHP_V}-fpm

# Configure Nginx
cat > /etc/nginx/sites-available/laravel << 'EOL'
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;
    root /var/www/laravel/current/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php${PHP_V}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOL

sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/" /etc/nginx/sites-available/laravel
ln -sf /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Create deployment structure
mkdir -p $PROJECT_PATH/{shared,releases}
cd $PROJECT_PATH
git clone $GITHUB_REPO releases/initial

# Create shared directories
mkdir -p shared/.env
mkdir -p shared/storage/app/public
mkdir -p shared/storage/framework/{cache,sessions,views}
mkdir -p shared/storage/logs

# Set permissions
chown -R www-data:www-data $PROJECT_PATH
chmod -R 775 $PROJECT_PATH

# Create deployment script
cat > /usr/local/bin/deploy-laravel << 'EOL'
#!/bin/bash
set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PROJECT_PATH="/var/www/laravel"
RELEASE_PATH="$PROJECT_PATH/releases/$TIMESTAMP"
SHARED_PATH="$PROJECT_PATH/shared"
CURRENT_PATH="$PROJECT_PATH/current"

# Clone latest code
git clone GITHUB_REPO_PLACEHOLDER "$RELEASE_PATH"
cd "$RELEASE_PATH"

# Install dependencies
composer install --no-dev --optimize-autoloader

# Link shared resources
ln -s "$SHARED_PATH/.env" "$RELEASE_PATH/.env"
rm -rf "$RELEASE_PATH/storage"
ln -s "$SHARED_PATH/storage" "$RELEASE_PATH/storage"

# Optimize Laravel
php artisan optimize
php artisan view:cache
php artisan config:cache
php artisan route:cache
php artisan event:cache


# Make new release live (atomic switch)
ln -sfn "$RELEASE_PATH" "$CURRENT_PATH"

# Cleanup old releases (keep last 5)
cd "$PROJECT_PATH/releases" && ls -t | tail -n +6 | xargs -r rm -rf

# Restart PHP-FPM
systemctl restart php${PHP_V}-fpm

echo "Deployment completed successfully!"
EOL

sed -i "s|GITHUB_REPO_PLACEHOLDER|$GITHUB_REPO|" /usr/local/bin/deploy-laravel
chmod +x /usr/local/bin/deploy-laravel

# Create initial .env file
cd $PROJECT_PATH/releases/initial
cp .env.example $PROJECT_PATH/shared/.env

# Set up initial symlinks
ln -s $PROJECT_PATH/shared/.env $PROJECT_PATH/releases/initial/.env
rm -rf $PROJECT_PATH/releases/initial/storage
ln -s $PROJECT_PATH/shared/storage $PROJECT_PATH/releases/initial/storage

# Make initial release current
ln -sfn $PROJECT_PATH/releases/initial $PROJECT_PATH/current

echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}Next steps:${NC}"
echo "1. Update the shared/.env file with your environment settings"
echo "2. Run 'deploy-laravel' whenever you want to deploy new changes"
echo "3. Consider setting up SSL with Let's Encrypt"
echo "4. Consider setting up GitHub Actions for automated deployment"