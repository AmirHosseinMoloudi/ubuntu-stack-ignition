#!/bin/bash

# Interactive Ubuntu VPS Setup Script for Web Backend API and Frontend Deployment
# This script sets up an Ubuntu server with necessary components
# Tested on Ubuntu 24.04 (Noble Numbat)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions for formatted output
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root or with sudo privileges"
    exit 1
fi

# OS check
if ! grep -q "Ubuntu" /etc/os-release; then
    error "This script is designed for Ubuntu systems only"
    exit 1
fi

# Banner
echo -e "${BLUE}"
echo "======================================================"
echo "      Interactive Ubuntu VPS Setup Script             "
echo "======================================================"
echo -e "${NC}"

# Prompt for configuration variables
read -p "Enter application username [default: app]: " APP_USER
APP_USER=${APP_USER:-app}

read -p "Enter application directory [default: /var/www/$APP_USER]: " APP_DIR
APP_DIR=${APP_DIR:-/var/www/$APP_USER}

read -p "Enter domain name (e.g., example.com): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    warn "Domain name is required for proper setup"
    read -p "Enter domain name (e.g., example.com): " DOMAIN_NAME
    if [ -z "$DOMAIN_NAME" ]; then
        error "Domain name is required. Exiting."
        exit 1
    fi
fi

# Node.js version selection
echo -e "\nSelect Node.js version:"
echo "1) 16.x (Maintenance LTS)"
echo "2) 18.x (Active LTS)"
echo "3) 20.x (Active LTS)"
echo "4) 21.x (Current)"
read -p "Choose Node.js version [default: 2]: " NODE_CHOICE
case $NODE_CHOICE in
    1) NODE_VERSION="16.x" ;;
    3) NODE_VERSION="20.x" ;;
    4) NODE_VERSION="21.x" ;;
    *) NODE_VERSION="18.x" ;; # Default or invalid choice
esac

# Database selection
echo -e "\nSelect database type:"
echo "1) PostgreSQL"
echo "2) MySQL / MariaDB"
echo "3) MongoDB"
echo "4) None (Skip database installation)"
read -p "Choose database [default: 1]: " DB_CHOICE
case $DB_CHOICE in
    2) DB_TYPE="mysql" ;;
    3) DB_TYPE="mongodb" ;;
    4) DB_TYPE="none" ;;
    *) DB_TYPE="postgresql" ;; # Default or invalid choice
esac

# Web server selection
echo -e "\nSelect web server:"
echo "1) Nginx"
echo "2) Apache"
read -p "Choose web server [default: 1]: " WEB_SERVER_CHOICE
case $WEB_SERVER_CHOICE in
    2) WEB_SERVER="apache" ;;
    *) WEB_SERVER="nginx" ;; # Default or invalid choice
esac

# Additional components
echo -e "\nSelect additional components to install (comma-separated numbers):"
echo "1) Docker and Docker Compose"
echo "2) Redis"
echo "3) Let's Encrypt SSL"
echo "4) Fail2ban (basic security)"
read -p "Enter components [default: none]: " COMPONENTS

# Process component selections
INSTALL_DOCKER=false
INSTALL_REDIS=false
INSTALL_SSL=false
INSTALL_FAIL2BAN=false

if [[ $COMPONENTS == *"1"* ]]; then INSTALL_DOCKER=true; fi
if [[ $COMPONENTS == *"2"* ]]; then INSTALL_REDIS=true; fi
if [[ $COMPONENTS == *"3"* ]]; then INSTALL_SSL=true; fi
if [[ $COMPONENTS == *"4"* ]]; then INSTALL_FAIL2BAN=true; fi

