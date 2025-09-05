#!/bin/bash

# CampsHub360 Environment Setup Script
# Copies the production environment template to .env

set -e

# Colors for output
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

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_header "CampsHub360 Environment Setup"

# Check if .env already exists
if [ -f ".env" ]; then
    print_warning ".env file already exists!"
    echo -n "Do you want to backup the existing .env and create a new one? (y/n): "
    read backup_choice
    
    if [ "$backup_choice" = "y" ] || [ "$backup_choice" = "Y" ]; then
        backup_file=".env.backup.$(date +%Y%m%d_%H%M%S)"
        cp .env "$backup_file"
        print_status "Existing .env backed up to: $backup_file"
    else
        print_status "Keeping existing .env file"
        exit 0
    fi
fi

# Copy the production environment template
if [ -f "env.production.complete" ]; then
    cp env.production.complete .env
    print_status "Production environment template copied to .env"
else
    print_warning "env.production.complete not found!"
    exit 1
fi

print_header "Next Steps"
print_warning "IMPORTANT: You must update the following values in .env:"
echo ""
print_status "1. SECRET_KEY - Generate a strong, unique secret key"
print_status "2. AWS credentials - Replace example values with your actual keys"
print_status "3. Database credentials - Update with your RDS details"
print_status "4. Redis URL - Update with your ElastiCache endpoint"
print_status "5. Email settings - Configure AWS SES credentials"
echo ""
print_warning "To edit the .env file:"
print_status "nano .env"
echo ""
print_warning "To generate a new SECRET_KEY:"
print_status "python -c \"import secrets; print(secrets.token_urlsafe(50))\""
echo ""
print_success "Environment setup complete!"
print_status "Remember to update all placeholder values before deployment"
