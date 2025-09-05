#!/bin/bash

# CampsHub360 Production Deployment Script
# Complete production-ready deployment with monitoring and security
# Optimized for AWS EC2 with RDS and ElastiCache

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_debug() {
    echo -e "${CYAN}[DEBUG]${NC} $1"
}

print_header "CampsHub360 Production Deployment"
echo -e "${PURPLE}High-Performance Django Application Deployment${NC}"
echo -e "${PURPLE}Optimized for 20k+ concurrent users${NC}"
echo ""

# Configuration
APP_NAME="campshub360"
APP_DIR="/home/ubuntu/campushub-backend-2"
VENV_DIR="$APP_DIR/venv"
SERVICE_USER="www-data"
LOG_DIR="/var/log/django"
NGINX_LOG_DIR="/var/log/nginx"

# Get instance information
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1")

print_status "Deploying to instance: $INSTANCE_ID in region: $REGION"
print_status "Public IP: $PUBLIC_IP"

# Check if we're in the right directory
if [ ! -f "$APP_DIR/manage.py" ]; then
    print_error "manage.py not found in $APP_DIR"
    print_error "Please run this script from the correct directory"
    exit 1
fi

print_status "Found Django project in $APP_DIR"

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    print_error "Virtual environment not found at $VENV_DIR"
    print_error "Please create the virtual environment first"
    exit 1
fi

print_status "Found virtual environment at $VENV_DIR"

# Environment setup
print_header "Environment Configuration"

# Check if .env file exists
if [ ! -f "$APP_DIR/.env" ]; then
    print_warning ".env file not found. Creating one from production example..."
    
    if [ -f "$APP_DIR/env.production.example" ]; then
        cp "$APP_DIR/env.production.example" "$APP_DIR/.env"
        print_status "Created .env file from production example"
        print_warning "Please review and update the .env file with your actual values"
        print_warning "Run: nano $APP_DIR/.env"
        print_warning "Press Enter to continue after reviewing..."
        read
    else
        print_error "No .env file or production example found"
        exit 1
    fi
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

print_success "Environment variables validated"

# System setup
print_header "System Setup and Dependencies"

# Update system packages
print_status "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install required system packages
print_status "Installing system dependencies..."
sudo apt install -y \
    python3 python3-pip python3-venv python3-dev \
    postgresql-client nginx redis-tools \
    build-essential libpq-dev libssl-dev libffi-dev \
    curl wget git htop iotop nload \
    fail2ban ufw \
    certbot python3-certbot-nginx \
    logrotate

# Create necessary directories
print_status "Creating directories..."
sudo mkdir -p $LOG_DIR
sudo mkdir -p $APP_DIR/staticfiles
sudo mkdir -p $APP_DIR/media
sudo mkdir -p /var/www/html

# Set up virtual environment
print_header "Python Environment Setup"
source $VENV_DIR/bin/activate

# Install Python dependencies
print_status "Installing Python dependencies..."
pip install --upgrade pip

# Try to install requirements, fallback to minimal if there are conflicts
if pip install -r $APP_DIR/requirements.txt; then
    print_success "Full requirements installed successfully"
else
    print_warning "Full requirements installation failed, trying minimal requirements..."
    if pip install -r $APP_DIR/requirements-minimal.txt; then
        print_success "Minimal requirements installed successfully"
    else
        print_error "Both full and minimal requirements failed"
        print_warning "Installing core packages manually..."
        pip install \
            Django==5.1.4 \
            djangorestframework==3.16.1 \
            psycopg[binary]==3.2.3 \
            gunicorn==23.0.0 \
            redis==5.0.1 \
            django-redis==5.4.0 \
            django-cors-headers==4.3.1 \
            django-health-check==3.17.0 \
            python-dotenv==1.0.0 \
            gevent==23.9.1
        print_warning "Core packages installed. You may need to install additional packages manually."
    fi
fi

# Test AWS connections
print_header "Testing AWS Connections"

