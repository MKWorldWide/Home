# CI/CD Pipeline Setup Guide

This guide explains how to set up a continuous integration and continuous deployment (CI/CD) pipeline for the MKWW Website.

## Overview

The CI/CD pipeline will automatically:
1. Build the application when code is pushed to GitHub
2. Run tests and linting
3. Deploy to AWS EC2
4. Send notifications on success/failure

## GitHub Actions Setup

### 1. Create GitHub Actions Workflow

Create the file `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS EC2

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run linting
      run: npm run lint
    
    - name: Run tests
      run: npm test
    
    - name: Build application
      run: npm run build

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Build application
      run: npm run build
    
    - name: Deploy to EC2
      uses: appleboy/ssh-action@v0.1.5
      with:
        host: ${{ secrets.EC2_HOST }}
        username: ${{ secrets.EC2_USERNAME }}
        key: ${{ secrets.EC2_SSH_KEY }}
        script: |
          cd /var/www/mkww-website
          git pull origin main
          npm ci
          npm run build
          pm2 restart mkww-website
          sudo systemctl reload nginx
    
    - name: Notify on success
      if: success()
      uses: 8398a7/action-slack@v3
      with:
        status: success
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        text: '✅ MKWW Website deployed successfully!'
    
    - name: Notify on failure
      if: failure()
      uses: 8398a7/action-slack@v3
      with:
        status: failure
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        text: '❌ MKWW Website deployment failed!'
```

### 2. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add the following secrets:

- `EC2_HOST`: Your EC2 instance public IP or domain
- `EC2_USERNAME`: SSH username (usually `ubuntu`)
- `EC2_SSH_KEY`: Your private SSH key
- `SLACK_WEBHOOK`: Slack webhook URL for notifications (optional)

### 3. Generate SSH Key for GitHub Actions

```bash
# Generate a new SSH key pair
ssh-keygen -t rsa -b 4096 -C "github-actions@mkww-website" -f ~/.ssh/github-actions

# Add public key to EC2 instance
ssh-copy-id -i ~/.ssh/github-actions.pub ubuntu@your-ec2-ip

# Copy private key content for GitHub secret
cat ~/.ssh/github-actions
```

## Alternative: AWS CodePipeline

### 1. Create CodeBuild Project

Create `buildspec.yml` in your repository:

```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      nodejs: 18
    commands:
      - echo Installing dependencies...
      - npm ci
  
  pre_build:
    commands:
      - echo Running tests...
      - npm run lint
      - npm test
  
  build:
    commands:
      - echo Building application...
      - npm run build
      - echo Build completed successfully
  
  post_build:
    commands:
      - echo Deploying to EC2...
      - aws s3 sync dist/ s3://your-s3-bucket/
      - aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"

artifacts:
  files:
    - '**/*'
  base-directory: 'dist'
```

### 2. Create CodeDeploy Application

Create `appspec.yml` in your repository:

```yaml
version: 0.0
os: linux

files:
  - source: /
    destination: /var/www/mkww-website

hooks:
  BeforeInstall:
    - location: scripts/before_install.sh
      timeout: 300
      runas: root
  
  AfterInstall:
    - location: scripts/after_install.sh
      timeout: 300
      runas: ubuntu
  
  ApplicationStart:
    - location: scripts/start_application.sh
      timeout: 300
      runas: ubuntu
  
  ApplicationStop:
    - location: scripts/stop_application.sh
      timeout: 300
      runas: ubuntu
```

### 3. Create Deployment Scripts

#### `scripts/before_install.sh`
```bash
#!/bin/bash
# Stop the application
pm2 stop mkww-website || true
pm2 delete mkww-website || true

# Backup current version
if [ -d "/var/www/mkww-website" ]; then
    mv /var/www/mkww-website /var/www/mkww-website.backup.$(date +%Y%m%d_%H%M%S)
fi
```

