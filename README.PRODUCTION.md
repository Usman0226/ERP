# CampsHub360 Production Deployment Guide

This guide covers deploying CampsHub360 to AWS EC2 for production use.

## Prerequisites

- AWS EC2 instance (Ubuntu 20.04+ recommended)
- Domain name (optional but recommended)
- SSL certificate (Let's Encrypt or AWS Certificate Manager)
- AWS RDS PostgreSQL instance (recommended)
- AWS ElastiCache Redis instance (optional)

## Quick Start

### 1. Prepare Your EC2 Instance

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3 python3-pip python3-venv python3-dev \
    postgresql-client nginx redis-tools \
    build-essential libpq-dev libssl-dev libffi-dev git

# Create application user
sudo adduser --system --group --home /app campshub360
```

### 2. Deploy the Application

```bash
# Clone the repository
sudo git clone <your-repo-url> /app
sudo chown -R campshub360:campshub360 /app

# Switch to application user
sudo su - campshub360

# Set up environment
cd /app
cp env.production.example .env
# Edit .env with your production values

# Run deployment script
chmod +x deploy.sh
./deploy.sh
```

### 3. Configure Environment Variables

Edit `/app/.env` with your production values:

```bash
# Django Settings
SECRET_KEY=your-super-secret-key-here
DEBUG=False
ALLOWED_HOSTS=your-ec2-public-ip,your-domain.com

# Database (AWS RDS)
POSTGRES_DB=campshub360_prod
POSTGRES_USER=campshub360_user
POSTGRES_PASSWORD=your-secure-password
POSTGRES_HOST=your-rds-endpoint.region.rds.amazonaws.com
POSTGRES_PORT=5432

# Redis (AWS ElastiCache)
REDIS_URL=redis://your-elasticache-endpoint:6379/1

# Email (AWS SES)
EMAIL_HOST=email-smtp.us-east-1.amazonaws.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-ses-username
EMAIL_HOST_PASSWORD=your-ses-password
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
```

### 4. Set Up SSL Certificate

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

### 5. Configure Nginx

Update `/etc/nginx/sites-available/campshub360` with your domain name:

```nginx
server_name your-domain.com www.your-domain.com;
```

### 6. Start Services

```bash
sudo systemctl start campshub360
sudo systemctl start nginx
sudo systemctl enable campshub360
sudo systemctl enable nginx
```

## Docker Deployment (Alternative)

If you prefer containerized deployment:

```bash
# Build and run with Docker Compose
docker-compose -f docker-compose.production.yml up -d

# Run migrations
docker-compose -f docker-compose.production.yml exec web python manage.py migrate

# Create superuser
docker-compose -f docker-compose.production.yml exec web python manage.py createsuperuser
```

## Security Checklist

- [ ] Change default admin password
- [ ] Set up AWS RDS with SSL
- [ ] Configure AWS ElastiCache
- [ ] Set up AWS SES for emails
- [ ] Configure firewall (only ports 80, 443, 22)
- [ ] Set up regular backups
- [ ] Monitor logs and performance
- [ ] Set up SSL certificate
- [ ] Configure CORS properly
- [ ] Enable security headers

## Monitoring and Maintenance

### Log Files
- Application logs: `/var/log/django/campshub360.log`
- Nginx logs: `/var/log/nginx/campshub360_*.log`
- System logs: `journalctl -u campshub360`

### Backup Strategy
```bash
# Database backup
pg_dump -h your-rds-endpoint -U campshub360_user campshub360_prod > backup_$(date +%Y%m%d).sql

# Application backup
tar -czf app_backup_$(date +%Y%m%d).tar.gz /app
```

### Performance Monitoring
```bash
# Check service status
sudo systemctl status campshub360
sudo systemctl status nginx

# Monitor resources
htop
df -h
free -h
```

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   ```bash
   # Test database connection
   python manage.py dbshell
   ```

2. **Static Files Not Loading**
   ```bash
   # Recollect static files
   python manage.py collectstatic --noinput
   ```

3. **Permission Issues**
   ```bash
   # Fix permissions
   sudo chown -R www-data:www-data /app
   sudo chmod -R 755 /app
   ```

4. **Service Won't Start**
   ```bash
   # Check logs
   sudo journalctl -u campshub360 -f
   ```

### Health Checks

```bash
# Application health
curl http://localhost:8000/health/

# Database health
curl http://localhost:8000/health/detailed/
```

## Scaling

For high-traffic deployments:

1. **Load Balancing**: Use AWS Application Load Balancer
2. **Database**: Use AWS RDS with read replicas
3. **Caching**: Use AWS ElastiCache Redis cluster
4. **Static Files**: Use AWS S3 + CloudFront
5. **Auto Scaling**: Use AWS Auto Scaling Groups

## Support

For issues and questions:
1. Check the logs first
2. Review this documentation
3. Check Django and system status
4. Contact your system administrator

## Security Notes

- Never commit `.env` files to version control
- Use strong passwords and rotate them regularly
- Keep system packages updated
- Monitor access logs
- Use AWS Security Groups to restrict access
- Enable AWS CloudTrail for audit logging