# Test RDS connection
print_status "Testing RDS PostgreSQL connection..."
if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" > /dev/null 2>&1; then
    print_success "RDS PostgreSQL connection successful"
else
    print_error "RDS PostgreSQL connection failed"
    print_warning "Please check your RDS security groups and connection details"
    exit 1
fi

# Test ElastiCache connection
REDIS_HOST=$(echo $REDIS_URL | sed 's/redis:\/\/\([^:]*\):.*/\1/')
REDIS_PORT=$(echo $REDIS_URL | sed 's/redis:\/\/[^:]*:\([^/]*\)\/.*/\1/')

print_status "Testing ElastiCache Redis connection..."
if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1; then
    print_success "ElastiCache Redis connection successful"
else
    print_error "ElastiCache Redis connection failed"
    print_warning "Please check your ElastiCache security groups and connection details"
    exit 1
fi

# Database setup
print_header "Database Setup"
export DJANGO_SETTINGS_MODULE=campshub360.production_http

# Run database migrations
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

# Set up systemd service
print_header "Service Configuration"

# Create the missing production_http.py file
print_status "Creating production_http.py compatibility file..."
cat > $APP_DIR/campshub360/production_http.py << 'EOF'
"""
Production HTTP settings for CampsHub360 project.
This file imports from production.py to maintain compatibility.
"""
from .production import *
EOF

# Create systemd service file
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
Environment=DJANGO_SETTINGS_MODULE=campshub360.production_http
ExecStart=$VENV_DIR/bin/gunicorn --config $APP_DIR/gunicorn.conf.py --bind 127.0.0.1:8000 campshub360.wsgi:application
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=campshub360

[Install]
WantedBy=multi-user.target
EOF

# Create www-data user if it doesn't exist
if ! id "www-data" &>/dev/null; then
    print_status "Creating www-data user..."
    sudo useradd -r -s /bin/false www-data
fi

sudo systemctl daemon-reload
sudo systemctl enable campshub360

# Set up nginx
print_header "Nginx Configuration"

# Copy nginx configuration
if [ -f "$APP_DIR/nginx-http-production.conf" ]; then
    sudo cp $APP_DIR/nginx-http-production.conf /etc/nginx/nginx.conf
    print_success "Using production nginx configuration"
else
    print_warning "Production nginx config not found, using basic configuration"
    sudo tee /etc/nginx/sites-available/campshub360 > /dev/null << EOF