#### `scripts/after_install.sh`
```bash
#!/bin/bash
cd /var/www/mkww-website

# Install dependencies
npm ci

# Build application
npm run build

# Set proper permissions
sudo chown -R ubuntu:ubuntu /var/www/mkww-website
```

#### `scripts/start_application.sh`
```bash
#!/bin/bash
cd /var/www/mkww-website

# Start application with PM2
pm2 start npm --name "mkww-website" -- start
pm2 save

# Reload Nginx
sudo systemctl reload nginx
```

#### `scripts/stop_application.sh`
```bash
#!/bin/bash
# Stop the application
pm2 stop mkww-website || true
```

## Docker-based Deployment

### 1. Create Dockerfile

```dockerfile
# Build stage
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built application
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

### 2. Create Docker Compose

```yaml
version: '3.8'

services:
  mkww-website:
    build: .
    ports:
      - "80:80"
    restart: unless-stopped
    environment:
      - NODE_ENV=production
```

### 3. Update GitHub Actions for Docker

```yaml
name: Deploy with Docker

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to EC2 with Docker
      uses: appleboy/ssh-action@v0.1.5
      with:
        host: ${{ secrets.EC2_HOST }}
        username: ${{ secrets.EC2_USERNAME }}
        key: ${{ secrets.EC2_SSH_KEY }}
        script: |
          cd /var/www/mkww-website
          git pull origin main
          docker-compose down
          docker-compose build --no-cache
          docker-compose up -d
```

## Monitoring and Alerts

### 1. Set up CloudWatch Alarms

```bash
# Create alarm for high CPU usage
aws cloudwatch put-metric-alarm \
  --alarm-name "MKWW-Website-High-CPU" \
  --alarm-description "High CPU usage on EC2 instance" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:region:account:topic-name
```

### 2. Set up Application Monitoring

```bash
# Install PM2 monitoring
pm2 install pm2-server-monit

# Set up PM2 monitoring dashboard
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
```

## Rollback Strategy

### 1. Automated Rollback

Add to your deployment script:

```bash
#!/bin/bash

# Deploy new version
deploy_new_version() {
    # ... deployment steps
}

# Rollback function
rollback() {
    echo "Rolling back to previous version..."
    cd /var/www/mkww-website
    git reset --hard HEAD~1
    npm ci
    npm run build
    pm2 restart mkww-website
}

# Health check
health_check() {
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)
    if [ $response -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

# Main deployment with rollback
deploy_new_version
sleep 30

if ! health_check; then
    echo "Health check failed, rolling back..."
    rollback
    exit 1
fi

echo "Deployment successful!"
```

### 2. Manual Rollback

```bash
# SSH into EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Rollback to previous version
cd /var/www/mkww-website
git log --oneline -5
git reset --hard <commit-hash>
npm ci
npm run build
pm2 restart mkww-website
```

## Best Practices

1. **Always test in staging environment first**
2. **Use blue-green deployment for zero downtime**
3. **Implement proper logging and monitoring**
4. **Set up automated backups before deployment**
5. **Use environment-specific configurations**
6. **Implement proper error handling and notifications**
7. **Regular security updates and dependency management**

## Troubleshooting

### Common CI/CD Issues

1. **Build failures**
   - Check Node.js version compatibility
   - Verify all dependencies are installed
   - Check for syntax errors in code

2. **Deployment failures**
   - Verify SSH key permissions
   - Check EC2 instance connectivity
   - Review PM2 and Nginx logs

3. **Performance issues**
   - Monitor resource usage during deployment
   - Optimize build process
   - Use caching strategies

### Debug Commands

```bash
# Check GitHub Actions logs
# Go to Actions tab in GitHub repository

# Check EC2 deployment logs
ssh -i your-key.pem ubuntu@your-ec2-ip
pm2 logs mkww-website
sudo journalctl -u nginx -f

# Check application status
pm2 status
sudo systemctl status nginx
``` 