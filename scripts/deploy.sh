#!/bin/bash

# MKWW Website Deployment Script
# This script automates the deployment process for AWS EC2

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="mkww-website"
REPO_URL="https://github.com/M-K-World-Wide/Home.git"
DEPLOY_DIR="/var/www/mkww-website"
NGINX_CONFIG="/etc/nginx/sites-available/mkww-website"

echo -e "${BLUE}🚀 Starting MKWW Website Deployment...${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js if not installed
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    print_status "Node.js is already installed"
fi

# Install PM2 if not installed
if ! command -v pm2 &> /dev/null; then
    print_status "Installing PM2..."
    sudo npm install -g pm2
else
    print_status "PM2 is already installed"
fi

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    print_status "Installing Nginx..."
    sudo apt install nginx -y
else
    print_status "Nginx is already installed"
fi

# Create deployment directory
print_status "Creating deployment directory..."
sudo mkdir -p $DEPLOY_DIR
sudo chown $USER:$USER $DEPLOY_DIR

# Clone or update repository
if [ -d "$DEPLOY_DIR/.git" ]; then
    print_status "Updating existing repository..."
    cd $DEPLOY_DIR
    git pull origin main
else
    print_status "Cloning repository..."
    git clone $REPO_URL $DEPLOY_DIR
    cd $DEPLOY_DIR
fi

# Install dependencies
print_status "Installing dependencies..."
npm install

# Build application
print_status "Building application..."
npm run build

# Stop existing PM2 process if running
if pm2 list | grep -q $APP_NAME; then
    print_status "Stopping existing PM2 process..."
    pm2 stop $APP_NAME
    pm2 delete $APP_NAME
fi

# Start application with PM2
print_status "Starting application with PM2..."
pm2 start npm --name $APP_NAME -- start
pm2 startup
pm2 save

# Create Nginx configuration
print_status "Configuring Nginx..."
sudo tee $NGINX_CONFIG > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }

    # Serve static files directly
    location /assets/ {
        alias $DEPLOY_DIR/dist/assets/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable site and restart Nginx
print_status "Enabling Nginx site..."
sudo ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
if sudo nginx -t; then
    print_status "Nginx configuration is valid"
    sudo systemctl restart nginx
    sudo systemctl enable nginx
else
    print_error "Nginx configuration is invalid"
    exit 1
fi

# Check if application is running
sleep 5
if pm2 list | grep -q $APP_NAME; then
    print_status "Application is running successfully"
else
    print_error "Application failed to start"
    pm2 logs $APP_NAME
    exit 1
fi

# Display deployment information
echo -e "${BLUE}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}📊 Application Status:${NC}"
pm2 status $APP_NAME
echo -e "${GREEN}🌐 Nginx Status:${NC}"
sudo systemctl status nginx --no-pager -l
echo -e "${GREEN}📝 Useful Commands:${NC}"
echo "  PM2 logs: pm2 logs $APP_NAME"
echo "  PM2 restart: pm2 restart $APP_NAME"
echo "  Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "  Application URL: http://$(curl -s ifconfig.me)"

print_status "Deployment completed!" 