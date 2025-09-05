#!/bin/bash

# CampsHub360 Deployment Validation Script
# Run this after deployment to verify everything is working

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

print_header "CampsHub360 Deployment Validation"

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")

print_status "Validating deployment on: $PUBLIC_IP"

# Check if services are running
print_header "Service Status Check"
if sudo systemctl is-active --quiet campshub360; then
    print_status "✓ CampsHub360 service is running"
else
    print_error "✗ CampsHub360 service is not running"
    print_warning "Check logs: sudo journalctl -u campshub360 -f"
fi

if sudo systemctl is-active --quiet nginx; then
    print_status "✓ Nginx service is running"
else
    print_error "✗ Nginx service is not running"
    print_warning "Check logs: sudo journalctl -u nginx -f"
fi

# Test health endpoint
print_header "Health Check"
if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
    print_status "✓ Application health check passed"
else
    print_warning "⚠ Application health check failed"
    print_warning "Check if Django is running: sudo systemctl status campshub360"
fi

# Test nginx proxy
print_header "Nginx Proxy Test"
if curl -f http://localhost/health/ > /dev/null 2>&1; then
    print_status "✓ Nginx proxy is working"
else
    print_warning "⚠ Nginx proxy test failed"
    print_warning "Check nginx config: sudo nginx -t"
fi

# Test external access
print_header "External Access Test"
if curl -f http://$PUBLIC_IP/health/ > /dev/null 2>&1; then
    print_status "✓ External access is working"
else
    print_warning "⚠ External access test failed"
    print_warning "Check security groups and firewall settings"
fi

# Test database connection
print_header "Database Connection Test"
if python manage.py check --database default > /dev/null 2>&1; then
    print_status "✓ Database connection is working"
else
    print_warning "⚠ Database connection test failed"
    print_warning "Check RDS security groups and connection details"
fi

# Test Redis connection
print_header "Redis Connection Test"
if python manage.py shell -c "from django.core.cache import cache; cache.set('test', 'value', 10); print('Redis OK' if cache.get('test') == 'value' else 'Redis FAIL')" 2>/dev/null | grep -q "Redis OK"; then
    print_status "✓ Redis connection is working"
else
    print_warning "⚠ Redis connection test failed"
    print_warning "Check ElastiCache security groups and connection details"
fi

# Test cache settings
print_header "Cache Settings Test"
if python manage.py shell -c "from django.core.cache import cache; cache.set('cache_test', 'working', 300); print('Cache OK' if cache.get('cache_test') == 'working' else 'Cache FAIL')" 2>/dev/null | grep -q "Cache OK"; then
    print_status "✓ Cache settings are working"
else
    print_warning "⚠ Cache settings test failed"
fi

# Test static files
print_header "Static Files Test"
if [ -d "/app/staticfiles" ] && [ "$(ls -A /app/staticfiles)" ]; then
    print_status "✓ Static files are collected"
else
    print_warning "⚠ Static files are missing"
    print_warning "Run: python manage.py collectstatic --noinput"
fi

# Test admin access
print_header "Admin Panel Test"
if curl -f http://$PUBLIC_IP/admin/ > /dev/null 2>&1; then
    print_status "✓ Admin panel is accessible"
else
    print_warning "⚠ Admin panel test failed"
fi

# Test API endpoints
print_header "API Endpoints Test"
if curl -f http://$PUBLIC_IP/api/ > /dev/null 2>&1; then
    print_status "✓ API endpoints are accessible"
else
    print_warning "⚠ API endpoints test failed"
fi

# Test CORS settings
print_header "CORS Settings Test"
if curl -H "Origin: http://$PUBLIC_IP" -H "Access-Control-Request-Method: GET" -H "Access-Control-Request-Headers: X-Requested-With" -X OPTIONS http://$PUBLIC_IP/api/ > /dev/null 2>&1; then
    print_status "✓ CORS settings are working"
else
    print_warning "⚠ CORS settings test failed"
fi

# Final summary
print_header "Deployment Summary"
print_status "🌐 Application URL: http://$PUBLIC_IP"
print_status "🔧 Admin Panel: http://$PUBLIC_IP/admin/ (admin/admin123)"
print_status "❤️ Health Check: http://$PUBLIC_IP/health/"
print_status "📡 API: http://$PUBLIC_IP/api/"

print_warning "Next steps:"
print_warning "1. Change admin password: python manage.py changepassword admin"
print_warning "2. Test your frontend connection"
print_warning "3. Set up SSL certificate (optional)"
print_warning "4. Configure domain name (optional)"

print_status "Deployment validation completed!"
