#!/bin/bash

# CampsHub360 Production Deployment Script for AWS EC2
# This script automates the deployment process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="campshub360"
# Use provided APP_DIR if set, otherwise default to current working directory
APP_DIR="${APP_DIR:-$(pwd)}"
VENV_DIR="$APP_DIR/venv"
# Keep backups within the app directory to avoid permission/path issues
BACKUP_DIR="$APP_DIR/backups"
LOG_DIR="/var/log/django"

echo -e "${GREEN}Starting CampsHub360 deployment...${NC}"

# Check disk space and clean up if needed
print_status "Checking disk space..."
df -h "$APP_DIR"
AVAILABLE_SPACE=$(df "$APP_DIR" | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt 524288 ]; then  # Less than 512MB
    print_warning "Very low disk space ($(($AVAILABLE_SPACE/1024))MB). Cleaning up..."
    # Clean up package cache
    sudo apt clean
    sudo apt autoremove -y
    # Clean up old logs
    sudo journalctl --vacuum-time=7d 2>/dev/null || true
    # Clean up old backups
    if [ -d "$BACKUP_DIR" ]; then
        sudo find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +3 -delete 2>/dev/null || true
    fi
fi

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_warning "Running as root. Proceed with caution."
fi

# Check if .env file exists; if not, try to create from example
if [ ! -f "$APP_DIR/.env" ]; then
    if [ -f "$APP_DIR/env.production.example" ]; then
        print_warning ".env not found; creating from env.production.example"
        cp "$APP_DIR/env.production.example" "$APP_DIR/.env"
        print_warning "A default .env has been created. Please review and update values."
    else
        print_error ".env file not found and env.production.example is missing."
        exit 1
    fi
fi

# Create necessary directories
print_status "Creating necessary directories..."
sudo mkdir -p $LOG_DIR
sudo mkdir -p $BACKUP_DIR
sudo mkdir -p $APP_DIR/logs
sudo mkdir -p $APP_DIR/media
sudo chown -R www-data:www-data $LOG_DIR
sudo chown -R www-data:www-data $BACKUP_DIR
sudo chown -R www-data:www-data $APP_DIR/logs $APP_DIR/media

# Check disk space before backup
AVAILABLE_SPACE=$(df "$APP_DIR" | awk 'NR==2 {print $4}')
REQUIRED_SPACE=1048576  # 1GB in KB

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    print_warning "Low disk space detected ($(($AVAILABLE_SPACE/1024))MB available). Skipping backup."
    # Clean up old backups to free space
    if [ -d "$BACKUP_DIR" ]; then
        print_status "Cleaning up old backups..."
        sudo find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    fi
else
    # Backup current deployment (archive, excluding transient directories)
    if [ -d "$APP_DIR" ]; then
        print_status "Creating backup of current deployment..."
        BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        # Create a compressed archive of the current app, excluding backups, venv, git and large generated dirs
        if sudo tar \
            --exclude="$APP_DIR/backups" \
            --exclude="$VENV_DIR" \
            --exclude="$APP_DIR/.git" \
            --exclude="$APP_DIR/staticfiles" \
            --exclude="$APP_DIR/__pycache__" \
            --exclude="$APP_DIR/*/__pycache__" \
            -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$APP_DIR" . 2>/dev/null; then
            print_status "Backup created: $BACKUP_DIR/$BACKUP_NAME"
        else
            print_warning "Backup failed (likely due to disk space). Continuing deployment..."
        fi
    fi
fi

# Update system packages
print_status "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install required system packages
print_status "Installing system dependencies..."
sudo apt install -y python3 python3-pip python3-venv python3-dev \
    postgresql-client nginx redis-tools \
    build-essential libpq-dev libssl-dev libffi-dev

# Create virtual environment
print_status "Setting up Python virtual environment..."
if [ -d "$VENV_DIR" ]; then
    rm -rf $VENV_DIR
fi
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate

# Install Python dependencies
print_status "Installing Python dependencies..."
pip install --upgrade pip
pip install -r $APP_DIR/requirements.txt

# Set up environment variables
print_status "Setting up environment variables..."
export DJANGO_SETTINGS_MODULE=campshub360.production

# Run database migrations
print_status "Running database migrations..."
python $APP_DIR/manage.py migrate --noinput

# Collect static files
print_status "Collecting static files..."
python $APP_DIR/manage.py collectstatic --noinput

# Create superuser if it doesn't exist
print_status "Creating superuser (if needed)..."
python $APP_DIR/manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(is_superuser=True).exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('Superuser created: admin/admin123')
else:
    print('Superuser already exists')
EOF

# Set up systemd service
print_status "Setting up systemd service..."
sudo tee /etc/systemd/system/campshub360.service > /dev/null << EOF
[Unit]
Description=CampsHub360 Django Application
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
Environment=DJANGO_SETTINGS_MODULE=campshub360.production
ExecStart=$VENV_DIR/bin/gunicorn --workers 3 --worker-class gevent --worker-connections 1000 --max-requests 1000 --max-requests-jitter 100 --timeout 30 --keep-alive 2 --bind 127.0.0.1:8000 campshub360.wsgi:application
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=campshub360

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR/logs $APP_DIR/media

[Install]
WantedBy=multi-user.target
EOF

# Verify service file was created
if [ ! -f "/etc/systemd/system/campshub360.service" ]; then
    print_error "Failed to create systemd service file"
    exit 1
fi

print_status "Systemd service file created successfully"
sudo systemctl daemon-reload
sudo systemctl enable campshub360

# Set up nginx
print_status "Setting up nginx..."
sudo cp $APP_DIR/nginx.conf /etc/nginx/sites-available/$APP_NAME
sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t

# Set up logrotate
print_status "Setting up log rotation..."
sudo cp $APP_DIR/campshub360.logrotate /etc/logrotate.d/$APP_NAME

# Set proper permissions
print_status "Setting proper permissions..."
sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 755 $APP_DIR
# Allow www-data to read env file referenced by systemd EnvironmentFile
sudo chgrp www-data $APP_DIR/.env || true
sudo chmod 640 $APP_DIR/.env

# Start services
print_status "Starting services..."
sudo systemctl restart nginx
sudo systemctl restart campshub360

# Check service status
print_status "Checking service status..."
sudo systemctl status campshub360 --no-pager
sudo systemctl status nginx --no-pager

# Run security validation
print_status "Running security validation..."
python $APP_DIR/manage.py security --validate-env 2>/dev/null || print_warning "Security validation command not available"

# Health check
print_status "Running health check..."
if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
    print_status "Application health check passed"
else
    print_warning "Application health check failed - check logs"
fi

# Final status check
print_status "Checking service status..."
sudo systemctl is-active --quiet campshub360 && print_status "✓ CampsHub360 service is running" || print_error "✗ CampsHub360 service is not running"
sudo systemctl is-active --quiet nginx && print_status "✓ Nginx service is running" || print_error "✗ Nginx service is not running"

print_status "Deployment completed successfully!"
print_warning "Next steps:"
print_warning "1. Set up database: ./setup_database.sh"
print_warning "2. Set up Redis: ./setup_redis.sh"
print_warning "3. Set up SSL certificates: ./setup_ssl.sh yourdomain.com"
print_warning "4. Change default admin password"
print_warning "5. Configure AWS services (RDS, ElastiCache, SES) if using them"
print_warning "6. Test the application: curl http://localhost:8000/health/"

echo -e "${GREEN}Deployment script finished!${NC}"