# Interactive Ubuntu VPS Setup Script

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A comprehensive, interactive Bash script for quickly setting up an Ubuntu VPS for web backend API and frontend deployment. This script automates the installation and configuration of essential components needed for a production-ready web server environment.

## 🚀 Features

- **Fully Interactive**: Prompts for all configuration options with sensible defaults
- **Customizable Stack**: Choose your preferred database, web server, and additional components
- **Multiple Node.js Versions**: Support for multiple Node.js LTS versions
- **Database Options**: PostgreSQL, MySQL/MariaDB, or MongoDB
- **Web Server Options**: Nginx or Apache with automatic configuration
- **Additional Components**: Docker, Redis, Let's Encrypt SSL, and Fail2ban
- **Color-Coded Output**: Clear, readable terminal output with status indicators
- **Comprehensive Configuration**: Sets up application user, directories, services, and firewall
- **PM2 Process Manager**: Configures PM2 for Node.js application management and persistence
- **Security Focused**: Implements basic security measures and provides options for additional security

## 📋 Requirements

- Ubuntu 20.04, 22.04, or 24.04 server (minimal installation)
- Root access or sudo privileges
- Internet connection to download packages
- A registered domain name (for SSL configuration)

## 🔧 Installation

Clone this repository or download the script:

```bash
# Clone the repository
git clone https://github.com/AmirHosseinMoloudi/ubuntu-stack-ignition.git
cd ubuntu-vps-setup

# Make the script executable
chmod +x setup.sh

# Run with sudo
sudo ./setup.sh
```

Alternatively, download and run directly:

```bash
wget https://raw.githubusercontent.com/AmirHosseinMoloudi/ubuntu-stack-ignition/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

## 📘 Usage

Simply run the script and follow the interactive prompts:

```bash
sudo ./setup.sh
```

The script will guide you through the following configuration options:

1. Application username
2. Application directory
3. Domain name
4. Node.js version
5. Database type
6. Web server
7. Additional components

After confirming your selections, the script will perform all installations and configurations automatically.

## ⚙️ Configuration Options

### Application User

Creates a dedicated system user for your application. This enhances security by isolating application processes.

- Default: `app`

### Application Directory

The directory where your application will be deployed.

- Default: `/var/www/[app_user]`

### Domain Name

Your website's domain name, used for web server configuration and SSL certificates.

- Example: `example.com`

### Node.js Version

Select from supported Node.js versions:

- **16.x**: Maintenance LTS
- **18.x**: Active LTS (Default)
- **20.x**: Active LTS
- **21.x**: Current

### Database Options

- **PostgreSQL**: Open-source relational database (Default)
- **MySQL/MariaDB**: Popular open-source relational database
- **MongoDB**: NoSQL document database (installed via Docker on Ubuntu 24.04)
- **None**: Skip database installation

### Web Server Options

- **Nginx**: High-performance web server and reverse proxy (Default)
- **Apache**: Traditional web server with extensive features

### Additional Components

- **Docker and Docker Compose**: Container platform for application isolation
- **Redis**: In-memory data structure store, used for caching and as a message broker
- **Let's Encrypt SSL**: Free, automated SSL certificates
- **Fail2ban**: Intrusion prevention framework

## 🔍 What Gets Installed

Depending on your selections, the script installs and configures:

### Base System

- Essential build tools and utilities
- Git, curl, wget, vim
- Application user and directory structure

### Node.js Environment

- Selected Node.js version
- NPM
- PM2 process manager (configured to start on boot)

### Database (Based on Selection)

- **PostgreSQL**: Configuration includes creating a database and user
- **MySQL/MariaDB**: Includes secure installation and user setup
- **MongoDB**: Via Docker on Ubuntu 24.04, or direct installation on other versions

### Web Server (Based on Selection)

- **Nginx**: Configured as reverse proxy for Node.js applications
- **Apache**: Configured with necessary modules and proxy settings

### Additional Components (If Selected)

- **Docker**: Latest version with Docker Compose
- **Redis**: In-memory database
- **Let's Encrypt SSL**: With auto-renewal cron job
- **Fail2ban**: Basic configuration for SSH protection

### Firewall Configuration

- UFW (Uncomplicated Firewall) with appropriate rules
- Optional activation (safety prompt to prevent SSH lockout)

## 🛠 Deployment

The script creates a sample deployment script (`deploy.sh`) in your application directory:

```bash
/var/www/[app_user]/deploy.sh
```

It includes basic deployment steps:

- Pull latest code changes
- Install dependencies
- Build the application
- Restart the PM2 processes

## 🔒 Security Considerations

This script implements several security best practices:

- **Dedicated Application User**: Runs applications with limited privileges
- **Firewall Configuration**: Restricts access to necessary services only
- **Fail2ban (Optional)**: Protects against brute force attacks
- **SSL Certificates (Optional)**: Enables HTTPS for encrypted connections
- **Secure Database Setup**: Creates limited-privilege database users

For production environments, consider these additional security measures:

- Configure SSH to use key-based authentication and disable password login
- Implement more restrictive firewall rules
- Set up regular security updates with unattended-upgrades
- Implement database backups
- Configure log rotation and monitoring

## ⚠️ Troubleshooting

### MongoDB Installation on Ubuntu 24.04

MongoDB doesn't have official packages for Ubuntu 24.04 yet. The script handles this by:

1. Using Docker if selected (recommended)
2. Using Ubuntu 22.04 (Jammy) repositories with compatibility tweaks

### Connection Problems After Firewall Activation

If you lose SSH connection after enabling UFW:

1. Restart your server from your provider's control panel
2. Connect via SSH and run: `sudo ufw allow OpenSSH`
3. Then: `sudo ufw enable`

### Node.js Installation Issues

If Node.js installation fails:

1. Check the Nodesource repository status
2. Try installing manually:
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

### Let's Encrypt Rate Limits

Let's Encrypt has rate limits for certificate issuance. If you hit these limits:

1. Use the staging environment for testing
2. Wait before requesting new certificates
3. Check domain validation issues

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🙏 Acknowledgements

- [Node.js](https://nodejs.org/)
- [PM2](https://pm2.keymetrics.io/)
- [Nginx](https://nginx.org/)
- [Apache](https://httpd.apache.org/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Docker](https://www.docker.com/)
- [PostgreSQL](https://www.postgresql.org/)
- [MySQL](https://www.mysql.com/)
- [MongoDB](https://www.mongodb.com/)
- [Redis](https://redis.io/)
- [Fail2ban](https://www.fail2ban.org/)
