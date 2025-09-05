# CampsHub360 AWS EC2 Deployment Guide

This guide provides step-by-step instructions for deploying CampsHub360 on AWS EC2 with production-ready configuration.

## Prerequisites

- AWS Account with appropriate permissions
- EC2 instance running Ubuntu 20.04+ or Amazon Linux 2
- Domain name (optional, for SSL certificates)
- Basic knowledge of AWS services

## Quick Start

### 1. Launch EC2 Instance

**Recommended Instance Type:** t3.medium or larger
**Storage:** 20GB+ EBS volume
**Security Groups:** Allow HTTP (80), HTTPS (443), SSH (22)

```bash
# Connect to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

### 2. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/your-repo/campshub360-backend.git
cd campshub360-backend

# Make scripts executable
chmod +x *.sh

# Run initial setup
sudo ./setup_aws_ec2.sh
```

### 3. Configure Production Environment

```bash
# Run configuration script
./configure_production.sh
```

This will prompt you for:
- Domain name
- Database configuration (RDS or local)
- Redis configuration (ElastiCache or local)
- Email configuration (SES)

### 4. Deploy Application

```bash
# Run deployment
sudo ./deploy.sh
```

### 5. Setup Database and Redis

```bash
# Setup database
./setup_database.sh

# Setup Redis
./setup_redis.sh
```

### 6. Setup SSL (if using domain)

```bash
# Setup SSL certificates
./setup_ssl.sh yourdomain.com
```

## Detailed Configuration

### AWS Services Setup

#### 1. RDS PostgreSQL Database

```bash
# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier campshub360-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --master-username campshub360_user \
    --master-user-password your-secure-password \
    --allocated-storage 20 \
    --vpc-security-group-ids sg-your-security-group \
    --db-subnet-group-name your-subnet-group
```

#### 2. ElastiCache Redis

```bash
# Create Redis cluster
aws elasticache create-cache-cluster \
    --cache-cluster-id campshub360-redis \
    --cache-node-type cache.t3.micro \
    --engine redis \
    --num-cache-nodes 1 \
    --security-group-ids sg-your-security-group
```

#### 3. SES Email Service

1. Verify your domain in AWS SES
2. Create SMTP credentials
3. Update `.env` file with SES details

### Environment Variables

The `.env` file contains all production configuration:

```bash
# Django Settings
SECRET_KEY=your-super-secret-key
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,your-ec2-ip

# Database Configuration
POSTGRES_DB=campshub360_prod
POSTGRES_USER=campshub360_user
POSTGRES_PASSWORD=your-secure-password
POSTGRES_HOST=your-rds-endpoint.region.rds.amazonaws.com
POSTGRES_PORT=5432

# Redis Configuration
REDIS_URL=redis://your-elasticache-endpoint:6379/1

# Email Configuration
EMAIL_HOST=email-smtp.region.amazonaws.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-ses-smtp-username
EMAIL_HOST_PASSWORD=your-ses-smtp-password
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
```

### Security Configuration

#### 1. Security Groups

Ensure your EC2 security group allows:
- SSH (22) from your IP
- HTTP (80) from anywhere
- HTTPS (443) from anywhere
- Custom TCP (8000) from localhost (for health checks)

#### 2. SSL/TLS Configuration

The deployment includes:
- Automatic HTTP to HTTPS redirect
- HSTS headers
- Secure cookie settings
- CSRF protection

#### 3. Firewall Configuration

```bash
# UFW is configured automatically
sudo ufw status
```

### Monitoring and Logging

#### 1. Health Checks

The application provides several health check endpoints:

- `/health/` - Basic health check
- `/health/detailed/` - Detailed system metrics
- `/health/ready/` - Readiness probe
- `/health/alive/` - Liveness probe

#### 2. Logging

Logs are stored in:
- Application logs: `/var/log/django/campshub360.log`
- Nginx logs: `/var/log/nginx/`
- System logs: `journalctl -u campshub360`

#### 3. Monitoring Scripts

Automated monitoring includes:
- Service status checks (every 5 minutes)
- Disk space monitoring
- Memory usage monitoring
- Automated backups (daily at 2 AM)

### Backup Strategy

#### 1. Automated Backups

Daily backups are created automatically:
- Database dump (if using local PostgreSQL)
- Application files (excluding cache and logs)
- Retention: 7 days

#### 2. Manual Backup

```bash
# Run manual backup
sudo /usr/local/bin/backup_campshub360.sh
```

#### 3. Restore from Backup

```bash
# Restore database
sudo -u postgres psql campshub360_prod < /app/backups/backup_db.sql

# Restore application files
tar -xzf /app/backups/backup_app.tar.gz -C /app/
```

### Scaling and Performance

#### 1. Horizontal Scaling

To scale horizontally:
1. Launch additional EC2 instances
2. Use Application Load Balancer
3. Configure shared Redis and RDS
4. Update nginx upstream configuration

#### 2. Vertical Scaling

To scale vertically:
1. Change EC2 instance type
2. Increase RDS instance class
3. Scale ElastiCache cluster

#### 3. Performance Optimization

The deployment includes:
- Gunicorn with gevent workers
- Redis caching
- Static file optimization
- Database connection pooling

### Troubleshooting

#### 1. Service Status

```bash
# Check service status
sudo systemctl status campshub360
sudo systemctl status nginx

# Check logs
sudo journalctl -u campshub360 -f
sudo tail -f /var/log/nginx/campshub360_error.log
```

#### 2. Database Issues

```bash
# Test database connection
python manage.py dbshell

# Check database status
sudo systemctl status postgresql
```

#### 3. Redis Issues

```bash
# Test Redis connection
redis-cli ping

# Check Redis status
sudo systemctl status redis-server
```

#### 4. SSL Issues

```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew
```

### Maintenance

#### 1. Regular Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update application
git pull origin main
sudo ./deploy.sh
```

#### 2. Log Rotation

Logs are automatically rotated:
- Daily rotation
- 30 days retention
- Compression enabled

#### 3. Security Updates

```bash
# Check for security updates
sudo unattended-upgrades --dry-run

# Apply security updates
sudo unattended-upgrades
```

### Cost Optimization

#### 1. Instance Types

- Development: t3.micro
- Production: t3.medium or larger
- Use Spot instances for non-critical workloads

#### 2. Storage

- Use GP3 EBS volumes for better price/performance
- Enable EBS optimization
- Use S3 for static files

#### 3. Database

- Use RDS Reserved Instances for predictable workloads
- Enable automated backups
- Use read replicas for read-heavy workloads

## Support

For issues and questions:
1. Check the logs first
2. Review this documentation
3. Check AWS service status
4. Contact support team

## Security Considerations

1. **Never commit secrets** to version control
2. **Use IAM roles** instead of access keys when possible
3. **Enable CloudTrail** for audit logging
4. **Use VPC** for network isolation
5. **Regular security updates** and patches
6. **Monitor access logs** and unusual activity
7. **Use AWS WAF** for additional protection
8. **Enable AWS Config** for compliance monitoring

## Production Checklist

- [ ] EC2 instance launched with appropriate size
- [ ] Security groups configured correctly
- [ ] RDS PostgreSQL database created
- [ ] ElastiCache Redis cluster created
- [ ] SES email service configured
- [ ] Domain name configured and verified
- [ ] SSL certificates installed
- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] Static files collected
- [ ] Services running and healthy
- [ ] Monitoring and logging configured
- [ ] Backup strategy implemented
- [ ] Security hardening applied
- [ ] Performance testing completed
- [ ] Documentation updated