# Summary of selected options
echo -e "\n${BLUE}=== Configuration Summary ===${NC}"
echo "Application User: $APP_USER"
echo "Application Directory: $APP_DIR"
echo "Domain Name: $DOMAIN_NAME"
echo "Node.js Version: $NODE_VERSION"
echo "Database: $DB_TYPE"
echo "Web Server: $WEB_SERVER"
echo "Additional Components:"
if [ "$INSTALL_DOCKER" = true ]; then echo "- Docker"; fi
if [ "$INSTALL_REDIS" = true ]; then echo "- Redis"; fi
if [ "$INSTALL_SSL" = true ]; then echo "- Let's Encrypt SSL"; fi
if [ "$INSTALL_FAIL2BAN" = true ]; then echo "- Fail2ban"; fi

# Confirmation
read -p "Proceed with installation? (y/n): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    error "Installation aborted by user"
    exit 1
fi

# Begin installation
log "Starting installation..."

# Update system
log "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install essential tools
log "Installing essential tools..."
apt-get install -y build-essential git curl wget unzip gnupg2 ca-certificates lsb-release software-properties-common apt-transport-https vim

# Create application user
log "Creating application user..."
if id "$APP_USER" &>/dev/null; then
    warn "User $APP_USER already exists"
else
    useradd -m -s /bin/bash $APP_USER
    log "User $APP_USER created"
fi

# Create application directory
log "Creating application directory..."
mkdir -p $APP_DIR
chown -R $APP_USER:$APP_USER $APP_DIR
log "Directory $APP_DIR created and ownership set to $APP_USER"

# Install Node.js
log "Installing Node.js $NODE_VERSION..."
if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION | bash -
    apt-get install -y nodejs
    log "Node.js $(node -v) installed"
else
    warn "Node.js $(node -v) is already installed"
fi

# Install PM2
log "Installing PM2..."
if ! command -v pm2 &>/dev/null; then
    npm install -g pm2
    log "PM2 installed"
else
    warn "PM2 is already installed"
fi

# Set up PM2 to start on boot
log "Setting up PM2 to start on boot..."
env PATH=$PATH:/usr/bin pm2 startup systemd -u $APP_USER --hp /home/$APP_USER

# Database installation
if [ "$DB_TYPE" = "postgresql" ]; then
    log "Installing PostgreSQL..."
    apt-get install -y postgresql postgresql-contrib
    
    # Setup PostgreSQL user and database
    log "Setting up PostgreSQL user and database..."
    read -s -p "Enter password for PostgreSQL user '$APP_USER': " DB_PASSWORD
    echo ""
    sudo -u postgres psql -c "CREATE ROLE $APP_USER WITH LOGIN ENCRYPTED PASSWORD '$DB_PASSWORD';"
    sudo -u postgres psql -c "CREATE DATABASE ${APP_USER}_db OWNER $APP_USER;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${APP_USER}_db TO $APP_USER;"
    
    log "PostgreSQL installed and configured"
    
elif [ "$DB_TYPE" = "mysql" ]; then
    log "Installing MySQL..."
    apt-get install -y mysql-server
    
    # Secure MySQL installation
    log "Securing MySQL installation..."
    read -s -p "Enter password for MySQL root user: " ROOT_PASSWORD
    echo ""
    
    # Set root password and secure the installation
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$ROOT_PASSWORD';"
    mysql -u root -p"$ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='';"
    mysql -u root -p"$ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -u root -p"$ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS test;"
    mysql -u root -p"$ROOT_PASSWORD" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -u root -p"$ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
    
    # Create MySQL user and database
    read -s -p "Enter password for MySQL user '$APP_USER': " DB_PASSWORD
    echo ""
    mysql -u root -p"$ROOT_PASSWORD" -e "CREATE DATABASE ${APP_USER}_db;"
    mysql -u root -p"$ROOT_PASSWORD" -e "CREATE USER '$APP_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
    mysql -u root -p"$ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON ${APP_USER}_db.* TO '$APP_USER'@'localhost';"
    mysql -u root -p"$ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
    
    log "MySQL installed and configured"
    
