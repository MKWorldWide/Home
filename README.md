<div align="center">
  <h1>MK Worldwide</h1>
  <p>Modern web presence for MK Worldwide - Built with React, TypeScript, and AWS Amplify</p>
  
  [![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
  [![CI](https://github.com/MKWorldWide/Home/actions/workflows/ci.yml/badge.svg)](https://github.com/MKWorldWide/Home/actions/workflows/ci.yml)
  [![GitHub Pages](https://github.com/MKWorldWide/Home/actions/workflows/gh-pages.yml/badge.svg)](https://github.com/MKWorldWide/Home/actions/workflows/gh-pages.yml)
  [![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg?style=flat)](https://github.com/prettier/prettier)
  [![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=flat&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
  [![React](https://img.shields.io/badge/React-20232A?style=flat&logo=react&logoColor=61DAFB)](https://reactjs.org/)
  [![Vite](https://img.shields.io/badge/Vite-B73BFE?style=flat&logo=vite&logoColor=FFD62E)](https://vitejs.dev/)
  [![AWS](https://img.shields.io/badge/AWS-FF9900?style=flat&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
</div>

## 🌟 Features

- ⚡ **Blazing Fast** - Built with Vite for lightning-fast development and production builds
- 🎨 **Modern UI** - Beautiful, responsive design with Tailwind CSS and Framer Motion
- 🛠 **Type Safe** - Full TypeScript support for better developer experience
- ☁️ **Cloud Ready** - Seamless AWS Amplify integration
- 📱 **Fully Responsive** - Works on all devices and screen sizes
- 🔄 **CI/CD** - Automated testing and deployment with GitHub Actions
- 📚 **Documentation** - Comprehensive docs with MkDocs Material

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ (LTS recommended)
- npm 9+ or pnpm 8+ or yarn 1.22+
- Git

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/MKWorldWide/Home.git
   cd Home
   ```

2. **Install dependencies**
   ```bash
   # Using npm
   npm install
   
   # Using pnpm
   pnpm install
   
   # Using yarn
   yarn
   ```

3. **Start the development server**
   ```bash
   npm run dev
   ```
   Open [http://localhost:5173](http://localhost:5173) in your browser.

4. **Build for production**
   ```bash
   npm run build
   ```
   The built files will be in the `dist` directory.

## 🧪 Testing

Run the test suite:

```bash
npm test
```

Run tests in watch mode:

```bash
npm test -- --watch
```

## 🛠️ Scripts

- `dev` - Start development server
- `build` - Build for production
- `preview` - Preview production build locally
- `test` - Run tests
- `lint` - Run ESLint
- `type-check` - Run TypeScript type checking

## 🏗 Project Structure

```
.
├── .github/                # GitHub configurations
│   └── workflows/          # GitHub Actions workflows
├── public/                 # Static files
├── src/
│   ├── assets/             # Images, fonts, etc.
│   ├── components/         # Reusable components
│   ├── hooks/              # Custom React hooks
│   ├── pages/              # Page components
│   ├── styles/             # Global styles
│   ├── types/              # TypeScript type definitions
│   ├── utils/              # Utility functions
│   ├── App.tsx             # Main App component
│   └── main.tsx            # Application entry point
├── .editorconfig           # Editor configuration
├── .eslintrc.cjs           # ESLint configuration
├── .gitignore              # Git ignore file
├── index.html              # HTML entry point
├── package.json            # Project manifest
├── tsconfig.json           # TypeScript configuration
└── vite.config.ts          # Vite configuration
```

## 🌍 Deployment

### AWS Amplify

1. Push your code to your GitHub repository
2. Sign in to the [AWS Management Console](https://console.aws.amazon.com/)
3. Open the [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
4. Choose **New app** > **Host web app**
5. Select your repository and branch
6. Configure build settings (if needed) and choose **Next**
7. Review and choose **Save and deploy**

### AWS EC2

#### Prerequisites
- AWS Account with EC2 access
- EC2 instance running Ubuntu 20.04+ or Amazon Linux 2
- Domain name (optional but recommended)

#### Deployment Steps

1. **Launch EC2 Instance**
   - Choose Ubuntu 20.04 LTS or Amazon Linux 2
   - Instance type: t2.micro (free tier) or t3.small for production
   - Configure Security Group:
     - HTTP (80)
     - HTTPS (443)
     - SSH (22)
     - Custom TCP (3000) for development

2. **Connect to EC2 Instance**
```bash
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

3. **Install Dependencies**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 for process management
sudo npm install -g pm2

# Install Nginx
sudo apt install nginx -y
```

4. **Deploy Application**
```bash
# Clone repository
git clone https://github.com/M-K-World-Wide/Home.git
cd Home

# Install dependencies
npm install

# Build application
npm run build

# Start with PM2
pm2 start npm --name "mkww-website" -- start
pm2 startup
pm2 save
```

5. **Configure Nginx**
```bash
sudo nano /etc/nginx/sites-available/mkww-website
```

Add the following configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

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

6. **Enable Site and Restart Nginx**
```bash
sudo ln -s /etc/nginx/sites-available/mkww-website /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

7. **SSL Certificate (Optional but Recommended)**
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

## Project Structure

```
├── src/
│   ├── components/     # Reusable components
│   ├── pages/         # Page components
│   ├── styles/        # Global styles
│   ├── config/        # Configuration files
│   ├── services/      # Service modules
│   └── App.tsx        # Main application component
├── public/            # Static assets
├── dist/              # Build output
├── scripts/           # Deployment scripts
├── docs/              # Documentation
└── package.json       # Dependencies and scripts
```

## Technologies Used

- **Frontend**: React 18, TypeScript, Tailwind CSS
- **Build Tool**: Vite
- **Animations**: Framer Motion
- **Cloud**: AWS Amplify, AWS EC2
- **Process Manager**: PM2
- **Web Server**: Nginx
- **SSL**: Let's Encrypt (Certbot)

## Development Scripts

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run preview      # Preview production build
npm run lint         # Run ESLint
```

## Environment Variables

Create a `.env` file in the root directory:

```env
VITE_API_URL=your-api-url
VITE_AWS_REGION=your-aws-region
VITE_USER_POOL_ID=your-user-pool-id
VITE_USER_POOL_WEB_CLIENT_ID=your-client-id
```

## Deployment Scripts

### Automated Deployment

Use the provided deployment script:

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Manual Deployment

1. Build the application
2. Upload to EC2
3. Configure Nginx
4. Start with PM2

## Monitoring and Maintenance

### PM2 Commands
```bash
pm2 status              # Check application status
pm2 logs mkww-website   # View logs
pm2 restart mkww-website # Restart application
pm2 stop mkww-website   # Stop application
```

### Nginx Commands
```bash
sudo nginx -t           # Test configuration
sudo systemctl status nginx  # Check status
sudo systemctl restart nginx # Restart nginx
```

## Troubleshooting

### Common Issues

1. **Port 3000 not accessible**
   - Check security group settings
   - Verify PM2 is running: `pm2 status`

2. **Nginx 502 Bad Gateway**
   - Check if application is running: `pm2 logs`
   - Verify proxy_pass configuration

3. **SSL Certificate Issues**
   - Check domain DNS settings
   - Verify Certbot installation

### Log Locations
- PM2 logs: `pm2 logs mkww-website`
- Nginx logs: `/var/log/nginx/error.log`
- Application logs: `pm2 logs`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

Apache-2.0

## Support

For support and questions:
- Create an issue on GitHub
- Contact the development team
- Check the documentation in `/docs`
