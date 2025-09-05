#!/bin/bash

# AWS EC2 Setup Script for CampsHub360
# This script sets up the complete AWS infrastructure for the project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if running on EC2
if ! curl -s http://169.254.169.254/latest/meta-data/instance-id > /dev/null 2>&1; then
    print_error "This script must be run on an AWS EC2 instance"
    exit 1
fi

print_header "AWS EC2 Setup for CampsHub360"

# Get EC2 instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

print_status "Instance ID: $INSTANCE_ID"
print_status "Public IP: $PUBLIC_IP"
print_status "Private IP: $PRIVATE_IP"
print_status "Region: $REGION"

# Update system
print_header "Updating System"
sudo apt update && sudo apt upgrade -y

# Install required packages
print_header "Installing Required Packages"
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    postgresql-client \
    nginx \
    redis-tools \
    build-essential \
    libpq-dev \
    libssl-dev \
    libffi-dev \
    certbot \
    python3-certbot-nginx \
    htop \
    curl \
    wget \
    git \
    unzip \
    awscli

# Install AWS CLI v2 if not present
if ! command -v aws &> /dev/null; then
    print_status "Installing AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Configure AWS CLI (user needs to run this manually)
print_warning "Please configure AWS CLI with your credentials:"
print_warning "Run: aws configure"
print_warning "You'll need:"
print_warning "  - AWS Access Key ID"
print_warning "  - AWS Secret Access Key"
print_warning "  - Default region (e.g., $REGION)"
print_warning "  - Default output format (json)"

# Create system user for the application
print_header "Creating Application User"
if ! id "campshub360" &>/dev/null; then
    sudo useradd -r -s /bin/false -d /app campshub360
    print_status "Created campshub360 user"
else
    print_status "campshub360 user already exists"
fi

# Create application directory
print_header "Setting Up Application Directory"
sudo mkdir -p /app
sudo chown campshub360:campshub360 /app

# Create log directories
sudo mkdir -p /var/log/django
sudo mkdir -p /var/log/nginx
sudo chown www-data:www-data /var/log/django
sudo chown www-data:www-data /var/log/nginx

# Configure firewall
print_header "Configuring Firewall"
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5432/tcp  # PostgreSQL (if using local DB)
sudo ufw allow 6379/tcp  # Redis (if using local Redis)

# Configure logrotate
print_header "Setting Up Log Rotation"
sudo tee /etc/logrotate.d/campshub360 > /dev/null << EOF
/var/log/django/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload campshub360
    endscript
}

/var/log/nginx/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload nginx
    endscript
}
EOF

# Create backup script
print_header "Creating Backup Script"
sudo tee /usr/local/bin/backup_campshub360.sh > /dev/null << 'EOF'
#!/bin/bash
# Backup script for CampsHub360

APP_DIR="/app"
BACKUP_DIR="/app/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="campshub360_backup_$DATE"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Database backup (if using local PostgreSQL)
if systemctl is-active --quiet postgresql; then
    echo "Backing up database..."
    sudo -u postgres pg_dump campshub360_prod > "$BACKUP_DIR/${BACKUP_NAME}_db.sql"
fi

# Application backup
echo "Backing up application..."
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_app.tar.gz" \
    --exclude="$APP_DIR/backups" \
    --exclude="$APP_DIR/venv" \
    --exclude="$APP_DIR/.git" \
    --exclude="$APP_DIR/staticfiles" \
    --exclude="$APP_DIR/__pycache__" \
    --exclude="$APP_DIR/*/__pycache__" \
    -C "$APP_DIR" .

# Clean up old backups (keep last 7 days)
find "$BACKUP_DIR" -name "campshub360_backup_*" -mtime +7 -delete

echo "Backup completed: $BACKUP_NAME"
EOF

sudo chmod +x /usr/local/bin/backup_campshub360.sh

# Set up cron job for backups
print_header "Setting Up Automated Backups"
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup_campshub360.sh") | crontab -

# Create monitoring script
print_header "Creating Monitoring Script"
sudo tee /usr/local/bin/monitor_campshub360.sh > /dev/null << 'EOF'
#!/bin/bash
# Monitoring script for CampsHub360

# Check if services are running
check_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo "✓ $service is running"
    else
        echo "✗ $service is not running"
        systemctl restart "$service"
    fi
}

# Check disk space
check_disk_space() {
    local usage=$(df /app | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$usage" -gt 80 ]; then
        echo "⚠ Disk usage is high: ${usage}%"
        # Clean up old logs
        sudo journalctl --vacuum-time=7d
        sudo find /app/backups -name "*.tar.gz" -mtime +7 -delete
    else
        echo "✓ Disk usage is normal: ${usage}%"
    fi
}

# Check memory usage
check_memory() {
    local usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$usage" -gt 80 ]; then
        echo "⚠ Memory usage is high: ${usage}%"
    else
        echo "✓ Memory usage is normal: ${usage}%"
    fi
}

echo "=== CampsHub360 Health Check $(date) ==="
check_service "campshub360"
check_service "nginx"
check_disk_space
check_memory
echo "=========================================="
EOF

sudo chmod +x /usr/local/bin/monitor_campshub360.sh

# Set up monitoring cron job
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor_campshub360.sh >> /var/log/campshub360_monitor.log 2>&1") | crontab -

print_header "Setup Complete!"

print_status "Next steps:"
print_status "1. Configure AWS CLI: aws configure"
print_status "2. Set up RDS PostgreSQL database"
print_status "3. Set up ElastiCache Redis cluster"
print_status "4. Configure domain name and SSL certificates"
print_status "5. Update .env file with production values"
print_status "6. Run deployment script: sudo ./deploy.sh"

print_warning "Important security notes:"
print_warning "- Change default admin password after deployment"
print_warning "- Configure proper security groups in AWS"
print_warning "- Set up CloudWatch monitoring"
print_warning "- Enable AWS Config for compliance monitoring"

echo -e "${GREEN}AWS EC2 setup completed successfully!${NC}"
