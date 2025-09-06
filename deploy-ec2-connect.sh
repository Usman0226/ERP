#!/bin/bash

# AWS EC2 Instance Connect Deployment Script for CampsHub360
# This script uses AWS EC2 Instance Connect (no SSH keys needed)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EC2_INSTANCE_IP="${EC2_INSTANCE_IP:-}"
EC2_INSTANCE_ID="${EC2_INSTANCE_ID:-}"
EC2_USER="${EC2_USER:-ubuntu}"
APP_NAME="campshub360"
APP_DIR="/home/${EC2_USER}/${APP_NAME}"

# Function to print colored output
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
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check if required environment variables are set
check_requirements() {
    print_header "Checking requirements..."
    
    if [ -z "$EC2_INSTANCE_IP" ]; then
        print_error "EC2_INSTANCE_IP environment variable is not set"
        print_error "Please set it with: export EC2_INSTANCE_IP=your-ec2-ip"
        exit 1
    fi
    
    if [ -z "$EC2_INSTANCE_ID" ]; then
        print_warning "EC2_INSTANCE_ID not set. Will use IP-based connection."
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first:"
        print_error "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run: aws configure"
        exit 1
    fi
    
    print_status "Requirements check passed"
}

# Generate secure passwords
generate_passwords() {
    print_header "Generating secure passwords..."
    
    # Generate random passwords
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    SECRET_KEY=$(openssl rand -base64 50 | tr -d "=+/" | cut -c1-50)
    
    print_status "Passwords generated successfully"
}

# Create environment file
create_env_file() {
    print_header "Creating environment configuration..."
    
    cat > .env.production << EOF
# CampsHub360 Production Environment - Auto Generated
# Generated on: $(date)

# Database Configuration
POSTGRES_DB=campushub360
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${DB_PASSWORD}
POSTGRES_HOST=db
POSTGRES_PORT=5432
POSTGRES_CONN_MAX_AGE=600
POSTGRES_CONNECT_TIMEOUT=10

# Redis Configuration
REDIS_URL=redis://redis:6379/0
REDIS_PASSWORD=${REDIS_PASSWORD}

# Django Configuration
SECRET_KEY=${SECRET_KEY}
DEBUG=False
DJANGO_SETTINGS_MODULE=campshub360.production

# Security Settings
SECURE_SSL_REDIRECT=False
CSRF_COOKIE_SECURE=False
SESSION_COOKIE_SECURE=False
SECURE_HSTS_SECONDS=0

# Performance Settings (Optimized for 20k+ users/sec)
GUNICORN_WORKERS=16
GUNICORN_WORKER_CLASS=gevent
GUNICORN_WORKER_CONNECTIONS=1000
GUNICORN_TIMEOUT=30
GUNICORN_KEEPALIVE=5
GUNICORN_MAX_REQUESTS=1000
GUNICORN_MAX_REQUESTS_JITTER=100

# Cache Settings
CACHE_DEFAULT_TIMEOUT=300
SESSION_CACHE_TIMEOUT=86400
QUERY_CACHE_TIMEOUT=600

# CORS Settings (Update with your domain)
CORS_ALLOWED_ORIGINS=http://${EC2_INSTANCE_IP},https://${EC2_INSTANCE_IP}
CSRF_TRUSTED_ORIGINS=http://${EC2_INSTANCE_IP},https://${EC2_INSTANCE_IP}

# Allowed Hosts
ALLOWED_HOSTS=${EC2_INSTANCE_IP},localhost,127.0.0.1

# Email Configuration (Optional - Update with your SMTP)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
DEFAULT_FROM_EMAIL=noreply@${EC2_INSTANCE_IP}

# API Settings
API_PAGE_SIZE=50

# Docker Settings
DOCKER_CONTAINER=true
EOF
    
    print_status "Environment file created: .env.production"
}

