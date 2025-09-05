#!/bin/bash

# CampsHub360 SSL Setup Script
# Automated SSL certificate setup with Let's Encrypt

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_header "CampsHub360 SSL Setup"

# Configuration
DOMAIN=""
EMAIL=""
APP_DIR="/home/ubuntu/campushub-backend-2"

# Get domain name
if [ -z "$DOMAIN" ]; then
    echo -n "Enter your domain name (e.g., yourdomain.com): "
    read DOMAIN
fi

if [ -z "$DOMAIN" ]; then
    print_error "Domain name is required"
    exit 1
fi

# Get email for Let's Encrypt
if [ -z "$EMAIL" ]; then
    echo -n "Enter your email address for Let's Encrypt: "
    read EMAIL
fi

if [ -z "$EMAIL" ]; then
    print_error "Email address is required"
    exit 1
fi

print_status "Setting up SSL for domain: $DOMAIN"
print_status "Email: $EMAIL"

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    print_status "Installing certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Update nginx configuration with domain
print_header "Updating Nginx Configuration"

# Create nginx configuration with domain
sudo tee /etc/nginx/sites-available/campshub360 > /dev/null << EOF
# Nginx configuration for CampsHub360 - $DOMAIN
upstream django_app {
    server 127.0.0.1:8000;
    keepalive 32;
}

# HTTP server - redirect to HTTPS
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration (will be updated by certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'none';" always;
    
    # Client settings
    client_max_body_size 10M;
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;
    
    # Timeouts
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;
    
    # Static files with aggressive caching
    location /static/ {
        alias $APP_DIR/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
        access_log off;
        gzip_static on;
    }
    
    # Media files
    location /media/ {
        alias $APP_DIR/media/;
        expires 1y;
        add_header Cache-Control "public";
        add_header Vary Accept-Encoding;
        access_log off;
    }
    
    # Health check endpoint
    location /health/ {
        proxy_pass http://django_app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        proxy_connect_timeout 5s;
        proxy_send_timeout 5s;
        proxy_read_timeout 5s;
        access_log off;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://django_app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }
    
    # Main application
    location / {
        proxy_pass http://django_app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_redirect off;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        proxy_temp_file_write_size 8k;
    }
    
    # Block access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~* \.(bak|backup|old|orig|save|swp|tmp)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Logging
    access_log /var/log/nginx/campshub360_access.log;
    error_log /var/log/nginx/campshub360_error.log warn;
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/campshub360 /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
print_status "Testing nginx configuration..."
if sudo nginx -t; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# Reload nginx
sudo systemctl reload nginx

# Update environment variables
print_header "Updating Environment Variables"

# Update .env file with domain
if [ -f "$APP_DIR/.env" ]; then
    # Update ALLOWED_HOSTS
    sed -i "s/ALLOWED_HOSTS=.*/ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN,localhost,127.0.0.1/" $APP_DIR/.env
    
    # Update CORS settings
    sed -i "s|CORS_ALLOWED_ORIGINS=.*|CORS_ALLOWED_ORIGINS=https://$DOMAIN,https://www.$DOMAIN,http://localhost:3000|" $APP_DIR/.env
    sed -i "s|CSRF_TRUSTED_ORIGINS=.*|CSRF_TRUSTED_ORIGINS=https://$DOMAIN,https://www.$DOMAIN,http://localhost:3000|" $APP_DIR/.env
    
    # Enable SSL settings
    sed -i "s/SECURE_SSL_REDIRECT=.*/SECURE_SSL_REDIRECT=True/" $APP_DIR/.env
    sed -i "s/SECURE_HSTS_SECONDS=.*/SECURE_HSTS_SECONDS=31536000/" $APP_DIR/.env
    sed -i "s/SECURE_HSTS_INCLUDE_SUBDOMAINS=.*/SECURE_HSTS_INCLUDE_SUBDOMAINS=True/" $APP_DIR/.env
    sed -i "s/SECURE_HSTS_PRELOAD=.*/SECURE_HSTS_PRELOAD=True/" $APP_DIR/.env
    sed -i "s/CSRF_COOKIE_SECURE=.*/CSRF_COOKIE_SECURE=True/" $APP_DIR/.env
    sed -i "s/SESSION_COOKIE_SECURE=.*/SESSION_COOKIE_SECURE=True/" $APP_DIR/.env
    
    print_success "Environment variables updated"
else
    print_warning ".env file not found, please update manually"
fi

# Obtain SSL certificate
print_header "Obtaining SSL Certificate"

print_status "Requesting SSL certificate from Let's Encrypt..."
if sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive --redirect; then
    print_success "SSL certificate obtained successfully"
else
    print_error "Failed to obtain SSL certificate"
    print_warning "Please check:"
    print_warning "1. Domain DNS is pointing to this server"
    print_warning "2. Port 80 and 443 are open in security groups"
    print_warning "3. Domain is accessible via HTTP"
    exit 1
fi

# Set up automatic renewal
print_header "Setting up Automatic Renewal"

# Create renewal script
sudo tee /usr/local/bin/certbot-renew.sh > /dev/null << 'EOF'
#!/bin/bash
# Certbot renewal script

/usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

sudo chmod +x /usr/local/bin/certbot-renew.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/local/bin/certbot-renew.sh") | crontab -

print_success "Automatic renewal configured"

# Restart services
print_header "Restarting Services"

sudo systemctl restart campshub360
sudo systemctl restart nginx

# Wait for services to start
sleep 5

# Test SSL setup
print_header "Testing SSL Setup"

# Test HTTP to HTTPS redirect
print_status "Testing HTTP to HTTPS redirect..."
if curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN | grep -q "301\|302"; then
    print_success "HTTP to HTTPS redirect working"
else
    print_warning "HTTP to HTTPS redirect may not be working"
fi

# Test HTTPS
print_status "Testing HTTPS connection..."
if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN | grep -q "200"; then
    print_success "HTTPS connection working"
else
    print_warning "HTTPS connection may have issues"
fi

# Test application health
print_status "Testing application health..."
if curl -s https://$DOMAIN/health/ | grep -q "healthy"; then
    print_success "Application health check passed"
else
    print_warning "Application health check failed"
fi

# Final status
print_header "SSL Setup Complete!"
print_success "SSL certificate installed for $DOMAIN"
print_success "Automatic renewal configured"
print_success "Services restarted"

print_warning "Access your application:"
print_status "🌐 Application: https://$DOMAIN"
print_status "🔧 Admin Panel: https://$DOMAIN/admin/"
print_status "❤️ Health Check: https://$DOMAIN/health/"
print_status "📡 API: https://$DOMAIN/api/"

print_warning "Next steps:"
print_warning "1. Test your application thoroughly"
print_warning "2. Update your frontend to use HTTPS"
print_warning "3. Monitor SSL certificate expiration"
print_warning "4. Set up monitoring for SSL certificate"

echo ""
echo -e "${GREEN}🎉 SSL setup completed successfully!${NC}"
echo -e "${PURPLE}Your CampsHub360 application is now secured with HTTPS.${NC}"
