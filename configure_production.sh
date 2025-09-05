#!/bin/bash

# Production Configuration Script for CampsHub360
# This script helps configure the production environment

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

# Get EC2 instance metadata
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo "127.0.0.1")
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1")

print_header "CampsHub360 Production Configuration"

# Generate a secure secret key
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")

# Get user input for configuration
echo "Please provide the following information for production configuration:"
echo

read -p "Domain name (e.g., yourdomain.com): " DOMAIN_NAME
read -p "Database host (RDS endpoint or localhost): " DB_HOST
read -p "Database name: " DB_NAME
read -p "Database username: " DB_USER
read -s -p "Database password: " DB_PASSWORD
echo
read -p "Redis host (ElastiCache endpoint or localhost): " REDIS_HOST
read -p "Email host (AWS SES endpoint): " EMAIL_HOST
read -p "Email username (SES SMTP username): " EMAIL_USER
read -s -p "Email password (SES SMTP password): " EMAIL_PASSWORD
echo
read -p "From email address: " FROM_EMAIL

# Set defaults if empty
DOMAIN_NAME=${DOMAIN_NAME:-"$PUBLIC_IP"}
DB_HOST=${DB_HOST:-"localhost"}
DB_NAME=${DB_NAME:-"campshub360_prod"}
DB_USER=${DB_USER:-"campshub360_user"}
REDIS_HOST=${REDIS_HOST:-"localhost"}
EMAIL_HOST=${EMAIL_HOST:-"email-smtp.$REGION.amazonaws.com"}
FROM_EMAIL=${FROM_EMAIL:-"noreply@$DOMAIN_NAME"}

# Create .env file
print_header "Creating Production Environment File"
cat > .env << EOF
# Django Settings
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=$DOMAIN_NAME,www.$DOMAIN_NAME,$PUBLIC_IP,localhost,127.0.0.1

# Database Configuration
POSTGRES_DB=$DB_NAME
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$DB_PASSWORD
POSTGRES_HOST=$DB_HOST
POSTGRES_PORT=5432

# Redis Configuration
REDIS_URL=redis://$REDIS_HOST:6379/1

# Email Configuration
EMAIL_HOST=$EMAIL_HOST
EMAIL_PORT=587
EMAIL_HOST_USER=$EMAIL_USER
EMAIL_HOST_PASSWORD=$EMAIL_PASSWORD
DEFAULT_FROM_EMAIL=$FROM_EMAIL

# AWS S3 Configuration (Optional)
USE_S3=False
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_STORAGE_BUCKET_NAME=
AWS_S3_REGION_NAME=$REGION

# CORS Settings
CORS_ALLOWED_ORIGINS=https://$DOMAIN_NAME,https://www.$DOMAIN_NAME

# Security Settings
SECURE_SSL_REDIRECT=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True
EOF

print_status "Environment file created: .env"

# Update nginx configuration
print_header "Updating Nginx Configuration"
sed -i "s/your-domain.com/$DOMAIN_NAME/g" nginx.conf
sed -i "s/www.your-domain.com/www.$DOMAIN_NAME/g" nginx.conf
sed -i "s|/app/staticfiles/|$(pwd)/staticfiles/|g" nginx.conf
sed -i "s|/app/media/|$(pwd)/media/|g" nginx.conf

print_status "Nginx configuration updated"

# Create SSL certificate setup script
print_header "Creating SSL Certificate Setup Script"
cat > setup_ssl.sh << 'EOF'
#!/bin/bash

# SSL Certificate Setup Script
# This script sets up SSL certificates using Let's Encrypt

set -e

DOMAIN_NAME=$1
if [ -z "$DOMAIN_NAME" ]; then
    echo "Usage: $0 <domain-name>"
    echo "Example: $0 yourdomain.com"
    exit 1
fi

echo "Setting up SSL certificate for $DOMAIN_NAME..."

# Install certbot if not already installed
if ! command -v certbot &> /dev/null; then
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Stop nginx temporarily
sudo systemctl stop nginx

# Get certificate
sudo certbot certonly --standalone -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME

# Update nginx configuration with SSL paths
sudo sed -i "s|/etc/ssl/certs/your-domain.crt|/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem|g" /etc/nginx/sites-available/campshub360
sudo sed -i "s|/etc/ssl/private/your-domain.key|/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem|g" /etc/nginx/sites-available/campshub360