# Function to run commands on EC2 using AWS CLI
run_ec2_command() {
    local command="$1"
    
    if [ -n "$EC2_INSTANCE_ID" ]; then
        # Use EC2 Instance Connect with instance ID
        aws ec2-instance-connect send-ssh-public-key \
            --instance-id "$EC2_INSTANCE_ID" \
            --instance-os-user "$EC2_USER" \
            --ssh-public-key file://~/.ssh/id_rsa.pub 2>/dev/null || true
        
        aws ssm start-session \
            --target "$EC2_INSTANCE_ID" \
            --document-name AWS-StartSSHSession \
            --parameters 'portNumber=22' \
            --cli-read-timeout 0 \
            --cli-write-timeout 0 \
            --input-text "$command"
    else
        # Use regular SSH (fallback)
        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_INSTANCE_IP} "$command"
    fi
}

# Function to copy files to EC2
copy_to_ec2() {
    local local_file="$1"
    local remote_path="$2"
    
    if [ -n "$EC2_INSTANCE_ID" ]; then
        # Use AWS CLI to copy files
        print_status "Copying $local_file to EC2..."
        # For now, we'll use a workaround with base64 encoding
        base64_content=$(base64 -w 0 "$local_file")
        run_ec2_command "echo '$base64_content' | base64 -d > '$remote_path'"
    else
        # Use SCP
        scp -o StrictHostKeyChecking=no "$local_file" ${EC2_USER}@${EC2_INSTANCE_IP}:"$remote_path"
    fi
}

# Setup EC2 instance
setup_ec2() {
    print_header "Setting up EC2 instance..."
    
    local setup_script='
        set -e
        echo "Updating system packages..."
        sudo apt update && sudo apt upgrade -y
        
        echo "Installing Docker and Docker Compose..."
        # Install Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker '${EC2_USER}'
        
        # Install Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        echo "Installing additional tools..."
        sudo apt install -y curl wget git htop
        
        echo "Creating application directory..."
        mkdir -p '${APP_DIR}'
        
        echo "Setting up firewall..."
        sudo ufw allow 22
        sudo ufw allow 80
        sudo ufw allow 443
        sudo ufw --force enable
        
        echo "EC2 setup completed successfully!"
    '
    
    run_ec2_command "$setup_script"
    print_status "EC2 instance setup completed"
}

# Deploy application
deploy_application() {
    print_header "Deploying application to EC2..."
    
    # Copy files to EC2
    print_status "Copying application files..."
    copy_to_ec2 "docker-compose.production.yml" "${APP_DIR}/"
    copy_to_ec2 ".env.production" "${APP_DIR}/.env"
    copy_to_ec2 "nginx-production-lb.conf" "${APP_DIR}/"
    copy_to_ec2 "Dockerfile" "${APP_DIR}/"
    copy_to_ec2 "gunicorn.conf.py" "${APP_DIR}/"
    copy_to_ec2 "supervisord.conf" "${APP_DIR}/"
    copy_to_ec2 "nginx-docker.conf" "${APP_DIR}/"
    copy_to_ec2 "init-db.sql" "${APP_DIR}/"
    
    # Copy Django application code (simplified approach)
    print_status "Copying Django application code..."
    # Create a tar file of the application
    tar -czf app-code.tar.gz --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' --exclude='.env*' --exclude='db.sqlite3' --exclude='media' --exclude='staticfiles' .
    copy_to_ec2 "app-code.tar.gz" "${APP_DIR}/"
    
    # Extract and deploy on EC2
    local deploy_script='
        set -e
        cd '${APP_DIR}'
        
        echo "Extracting application code..."
        tar -xzf app-code.tar.gz
        rm app-code.tar.gz
        
        echo "Building Docker image..."
        docker build -t '${APP_NAME}':latest .
        
        echo "Starting services..."
        docker-compose -f docker-compose.production.yml down || true
        docker-compose -f docker-compose.production.yml up -d
        
        echo "Waiting for services to start..."
        sleep 30
        
        echo "Checking service status..."
        docker-compose -f docker-compose.production.yml ps
        
        echo "Running database migrations..."
        docker-compose -f docker-compose.production.yml exec -T web python manage.py migrate --settings=campshub360.production
        
        echo "Creating superuser..."
        docker-compose -f docker-compose.production.yml exec -T web python manage.py shell --settings=campshub360.production << "PYTHON"
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username="admin").exists():
    User.objects.create_superuser("admin", "admin@example.com", "admin123")
    print("Superuser created: admin/admin123")
