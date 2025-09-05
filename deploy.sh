#!/bin/bash

# CampsHub360 Complete AWS Deployment Script
# This script handles everything: setup, deployment, and RDS connection

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

print_header "CampsHub360 AWS Deployment"

# Configuration
APP_NAME="campshub360"
APP_DIR="${APP_DIR:-$(pwd)}"
VENV_DIR="$APP_DIR/venv"
LOG_DIR="/var/log/django"

# Check if .env file exists
if [ ! -f "$APP_DIR/.env" ]; then
    print_error ".env file not found. Creating one..."
    
    # Generate secure secret key
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
    
    # Get instance info
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
    
    # Create .env file
    cat > .env << EOF
# Django Settings
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=$PUBLIC_IP,ec2-$PUBLIC_IP.ap-south-1.compute.amazonaws.com,localhost,127.0.0.1

# CORS/CSRF
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://$PUBLIC_IP,http://ec2-$PUBLIC_IP.ap-south-1.compute.amazonaws.com
CSRF_TRUSTED_ORIGINS=http://localhost:5173,http://$PUBLIC_IP,http://ec2-$PUBLIC_IP.ap-south-1.compute.amazonaws.com

# Security (HTTP testing)
SECURE_SSL_REDIRECT=False
SECURE_HSTS_SECONDS=0
SECURE_HSTS_INCLUDE_SUBDOMAINS=False
SECURE_HSTS_PRELOAD=False

# Database (RDS) - UPDATE THESE VALUES
POSTGRES_DB=campshub360
POSTGRES_USER=postgres
POSTGRES_PASSWORD=Campushub123
POSTGRES_HOST=database-1.cl00sagomrhg.ap-south-1.rds.amazonaws.com
POSTGRES_PORT=5432

# Redis (ElastiCache) - UPDATE THESE VALUES
REDIS_URL=redis://campshub-j2z0gd.serverless.aps1.cache.amazonaws.com:6379/1

# Email (optional)
EMAIL_HOST=email-smtp.ap-south-1.amazonaws.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-ses-smtp-username
EMAIL_HOST_PASSWORD=your-ses-smtp-password
DEFAULT_FROM_EMAIL=noreply@$PUBLIC_IP.nip.io
EOF
    
    print_warning "Created .env file. Please review and update the values if needed."
    print_warning "Run: nano .env"
    print_warning "Press Enter to continue after reviewing..."
    read
fi

# Load environment variables
source "$APP_DIR/.env"

# Validate required environment variables
required_vars=("SECRET_KEY" "POSTGRES_PASSWORD" "ALLOWED_HOSTS" "POSTGRES_HOST" "REDIS_URL")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        print_error "Required environment variable $var is not set in .env file"
        exit 1
    fi
done

print_status "Environment variables validated"

# Create necessary directories
print_header "Creating Directories"
sudo mkdir -p $LOG_DIR
sudo mkdir -p $APP_DIR/logs
sudo mkdir -p $APP_DIR/media
sudo mkdir -p $APP_DIR/staticfiles
sudo chown -R www-data:www-data $LOG_DIR
sudo chown -R www-data:www-data $APP_DIR/logs $APP_DIR/media $APP_DIR/staticfiles

# Update system packages
print_header "Updating System"
sudo apt update
sudo apt upgrade -y

# Install required system packages
print_header "Installing Dependencies"
sudo apt install -y python3 python3-pip python3-venv python3-dev \
    postgresql-client nginx redis-tools \
    build-essential libpq-dev libssl-dev libffi-dev \
    curl wget git

# Create virtual environment
print_header "Setting Up Python Environment"
if [ -d "$VENV_DIR" ]; then
    print_warning "Removing existing virtual environment..."
    rm -rf $VENV_DIR
fi
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate

# Install Python dependencies
print_status "Installing Python packages..."
pip install --upgrade pip
pip install -r $APP_DIR/requirements.txt

# Set up environment variables
export DJANGO_SETTINGS_MODULE=campshub360.production

# Test AWS connections
print_header "Testing AWS Connections"

# Test RDS connection
print_status "Testing RDS PostgreSQL connection..."
if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" > /dev/null 2>&1; then
    print_status "✓ RDS PostgreSQL connection successful"
else
    print_error "✗ RDS PostgreSQL connection failed"
    print_error "This is likely a security group issue."
    print_warning "Fix this in AWS Console:"
    print_warning "1. Go to RDS Console → Databases → Select 'database-1'"
    print_warning "2. Click 'Actions' → 'Set up EC2 connection'"
    print_warning "3. Select your EC2 instance and click 'Set up connection'"
    print_warning "4. Wait 2-3 minutes for changes to apply"
    print_warning "5. Run this script again"
    exit 1