# Test nginx configuration
sudo nginx -t

# Start nginx
sudo systemctl start nginx

# Set up auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -

echo "SSL certificate setup completed!"
echo "Your site should now be accessible at https://$DOMAIN_NAME"
EOF

chmod +x setup_ssl.sh
print_status "SSL setup script created: setup_ssl.sh"

# Create database setup script
print_header "Creating Database Setup Script"
cat > setup_database.sh << 'EOF'
#!/bin/bash

# Database Setup Script
# This script sets up the PostgreSQL database

set -e

# Load environment variables
source .env

echo "Setting up database: $POSTGRES_DB"

# Check if using local PostgreSQL
if [ "$POSTGRES_HOST" = "localhost" ] || [ "$POSTGRES_HOST" = "127.0.0.1" ]; then
    echo "Setting up local PostgreSQL..."
    
    # Install PostgreSQL if not installed
    if ! command -v psql &> /dev/null; then
        sudo apt update
        sudo apt install -y postgresql postgresql-contrib
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    fi
    
    # Create database and user
    sudo -u postgres psql << EOF
CREATE DATABASE $POSTGRES_DB;
CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
ALTER USER $POSTGRES_USER CREATEDB;
\q
EOF
    
    echo "Local PostgreSQL database created successfully!"
else
    echo "Using remote database: $POSTGRES_HOST"
    echo "Please ensure the database and user are created on your RDS instance."
fi

# Run Django migrations
echo "Running Django migrations..."
source venv/bin/activate
python manage.py migrate

# Create superuser
echo "Creating superuser..."
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(is_superuser=True).exists():
    User.objects.create_superuser('admin', 'admin@$DOMAIN_NAME', 'admin123')
    print('Superuser created: admin/admin123')
else:
    print('Superuser already exists')
EOF

echo "Database setup completed!"
EOF

chmod +x setup_database.sh
print_status "Database setup script created: setup_database.sh"

# Create Redis setup script
print_header "Creating Redis Setup Script"
cat > setup_redis.sh << 'EOF'
#!/bin/bash

# Redis Setup Script
# This script sets up Redis for caching

set -e

# Load environment variables
source .env

echo "Setting up Redis..."

# Check if using local Redis
if [ "$REDIS_HOST" = "localhost" ] || [ "$REDIS_HOST" = "127.0.0.1" ]; then
    echo "Setting up local Redis..."
    
    # Install Redis if not installed
    if ! command -v redis-server &> /dev/null; then
        sudo apt update
        sudo apt install -y redis-server
        sudo systemctl start redis-server
        sudo systemctl enable redis-server
    fi
    
    # Configure Redis for production
    sudo tee -a /etc/redis/redis.conf > /dev/null << EOF

# Production settings
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
EOF
    
    sudo systemctl restart redis-server
    echo "Local Redis setup completed!"
else
    echo "Using remote Redis: $REDIS_HOST"
    echo "Please ensure your ElastiCache Redis cluster is accessible."
fi

# Test Redis connection
echo "Testing Redis connection..."
redis-cli -h $REDIS_HOST ping

echo "Redis setup completed!"
EOF

chmod +x setup_redis.sh
print_status "Redis setup script created: setup_redis.sh"

print_header "Configuration Complete!"

print_status "Configuration files created:"
print_status "  - .env (environment variables)"
print_status "  - setup_ssl.sh (SSL certificate setup)"
print_status "  - setup_database.sh (database setup)"
print_status "  - setup_redis.sh (Redis setup)"

print_warning "Next steps:"
print_warning "1. Review and update .env file if needed"
print_warning "2. Set up database: ./setup_database.sh"
print_warning "3. Set up Redis: ./setup_redis.sh"
print_warning "4. Run deployment: sudo ./deploy.sh"
print_warning "5. Set up SSL (if using domain): ./setup_ssl.sh $DOMAIN_NAME"

print_warning "Important:"
print_warning "- Change the default admin password after deployment"
print_warning "- Update ALLOWED_HOSTS in .env if using a domain"
print_warning "- Configure AWS services (RDS, ElastiCache, SES) if using them"

echo -e "${GREEN}Production configuration completed!${NC}"
