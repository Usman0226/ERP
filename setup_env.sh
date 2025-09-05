#!/bin/bash

# Environment Setup Script for CampsHub360
# Creates .env file with your AWS configuration

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

print_header "CampsHub360 Environment Setup"

# Generate a secure secret key
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")

print_status "Creating .env file with your AWS configuration..."

cat > .env << EOF
# Django Settings
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=35.154.2.91,ec2-35-154-2-91.ap-south-1.compute.amazonaws.com,localhost,127.0.0.1

# CORS/CSRF (frontend on localhost:5173 + EC2)
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://35.154.2.91,http://ec2-35-154-2-91.ap-south-1.compute.amazonaws.com
CSRF_TRUSTED_ORIGINS=http://localhost:5173,http://35.154.2.91,http://ec2-35-154-2-91.ap-south-1.compute.amazonaws.com

# Security (HTTP testing)
SECURE_SSL_REDIRECT=False
SECURE_HSTS_SECONDS=0
SECURE_HSTS_INCLUDE_SUBDOMAINS=False
SECURE_HSTS_PRELOAD=False

# Database (RDS)
POSTGRES_DB=campshub360
POSTGRES_USER=postgres
POSTGRES_PASSWORD=Campushub123
POSTGRES_HOST=database-1.cl00sagomrhg.ap-south-1.rds.amazonaws.com
POSTGRES_PORT=5432

# Redis (Valkey serverless)
REDIS_URL=redis://campshub-j2z0gd.serverless.aps1.cache.amazonaws.com:6379/1

# Email (optional)
EMAIL_HOST=email-smtp.ap-south-1.amazonaws.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-ses-smtp-username
EMAIL_HOST_PASSWORD=your-ses-smtp-password
DEFAULT_FROM_EMAIL=noreply@35.154.2.91.nip.io
EOF

print_status "✓ .env file created successfully"
print_warning "Review the .env file and update any values if needed"
print_warning "Run: nano .env"
