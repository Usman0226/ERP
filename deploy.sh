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
APP_DIR="/app"
VENV_DIR="$APP_DIR/venv"
BACKUP_DIR="/app/backups"
LOG_DIR="/var/log/django"

echo -e "${GREEN}Starting CampsHub360 deployment...${NC}"

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
   print_error "This script should not be run as root"
   exit 1
fi

# Check if .env file exists
if [ ! -f "$APP_DIR/.env" ]; then
    print_error ".env file not found. Please create it from env.production.example"
    exit 1
fi

# Create necessary directories
print_status "Creating necessary directories..."
sudo mkdir -p $LOG_DIR
sudo mkdir -p $BACKUP_DIR
sudo chown -R www-data:www-data $LOG_DIR
sudo chown -R www-data:www-data $BACKUP_DIR

# Backup current deployment
if [ -d "$APP_DIR" ]; then
    print_status "Creating backup of current deployment..."
    BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
    sudo cp -r $APP_DIR $BACKUP_DIR/$BACKUP_NAME
    print_status "Backup created: $BACKUP_DIR/$BACKUP_NAME"
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
sudo cp $APP_DIR/campshub360.service /etc/systemd/system/
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
sudo chmod 600 $APP_DIR/.env

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
python $APP_DIR/manage.py security --validate-env

print_status "Deployment completed successfully!"
print_warning "Please update the following:"
print_warning "1. Update nginx.conf with your domain name"
print_warning "2. Set up SSL certificates"
print_warning "3. Update .env file with production values"
print_warning "4. Change default admin password"
print_warning "5. Configure AWS RDS and ElastiCache"

echo -e "${GREEN}Deployment script finished!${NC}"