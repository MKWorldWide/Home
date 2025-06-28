#!/bin/bash

# SSL Certificate Setup Script for MKWW Website
# This script sets up SSL certificates using Let's Encrypt

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo -e "${BLUE}🔒 Setting up SSL Certificate...${NC}"

# Check if domain is provided
if [ -z "$1" ]; then
    print_error "Please provide a domain name"
    echo "Usage: $0 your-domain.com"
    exit 1
fi

DOMAIN=$1

# Install Certbot if not installed
if ! command -v certbot &> /dev/null; then
    print_status "Installing Certbot..."
    sudo apt update
    sudo apt install certbot python3-certbot-nginx -y
else
    print_status "Certbot is already installed"
fi

# Check if Nginx is running
if ! sudo systemctl is-active --quiet nginx; then
    print_error "Nginx is not running. Please start Nginx first."
    exit 1
fi

# Verify domain is pointing to this server
print_status "Verifying domain DNS settings..."
SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $DOMAIN)

if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    print_warning "Domain $DOMAIN is not pointing to this server's IP ($SERVER_IP)"
    print_warning "Current DNS record points to: $DOMAIN_IP"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get SSL certificate
print_status "Requesting SSL certificate for $DOMAIN..."
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# Test certificate renewal
print_status "Testing certificate renewal..."
sudo certbot renew --dry-run

# Set up automatic renewal
print_status "Setting up automatic renewal..."
sudo crontab -l 2>/dev/null | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet"; } | sudo crontab -

print_status "SSL certificate setup completed!"
echo -e "${GREEN}🌐 Your website is now available at: https://$DOMAIN${NC}"
echo -e "${GREEN}📅 Certificate will auto-renew every 90 days${NC}" 