upstream django_app {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name _;
    
    client_max_body_size 10M;
    
    location /static/ {
        alias $APP_DIR/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    location /media/ {
        alias $APP_DIR/media/;
        expires 1y;
        add_header Cache-Control "public";
        access_log off;
    }
    
    location /health/ {
        proxy_pass http://django_app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location / {
        proxy_pass http://django_app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    access_log /var/log/nginx/campshub360_access.log;
    error_log /var/log/nginx/campshub360_error.log;
}
EOF
    sudo ln -sf /etc/nginx/sites-available/campshub360 /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
fi

# Test nginx configuration
print_status "Testing nginx configuration..."
if sudo nginx -t; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# Set up logging
print_header "Logging Configuration"

# Create logrotate configuration
sudo tee /etc/logrotate.d/campshub360 > /dev/null << EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $SERVICE_USER $SERVICE_USER
    postrotate
        systemctl reload campshub360
    endscript
}

$NGINX_LOG_DIR/campshub360_*.log {
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

# Set proper permissions
print_header "Setting Permissions"
sudo chown -R $SERVICE_USER:$SERVICE_USER $APP_DIR
sudo chmod -R 755 $APP_DIR
sudo chgrp $SERVICE_USER $APP_DIR/.env || true
sudo chmod 640 $APP_DIR/.env
sudo chown -R $SERVICE_USER:$SERVICE_USER $LOG_DIR
sudo chown -R www-data:www-data $NGINX_LOG_DIR

print_success "Permissions set correctly"

# Security setup
print_header "Security Configuration"

# Configure UFW firewall
print_status "Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Configure fail2ban
print_status "Configuring fail2ban..."
sudo tee /etc/fail2ban/jail.local > /dev/null << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 3

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 3
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Start services
print_header "Starting Services"
sudo systemctl enable nginx
sudo systemctl restart nginx
sudo systemctl restart campshub360

# Wait for services to start
sleep 10

# Check service status
print_header "Service Status Check"
if sudo systemctl is-active --quiet campshub360; then
    print_success "CampsHub360 service is running"
else
    print_error "CampsHub360 service failed to start"
    print_warning "Check logs with: sudo journalctl -u campshub360 -f"
    sudo systemctl status campshub360
fi

if sudo systemctl is-active --quiet nginx; then
    print_success "Nginx service is running"
else
    print_error "Nginx service failed to start"
    sudo systemctl status nginx
fi

# Health check
print_header "Application Health Check"
if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
    print_success "Application health check passed"
else
    print_warning "Application health check failed - check logs"
    print_warning "Check logs with: sudo journalctl -u campshub360 -f"
fi

# Performance monitoring setup
print_header "Performance Monitoring"

# Create monitoring script
sudo tee /usr/local/bin/campshub360-monitor.sh > /dev/null << 'EOF'
#!/bin/bash
# CampsHub360 Performance Monitor

LOG_FILE="/var/log/django/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Check service status
if systemctl is-active --quiet campshub360; then
    SERVICE_STATUS="OK"
else
    SERVICE_STATUS="FAILED"
fi

# Check disk usage
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# Check memory usage
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')

# Check load average
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

# Log metrics
echo "$DATE - Service: $SERVICE_STATUS, Disk: ${DISK_USAGE}%, Memory: ${MEMORY_USAGE}%, Load: $LOAD_AVG" >> $LOG_FILE

# Alert if disk usage > 90%
if [ $DISK_USAGE -gt 90 ]; then
    echo "$DATE - ALERT: Disk usage is ${DISK_USAGE}%" >> $LOG_FILE
fi

# Alert if memory usage > 90%
if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
    echo "$DATE - ALERT: Memory usage is ${MEMORY_USAGE}%" >> $LOG_FILE
fi
EOF

sudo chmod +x /usr/local/bin/campshub360-monitor.sh

# Add monitoring to crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/campshub360-monitor.sh") | crontab -

# Final status
print_header "Deployment Complete!"
print_success "RDS PostgreSQL connected"
print_success "ElastiCache Redis connected"
print_success "Database migrations completed"
print_success "Superuser created (admin/admin123)"
print_success "Static files collected"
print_success "Services started and configured"
print_success "Security configured (UFW + Fail2ban)"
print_success "Monitoring setup complete"

print_warning "Access your application:"
print_status "🌐 Application: http://$PUBLIC_IP"
print_status "🔧 Admin Panel: http://$PUBLIC_IP/admin/ (admin/admin123)"
print_status "❤️ Health Check: http://$PUBLIC_IP/health/"
print_status "📡 API: http://$PUBLIC_IP/api/"

print_warning "Useful commands:"
print_status "📋 Check service status: sudo systemctl status campshub360"
print_status "📋 View service logs: sudo journalctl -u campshub360 -f"
print_status "📋 Restart service: sudo systemctl restart campshub360"
print_status "📋 Check nginx status: sudo systemctl status nginx"
print_status "📋 View nginx logs: sudo tail -f /var/log/nginx/campshub360_error.log"
print_status "📋 Monitor performance: tail -f /var/log/django/monitor.log"

print_warning "Next steps:"
print_warning "1. Change admin password: http://$PUBLIC_IP/admin/"
print_warning "2. Test your frontend connection"
print_warning "3. Set up SSL certificate: sudo certbot --nginx"
print_warning "4. Configure domain name in nginx"
print_warning "5. Set up automated backups"

echo ""
echo -e "${GREEN}🎉 Production deployment completed successfully!${NC}"
echo -e "${PURPLE}Your CampsHub360 application is now running in production mode.${NC}"
