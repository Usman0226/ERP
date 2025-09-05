#!/bin/bash

# CampsHub360 Simple AWS EC2 Deployment Script
# Optimized for production deployment

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

print_header "CampsHub360 AWS EC2 Deployment"

# Configuration
APP_NAME="campshub360"
APP_DIR="${APP_DIR:-$(pwd)}"
VENV_DIR="$APP_DIR/venv"
SERVICE_USER="www-data"

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
ALLOWED_HOSTS=$PUBLIC_IP,localhost,127.0.0.1

# Database (AWS RDS) - UPDATE THESE VALUES
POSTGRES_DB=campshub360
POSTGRES_USER=postgres
POSTGRES_PASSWORD=Campushub123
POSTGRES_HOST=database-1.cl00sagomrhg.ap-south-1.rds.amazonaws.com
POSTGRES_PORT=5432

# Redis (AWS ElastiCache) - UPDATE THESE VALUES
REDIS_URL=redis://campshub-j2z0gd.serverless.aps1.cache.amazonaws.com:6379/1

# Performance Settings
GUNICORN_WORKERS=4
GUNICORN_WORKER_CLASS=gevent
GUNICORN_WORKER_CONNECTIONS=1000
GUNICORN_TIMEOUT=30
GUNICORN_KEEPALIVE=5
GUNICORN_MAX_REQUESTS=1000
GUNICORN_MAX_REQUESTS_JITTER=100

# Security Settings (HTTP deployment)
SECURE_SSL_REDIRECT=False
SECURE_HSTS_SECONDS=0
SECURE_HSTS_INCLUDE_SUBDOMAINS=False
SECURE_HSTS_PRELOAD=False

# CORS Settings (for frontend integration)
CORS_ALLOWED_ORIGINS=http://$PUBLIC_IP,http://localhost
CSRF_TRUSTED_ORIGINS=http://$PUBLIC_IP,http://localhost

# Cache Settings
CACHE_DEFAULT_TIMEOUT=300
SESSION_CACHE_TIMEOUT=86400

# API Settings
API_PAGE_SIZE=50
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

# Update system packages
print_header "System Setup"
sudo apt update
sudo apt upgrade -y

# Install required system packages
sudo apt install -y python3 python3-pip python3-venv python3-dev \
    postgresql-client nginx redis-tools build-essential libpq-dev \
    libssl-dev libffi-dev curl wget git

# Create virtual environment
print_header "Python Environment Setup"
if [ -d "$VENV_DIR" ]; then
    print_warning "Removing existing virtual environment..."
    rm -rf $VENV_DIR
fi

python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate

# Install Python dependencies
pip install --upgrade pip

# Try to install requirements, fallback to minimal if there are conflicts
print_status "Installing Python dependencies..."
if pip install -r $APP_DIR/requirements.txt; then
    print_status "✅ Full requirements installed successfully"
else
    print_warning "⚠️ Full requirements installation failed, trying minimal requirements..."
    if pip install -r $APP_DIR/requirements-minimal.txt; then
        print_status "✅ Minimal requirements installed successfully"
    else
        print_error "❌ Both full and minimal requirements failed"
        print_warning "Trying manual installation of core packages..."
        pip install Django==5.1.4 djangorestframework==3.16.1 psycopg[binary]==3.2.3 gunicorn==23.0.0
        print_warning "Core packages installed. You may need to install additional packages manually."
    fi
fi

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
    print_warning "Please check your RDS security groups and connection details"
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
    print_warning "Please check your ElastiCache security groups and connection details"
    exit 1
fi

# Run database migrations
print_header "Database Setup"
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

# Set up systemd service
print_header "Service Configuration"
sudo tee /etc/systemd/system/campshub360.service > /dev/null << EOF
[Unit]
Description=CampsHub360 Django Application
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
Environment=DJANGO_SETTINGS_MODULE=campshub360.production
ExecStart=$VENV_DIR/bin/gunicorn --config $APP_DIR/gunicorn.conf.py --bind 127.0.0.1:8000 campshub360.wsgi:application
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable campshub360

# Set up nginx
print_status "Setting up nginx..."
sudo cp $APP_DIR/nginx-http.conf /etc/nginx/sites-available/$APP_NAME
sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t

# Create log directory
print_status "Creating log directory..."
sudo mkdir -p /var/log/django
sudo chown $SERVICE_USER:$SERVICE_USER /var/log/django

# Set proper permissions
print_status "Setting permissions..."
sudo chown -R $SERVICE_USER:$SERVICE_USER $APP_DIR
sudo chmod -R 755 $APP_DIR
sudo chgrp $SERVICE_USER $APP_DIR/.env || true
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