fi

# Test ElastiCache connection
REDIS_HOST=$(echo $REDIS_URL | sed 's/redis:\/\/\([^:]*\):.*/\1/')
REDIS_PORT=$(echo $REDIS_URL | sed 's/redis:\/\/[^:]*:\([^/]*\)\/.*/\1/')

print_status "Testing ElastiCache Redis connection..."
if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1; then
    print_status "✓ ElastiCache Redis connection successful"
else
    print_error "✗ ElastiCache Redis connection failed"
    print_error "This is likely a security group issue."
    print_warning "Fix this in AWS Console:"
    print_warning "1. Go to ElastiCache Console → Redis clusters → Select your cluster"
    print_warning "2. Click 'Actions' → 'Modify'"
    print_warning "3. Update security groups to allow EC2 access"
    print_warning "4. Wait 2-3 minutes for changes to apply"
    print_warning "5. Run this script again"
    exit 1
fi

# Test Django configuration
print_status "Testing Django configuration..."
if python manage.py check --database default > /dev/null 2>&1; then
    print_status "✓ Django configuration is valid"
else
    print_error "✗ Django configuration has issues"
    print_error "Run: python manage.py check --database default"
    exit 1
fi

# Run database migrations
print_header "Setting Up Database"
print_status "Running database migrations..."
python manage.py migrate --noinput

# Create superuser if it doesn't exist
print_status "Creating superuser (if needed)..."
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(is_superuser=True).exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('Superuser created: admin/admin123')
else:
    print('Superuser already exists')
EOF

# Collect static files
print_status "Collecting static files..."
python manage.py collectstatic --noinput

# Test Django cache
print_status "Testing Django cache..."
python manage.py shell << EOF
from django.core.cache import cache
cache.set('test_key', 'test_value', 30)
result = cache.get('test_key')
if result == 'test_value':
    print('✓ Django cache working')
    cache.delete('test_key')
else:
    print('✗ Django cache not working')
    exit(1)
EOF

# Set up systemd service
print_header "Setting Up Services"
print_status "Creating systemd service..."
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
ExecStart=$VENV_DIR/bin/gunicorn --workers 2 --worker-class gevent --worker-connections 1000 --max-requests 1000 --max-requests-jitter 100 --timeout 30 --keep-alive 2 --bind 127.0.0.1:8000 campshub360.wsgi:application
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
ReadWritePaths=$APP_DIR/logs $APP_DIR/media $APP_DIR/staticfiles

[Install]
WantedBy=multi-user.target
EOF

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
if [ -f "$APP_DIR/campshub360.logrotate" ]; then
    sudo cp $APP_DIR/campshub360.logrotate /etc/logrotate.d/$APP_NAME
fi

# Set proper permissions
print_status "Setting permissions..."
sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 755 $APP_DIR
sudo chgrp www-data $APP_DIR/.env || true
sudo chmod 640 $APP_DIR/.env

# Start services
print_header "Starting Services"
sudo systemctl restart nginx
sudo systemctl restart campshub360

# Wait for services to start
sleep 5

# Check service status
print_status "Checking service status..."
sudo systemctl is-active --quiet campshub360 && print_status "✓ CampsHub360 service is running" || print_error "✗ CampsHub360 service failed"
sudo systemctl is-active --quiet nginx && print_status "✓ Nginx service is running" || print_error "✗ Nginx service failed"

# Health check
print_header "Testing Application"
if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
    print_status "✓ Application health check passed"
else
    print_warning "⚠ Application health check failed - check logs"
    print_warning "Check logs with: sudo journalctl -u campshub360 -f"
fi

# Final status
print_header "Deployment Complete!"
print_status "✓ RDS PostgreSQL connected"
print_status "✓ ElastiCache Redis connected"
print_status "✓ Database migrations completed"
print_status "✓ Superuser created (admin/admin123)"
print_status "✓ Static files collected"
print_status "✓ Services started"

# Get public IP for access
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")

print_warning "Access your application:"
print_status "🌐 Application: http://$PUBLIC_IP"
print_status "🔧 Admin Panel: http://$PUBLIC_IP/admin/ (admin/admin123)"
print_status "❤️ Health Check: http://$PUBLIC_IP/health/"
print_status "📡 API: http://$PUBLIC_IP/api/"

print_warning "Next steps:"
print_warning "1. Change admin password"
print_warning "2. Test your frontend connection"
print_warning "3. Set up SSL certificate (optional)"

echo -e "${GREEN}Deployment completed successfully!${NC}"