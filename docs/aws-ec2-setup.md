# AWS EC2 Setup and Deployment Guide

This guide provides step-by-step instructions for setting up and deploying the MKWW Website on AWS EC2.

## Prerequisites

- AWS Account with EC2 access
- Basic knowledge of AWS services
- Domain name (optional but recommended)
- SSH key pair

## Step 1: Launch EC2 Instance

### 1.1 Choose AMI
- **Recommended**: Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
- **Alternative**: Amazon Linux 2 AMI

### 1.2 Choose Instance Type
- **Free Tier**: t2.micro (1 vCPU, 1 GB RAM)
- **Production**: t3.small or larger (2 vCPU, 2 GB RAM)

### 1.3 Configure Instance Details
- **Network**: Default VPC
- **Subnet**: Any public subnet
- **Auto-assign Public IP**: Enable

### 1.4 Configure Security Group
Create a new security group with the following rules:

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | 0.0.0.0/0 | SSH access |
| HTTP | TCP | 80 | 0.0.0.0/0 | HTTP traffic |
| HTTPS | TCP | 443 | 0.0.0.0/0 | HTTPS traffic |
| Custom TCP | TCP | 3000 | 0.0.0.0/0 | Development server |

### 1.5 Review and Launch
- Review your configuration
- Select or create a key pair
- Launch the instance

## Step 2: Connect to EC2 Instance

### 2.1 Using SSH (Linux/Mac)
```bash
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

### 2.2 Using PuTTY (Windows)
1. Convert your .pem key to .ppk format using PuTTYgen
2. Use PuTTY to connect with the .ppk key

## Step 3: Initial Server Setup

### 3.1 Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### 3.2 Install Essential Packages
```bash
sudo apt install -y curl wget git unzip software-properties-common
```

### 3.3 Configure Firewall (Optional)
```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

## Step 4: Install Node.js

### 4.1 Add NodeSource Repository
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
```

### 4.2 Install Node.js
```bash
sudo apt-get install -y nodejs
```

### 4.3 Verify Installation
```bash
node --version
npm --version
```

## Step 5: Install PM2

PM2 is a process manager for Node.js applications.

```bash
sudo npm install -g pm2
```

## Step 6: Install Nginx

### 6.1 Install Nginx
```bash
sudo apt install nginx -y
```

### 6.2 Start and Enable Nginx
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 6.3 Verify Installation
```bash
sudo systemctl status nginx
```

## Step 7: Deploy Application

### 7.1 Clone Repository
```bash
git clone https://github.com/M-K-World-Wide/Home.git
cd Home
```

### 7.2 Install Dependencies
```bash
npm install
```

### 7.3 Build Application
```bash
npm run build
```

### 7.4 Start with PM2
```bash
pm2 start npm --name "mkww-website" -- start
pm2 startup
pm2 save
```

## Step 8: Configure Nginx

### 8.1 Create Nginx Configuration
```bash
sudo nano /etc/nginx/sites-available/mkww-website
```

Add the following configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 8.2 Enable Site
```bash
sudo ln -s /etc/nginx/sites-available/mkww-website /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

### 8.3 Test and Restart Nginx
```bash
sudo nginx -t
sudo systemctl restart nginx
```

## Step 9: SSL Certificate (Optional)

### 9.1 Install Certbot
```bash
sudo apt install certbot python3-certbot-nginx -y
```

### 9.2 Get SSL Certificate
```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

### 9.3 Set Up Auto-renewal
```bash
sudo crontab -e
```

Add this line:
```
0 12 * * * /usr/bin/certbot renew --quiet
```

## Step 10: Monitoring and Maintenance

### 10.1 PM2 Commands
```bash
pm2 status              # Check application status
pm2 logs mkww-website   # View logs
pm2 restart mkww-website # Restart application
pm2 stop mkww-website   # Stop application
pm2 delete mkww-website # Remove application
```

### 10.2 Nginx Commands
```bash
sudo nginx -t           # Test configuration
sudo systemctl status nginx  # Check status
sudo systemctl restart nginx # Restart nginx
sudo systemctl reload nginx  # Reload configuration
```

### 10.3 Log Files
```bash
# PM2 logs
pm2 logs mkww-website

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# System logs
sudo journalctl -u nginx
```

## Step 11: Automated Deployment

### 11.1 Using Deployment Script
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### 11.2 Using SSL Setup Script
```bash
chmod +x scripts/ssl-setup.sh
./scripts/ssl-setup.sh your-domain.com
```

## Troubleshooting

### Common Issues

1. **Application not accessible**
   - Check if PM2 is running: `pm2 status`
   - Check if Nginx is running: `sudo systemctl status nginx`
   - Check security group settings

2. **502 Bad Gateway**
   - Check application logs: `pm2 logs mkww-website`
   - Verify proxy_pass configuration
   - Check if application is listening on port 3000

3. **SSL Certificate Issues**
   - Check domain DNS settings
   - Verify Certbot installation
   - Check certificate status: `sudo certbot certificates`

4. **Performance Issues**
   - Monitor system resources: `htop`
   - Check PM2 memory usage: `pm2 monit`
   - Optimize Nginx configuration

### Performance Optimization

1. **Enable Gzip Compression**
2. **Configure Browser Caching**
3. **Use CDN for Static Assets**
4. **Optimize Images**
5. **Enable HTTP/2**

## Security Best Practices

1. **Keep System Updated**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Configure Firewall**
   ```bash
   sudo ufw enable
   sudo ufw allow ssh
   sudo ufw allow 'Nginx Full'
   ```

3. **Use SSH Keys Only**
   ```bash
   sudo nano /etc/ssh/sshd_config
   # Set PasswordAuthentication no
   ```

4. **Regular Backups**
   ```bash
   # Backup application
   tar -czf mkww-website-backup.tar.gz /var/www/mkww-website
   
   # Backup Nginx configuration
   sudo tar -czf nginx-config-backup.tar.gz /etc/nginx
   ```

## Cost Optimization

1. **Use Reserved Instances** for long-term deployments
2. **Monitor Usage** with AWS CloudWatch
3. **Use Spot Instances** for development/testing
4. **Optimize Instance Size** based on actual usage

## Next Steps

1. Set up monitoring with AWS CloudWatch
2. Configure automated backups
3. Set up CI/CD pipeline
4. Implement load balancing for high availability
5. Set up CDN for global performance 