elif [ "$DB_TYPE" = "mongodb" ]; then
    log "Installing MongoDB..."
    
    # Check if Docker is available for MongoDB installation
    if [ "$INSTALL_DOCKER" = true ]; then
        log "Installing MongoDB using Docker..."
        
        # Create MongoDB data directory
        mkdir -p /data/db
        chown -R $APP_USER:$APP_USER /data/db
        
        # Create docker-compose file for MongoDB
        cat > $APP_DIR/docker-compose.mongodb.yml <<EOF
version: '3'
services:
  mongodb:
    image: mongo:6.0
    container_name: mongodb
    ports:
      - "27017:27017"
    volumes:
      - /data/db:/data/db
    restart: always
EOF
        
        # Start MongoDB container
        docker-compose -f $APP_DIR/docker-compose.mongodb.yml up -d
        
        log "MongoDB installed via Docker successfully!"
    else
        # Try using the Jammy (Ubuntu 22.04) repository instead
        warn "MongoDB official repository for Ubuntu 24.04 not available yet, using Ubuntu 22.04 (Jammy) repository..."
        
        # Add MongoDB GPG key
        wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-archive-keyring.gpg
        
        # Add MongoDB repository for Ubuntu 22.04 (Jammy)
        echo "deb [signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg arch=amd64,arm64] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
        
        # Force apt to accept the repository despite distribution mismatch
        cat > /etc/apt/apt.conf.d/99force-mongodb <<EOF
Acquire::AllowInsecureRepositories "true";
Acquire::AllowDowngradeToInsecureRepositories "true";
APT::Get::AllowUnauthenticated "true";
EOF
        
        apt-get update
        apt-get install -y mongodb-org
        
        # Remove the temporary configuration after installation
        rm /etc/apt/apt.conf.d/99force-mongodb
        
        # Enable and start MongoDB
        systemctl enable mongod
        systemctl start mongod
        
        log "MongoDB installed and configured"
    fi
fi

# Install Docker if selected
if [ "$INSTALL_DOCKER" = true ]; then
    log "Installing Docker and Docker Compose..."
    if ! command -v docker &>/dev/null; then
        # Install Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Add user to docker group
        usermod -aG docker $APP_USER
        
        # Install Docker Compose v2
        log "Installing Docker Compose v2..."
        mkdir -p /usr/local/lib/docker/cli-plugins
        curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
        chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        
        log "Docker and Docker Compose installed"
    else
        warn "Docker is already installed"
    fi
fi

# Install Redis if selected
if [ "$INSTALL_REDIS" = true ]; then
    log "Installing Redis..."
    apt-get install -y redis-server
    
    # Configure Redis
    sed -i 's/supervised no/supervised systemd/g' /etc/redis/redis.conf
    systemctl restart redis.service
    
    log "Redis installed and configured"
fi

# Install web server
if [ "$WEB_SERVER" = "nginx" ]; then
    log "Installing Nginx..."
    apt-get install -y nginx
    
    # Configure Nginx for the application
    cat > /etc/nginx/sites-available/$DOMAIN_NAME <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
    
    # Enable the site
    ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    nginx -t
    
    # Restart Nginx
    systemctl restart nginx
    
    log "Nginx installed and configured"
    
elif [ "$WEB_SERVER" = "apache" ]; then
    log "Installing Apache..."
    apt-get install -y apache2
    
    # Enable necessary modules
    a2enmod proxy proxy_http rewrite headers
    
    # Configure Apache for the application
    cat > /etc/apache2/sites-available/$DOMAIN_NAME.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@$DOMAIN_NAME
    ServerName $DOMAIN_NAME
    ServerAlias www.$DOMAIN_NAME
    
    ProxyPreserveHost On
    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/
    
    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN_NAME-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN_NAME-access.log combined
</VirtualHost>
EOF
    
    # Enable the site
    a2ensite $DOMAIN_NAME.conf
    a2dissite 000-default.conf
    
    # Restart Apache
    systemctl restart apache2
    
    log "Apache installed and configured"