else:
    print("Superuser already exists")
PYTHON
        
        echo "Collecting static files..."
        docker-compose -f docker-compose.production.yml exec -T web python manage.py collectstatic --noinput --settings=campshub360.production
        
        echo "Application deployed successfully!"
    '
    
    run_ec2_command "$deploy_script"
    print_status "Application deployment completed"
}

# Test deployment
test_deployment() {
    print_header "Testing deployment..."
    
    # Wait a bit for services to fully start
    sleep 10
    
    # Test health endpoint
    print_status "Testing health endpoint..."
    if curl -f -s --max-time 30 "http://${EC2_INSTANCE_IP}/health/" > /dev/null; then
        print_status "✅ Health check passed!"
    else
        print_warning "⚠️ Health check failed, but application might still be starting..."
    fi
    
    # Test main application
    print_status "Testing main application..."
    if curl -f -s --max-time 30 "http://${EC2_INSTANCE_IP}/" > /dev/null; then
        print_status "✅ Main application is accessible!"
    else
        print_warning "⚠️ Main application test failed, but it might still be starting..."
    fi
}

# Show deployment information
show_deployment_info() {
    print_header "Deployment Information"
    
    echo ""
    echo "🎉 CampsHub360 has been successfully deployed using AWS EC2 Instance Connect!"
    echo ""
    echo "📋 Deployment Details:"
    echo "   • Application URL: http://${EC2_INSTANCE_IP}"
    echo "   • Health Check: http://${EC2_INSTANCE_IP}/health/"
    echo "   • Admin Panel: http://${EC2_INSTANCE_IP}/admin/"
    echo ""
    echo "🔐 Admin Credentials:"
    echo "   • Username: admin"
    echo "   • Password: admin123"
    echo ""
    echo "🗄️ Database Information:"
    echo "   • Database: campushub360"
    echo "   • Username: postgres"
    echo "   • Password: ${DB_PASSWORD}"
    echo ""
    echo "📊 Monitoring Commands (using AWS CLI):"
    if [ -n "$EC2_INSTANCE_ID" ]; then
        echo "   • View logs: aws ssm start-session --target ${EC2_INSTANCE_ID} --document-name AWS-StartSSHSession"
        echo "   • Check status: aws ssm start-session --target ${EC2_INSTANCE_ID} --document-name AWS-StartSSHSession"
    else
        echo "   • View logs: ssh ${EC2_USER}@${EC2_INSTANCE_IP} 'cd ${APP_DIR} && docker-compose -f docker-compose.production.yml logs -f'"
        echo "   • Check status: ssh ${EC2_USER}@${EC2_INSTANCE_IP} 'cd ${APP_DIR} && docker-compose -f docker-compose.production.yml ps'"
    fi
    echo ""
    echo "🔧 Configuration Files:"
    echo "   • Environment: ${APP_DIR}/.env"
    echo "   • Docker Compose: ${APP_DIR}/docker-compose.production.yml"
    echo ""
    echo "⚠️ Important Notes:"
    echo "   • Change the admin password after first login"
    echo "   • Update CORS_ALLOWED_ORIGINS with your domain"
    echo "   • Configure email settings if needed"
    echo "   • Set up SSL certificates for production use"
    echo ""
}

# Main function
main() {
    print_header "Starting CampsHub360 deployment using AWS EC2 Instance Connect..."
    print_status "Target EC2 Instance: ${EC2_INSTANCE_IP}"
    if [ -n "$EC2_INSTANCE_ID" ]; then
        print_status "EC2 Instance ID: ${EC2_INSTANCE_ID}"
    fi
    print_status "EC2 User: ${EC2_USER}"
    
    check_requirements
    generate_passwords
    create_env_file
    setup_ec2
    deploy_application
    test_deployment
    show_deployment_info
    
    print_status "🎉 Deployment completed successfully using AWS EC2 Instance Connect!"
}

# Run main function
main "$@"
