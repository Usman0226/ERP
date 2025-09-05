#!/bin/bash

# CampsHub360 Dependency Fix Script
# This script resolves the Django and django-celery-beat compatibility issue

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

print_header "CampsHub360 Dependency Fix"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    print_error "Virtual environment not found. Please run the deployment script first."
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

print_status "Activated virtual environment"

# Option 1: Install without celery packages (recommended for most deployments)
print_header "Option 1: Installing without Celery packages (Recommended)"
print_status "This removes background task functionality but ensures compatibility"

if pip install -r requirements-minimal.txt; then
    print_status "✅ Successfully installed minimal requirements"
    print_warning "Note: Background tasks (Celery) are disabled. This is fine for most deployments."
    exit 0
fi

# Option 2: Try with compatible Django version
print_header "Option 2: Installing with compatible Django version"
print_status "This keeps all features but uses Django 5.1.4 instead of 5.2.5"

# Create temporary requirements file
cat > requirements-compatible.txt << EOF
# Core Django Framework
Django==5.1.4
djangorestframework==3.16.1
djangorestframework-simplejwt==5.5.1

# Database
psycopg[binary]==3.2.3

# Server & WSGI
gunicorn==23.0.0
gevent==24.11.1

# Utilities
python-dotenv==1.0.1
requests==2.32.3
Pillow==11.0.0
pandas==2.2.3
openpyxl==3.1.5
django-filter==24.3

# Security
cryptography==44.0.0
bcrypt==4.2.1

# Performance & Monitoring
psutil==6.1.0

# CORS
django-cors-headers==4.6.0

# Caching
django-redis==5.4.0
redis==5.2.1

# Environment & Configuration
python-decouple==3.8
django-environ==0.11.2

# AWS Services
boto3==1.35.93
django-storages==1.14.4

# File Processing
python-magic==0.4.27

# Background Tasks
celery==5.4.0
django-celery-beat==2.7.0
django-celery-results==2.5.1

# API Documentation
drf-spectacular==0.28.0

# Additional Production Dependencies
whitenoise==6.8.2
dj-database-url==2.3.0
EOF

if pip install -r requirements-compatible.txt; then
    print_status "✅ Successfully installed compatible requirements"
    print_warning "Note: Using Django 5.1.4 instead of 5.2.5 for compatibility"
    exit 0
fi

# Option 3: Manual installation without version constraints
print_header "Option 3: Installing without strict version constraints"
print_status "This allows pip to resolve dependencies automatically"

# Uninstall conflicting packages first
pip uninstall -y django-celery-beat django-celery-results celery || true

# Install core packages
pip install Django djangorestframework djangorestframework-simplejwt
pip install psycopg[binary] gunicorn gevent
pip install python-dotenv requests Pillow pandas openpyxl django-filter
pip install cryptography bcrypt psutil
pip install django-cors-headers django-redis redis
pip install python-decouple django-environ
pip install boto3 django-storages python-magic
pip install drf-spectacular whitenoise dj-database-url

# Try to install celery packages with latest compatible versions
if pip install celery django-celery-beat django-celery-results; then
    print_status "✅ Successfully installed all packages including Celery"
else
    print_warning "⚠️ Celery packages could not be installed, but core functionality is available"
fi

print_header "Dependency Fix Complete"
print_status "You can now continue with the deployment process"

# Clean up temporary file
rm -f requirements-compatible.txt