fi

# Install Let's Encrypt SSL if selected
if [ "$INSTALL_SSL" = true ]; then
    log "Installing Let's Encrypt SSL..."
    
    # Install Certbot
    apt-get install -y certbot
    
    if [ "$WEB_SERVER" = "nginx" ]; then
        apt-get install -y python3-certbot-nginx
        certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME
    elif [ "$WEB_SERVER" = "apache" ]; then
        apt-get install -y python3-certbot-apache
        certbot --apache -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME
    fi
    
    # Set up auto-renewal
    echo "0 3 * * * /usr/bin/certbot renew --quiet" | crontab -
    
    log "Let's Encrypt SSL installed and configured"
fi

# Install Fail2ban if selected
if [ "$INSTALL_FAIL2BAN" = true ]; then
    log "Installing Fail2ban..."
    apt-get install -y fail2ban
    
    # Configure Fail2ban
    cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime  = 10m
findtime  = 10m
maxretry = 5

[sshd]
enabled = true
EOF
    
    # Restart Fail2ban
    systemctl restart fail2ban
    
    log "Fail2ban installed and configured"
fi

# Setup firewall
log "Setting up firewall..."
ufw allow OpenSSH
if [ "$WEB_SERVER" = "nginx" ] || [ "$WEB_SERVER" = "apache" ]; then
    ufw allow 'Nginx Full'
    ufw allow 'Apache Full'
fi

# Ask before enabling firewall
read -p "Enable firewall now? This might disconnect your SSH session if not properly configured. (y/n): " ENABLE_UFW
if [[ $ENABLE_UFW =~ ^[Yy]$ ]]; then
    ufw --force enable
    log "Firewall enabled"
else
    warn "Firewall not enabled. Enable it manually later with 'sudo ufw enable'"
fi

# Create a sample deployment script
log "Creating deployment script..."
cat > $APP_DIR/deploy.sh <<EOF
#!/bin/bash
# Deployment script for $DOMAIN_NAME

# Pull latest changes
git pull

# Install dependencies
npm install

# Build the application
npm run build

# Restart the application
pm2 restart all

echo "Deployment completed!"
EOF

chmod +x $APP_DIR/deploy.sh
chown $APP_USER:$APP_USER $APP_DIR/deploy.sh

# Final steps
log "Creating a sample .env file..."
cat > $APP_DIR/.env.example <<EOF
NODE_ENV=production
PORT=3000
HOST=localhost
EOF

chown $APP_USER:$APP_USER $APP_DIR/.env.example

# Summary
echo -e "\n${GREEN}=== Installation Complete ===${NC}"
echo "Your server is now set up with the following:"
echo "- Application user: $APP_USER"
echo "- Application directory: $APP_DIR"
echo "- Domain: $DOMAIN_NAME"
echo "- Node.js $(node -v)"
echo "- Web Server: $WEB_SERVER"
if [ "$DB_TYPE" != "none" ]; then
    echo "- Database: $DB_TYPE"
fi
if [ "$INSTALL_DOCKER" = true ]; then echo "- Docker"; fi
if [ "$INSTALL_REDIS" = true ]; then echo "- Redis"; fi
if [ "$INSTALL_SSL" = true ]; then echo "- Let's Encrypt SSL"; fi
if [ "$INSTALL_FAIL2BAN" = true ]; then echo "- Fail2ban"; fi

echo -e "\n${BLUE}Next Steps:${NC}"
echo "1. Deploy your application to $APP_DIR"
echo "2. Create a .env file (use .env.example as a template)"
echo "3. Start your application with PM2:"
echo "   cd $APP_DIR && pm2 start app.js --name $DOMAIN_NAME"
echo "4. Save the PM2 process list:"
echo "   pm2 save"

echo -e "\n${GREEN}Thank you for using this setup script!${NC}"

