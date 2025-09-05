# CampsHub360 AWS EC2 Deployment Guide

Complete step-by-step guide to deploy your CampsHub360 backend on AWS EC2.

## 📋 Prerequisites

Before starting, ensure you have:
- AWS Account with appropriate permissions
- Domain name (optional but recommended)
- Basic knowledge of AWS services

## 🚀 Step 1: Launch EC2 Instance

### 1.1 Login to AWS Console
1. Go to [AWS Console](https://console.aws.amazon.com)
2. Sign in with your AWS account
3. Navigate to **EC2** service

### 1.2 Launch Instance
1. Click **"Launch Instance"**
2. **Name**: `campshub360-backend`
3. **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
4. **Instance Type**: 
   - `t3.medium` (2 vCPU, 4GB RAM) - Recommended
   - `t3.large` (2 vCPU, 8GB RAM) - For higher traffic
5. **Key Pair**: Create new or select existing
6. **Security Group**: Create new with these rules:
   - SSH (22) - Your IP
   - HTTP (80) - Anywhere (0.0.0.0/0)
   - HTTPS (443) - Anywhere (0.0.0.0/0)
   - Custom TCP (8000) - Anywhere (0.0.0.0/0)
7. **Storage**: 20GB gp3 (minimum)
8. Click **"Launch Instance"**

### 1.3 Get Instance Details
1. Note your **Public IPv4 address**
2. Note your **Instance ID**
3. Wait for instance to be in "Running" state

## 🗄️ Step 2: Set Up RDS Database

### 2.1 Create RDS Instance
1. Go to **RDS** service in AWS Console
2. Click **"Create database"**
3. **Engine**: PostgreSQL
4. **Version**: PostgreSQL 15.x
5. **Templates**: Free tier (if eligible) or Production
6. **DB Instance Identifier**: `campshub360-db`
7. **Master Username**: `postgres`
8. **Master Password**: Create strong password (save it!)
9. **DB Instance Class**: `db.t3.micro` (free tier) or `db.t3.small`
10. **Storage**: 20GB (minimum)
11. **VPC**: Default VPC
12. **Subnet Group**: Default
13. **Public Access**: Yes
14. **VPC Security Groups**: Create new
15. **Database Name**: `campshub360`
16. Click **"Create database"**

### 2.2 Configure RDS Security Group
1. Go to **EC2** → **Security Groups**
2. Find your RDS security group
3. **Edit Inbound Rules**
4. Add rule:
   - **Type**: PostgreSQL
   - **Port**: 5432
   - **Source**: Your EC2 security group ID
5. **Save rules**

## 🔴 Step 3: Set Up ElastiCache Redis

### 3.1 Create Redis Cluster
1. Go to **ElastiCache** service
2. Click **"Create cluster"**
3. **Cluster mode**: Disabled
4. **Name**: `campshub360-redis`
5. **Node type**: `cache.t3.micro` (free tier)
6. **Number of replicas**: 0
7. **Subnet group**: Default
8. **Security groups**: Create new
9. Click **"Create cluster"**

### 3.2 Configure Redis Security Group
1. Go to **EC2** → **Security Groups**
2. Find your Redis security group
3. **Edit Inbound Rules**
4. Add rule:
   - **Type**: Custom TCP
   - **Port**: 6379
   - **Source**: Your EC2 security group ID
5. **Save rules**

## 🔗 Step 4: Connect to EC2 Instance

### 4.1 SSH Connection
```bash
# Replace with your key file and public IP
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

### 4.2 Update System
```bash
sudo apt update && sudo apt upgrade -y
```

## 📦 Step 5: Deploy Application

### 5.1 Clone Repository
```bash
# Clone your repository
git clone <your-repo-url> /app
cd /app

# Make deployment script executable
chmod +x deploy.sh
```

### 5.2 Configure Environment
```bash
# Create .env file
nano .env
```

Add your configuration:
```env
# Django Settings
SECRET_KEY=your-super-secret-key-here
DEBUG=False
ALLOWED_HOSTS=your-ec2-public-ip,your-domain.com

# Database (AWS RDS)
POSTGRES_DB=campshub360
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-rds-password
POSTGRES_HOST=your-rds-endpoint.region.rds.amazonaws.com
POSTGRES_PORT=5432

# Redis (AWS ElastiCache)
REDIS_URL=redis://your-redis-endpoint:6379/1

# Performance Settings
GUNICORN_WORKERS=4
GUNICORN_WORKER_CLASS=gevent
GUNICORN_WORKER_CONNECTIONS=1000
```

### 5.3 Run Deployment
```bash
# Run the deployment script
sudo ./deploy.sh
```

The script will:
- Install dependencies
- Test AWS connections
- Run database migrations
- Set up services
- Configure nginx

## 🔧 Step 6: Configure Domain (Optional)

### 6.1 Point Domain to EC2
1. Go to your domain registrar
2. Update DNS A record to point to your EC2 public IP
3. Wait for DNS propagation (5-30 minutes)

### 6.2 Update Environment
```bash
# Update .env file with domain
nano .env
```

Update `ALLOWED_HOSTS`:
```env
ALLOWED_HOSTS=your-ec2-public-ip,your-domain.com,www.your-domain.com
```

### 6.3 Restart Services
```bash
sudo systemctl restart campshub360
sudo systemctl restart nginx
```

## 🔒 Step 7: Set Up SSL Certificate

### 7.1 Install Certbot
```bash
sudo apt install certbot python3-certbot-nginx -y
```

### 7.2 Obtain SSL Certificate
```bash
# Replace with your domain
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

### 7.3 Test Auto-renewal
```bash
sudo certbot renew --dry-run
```

## ✅ Step 8: Verify Deployment

### 8.1 Check Services
```bash
# Check service status
sudo systemctl status campshub360
sudo systemctl status nginx

# Check logs
sudo journalctl -u campshub360 -f
```

### 8.2 Test Endpoints
```bash
# Test health check
curl http://your-domain.com/health/

# Test API
curl http://your-domain.com/api/

# Test admin panel
curl http://your-domain.com/admin/
```

### 8.3 Access Application
- **Application**: `http://your-domain.com`
- **Admin Panel**: `http://your-domain.com/admin/`
- **API**: `http://your-domain.com/api/`
- **Health Check**: `http://your-domain.com/health/`

## 🔧 Step 9: Post-Deployment Configuration

### 9.1 Change Admin Password
```bash
# Create new superuser or change password
python manage.py changepassword admin
```

### 9.2 Configure Monitoring
```bash
# Set up log rotation
sudo nano /etc/logrotate.d/campshub360
```

### 9.3 Set Up Backups
```bash
# Create backup script
sudo nano /usr/local/bin/backup-db.sh
```

## 🆘 Troubleshooting

### Common Issues

#### Database Connection Failed
```bash
# Check RDS security groups
# Ensure EC2 security group can access RDS on port 5432

# Test connection manually
PGPASSWORD=your-password psql -h your-rds-endpoint -U postgres -d campshub360
```

#### Redis Connection Failed
```bash
# Check ElastiCache security groups
# Ensure EC2 security group can access Redis on port 6379

# Test connection manually
redis-cli -h your-redis-endpoint -p 6379 ping
```

#### Service Won't Start
```bash
# Check service status
sudo systemctl status campshub360

# Check logs
sudo journalctl -u campshub360 -f

# Test configuration
python manage.py check --deploy
```

#### Static Files Not Loading
```bash
# Collect static files
python manage.py collectstatic --noinput

# Check nginx configuration
sudo nginx -t

# Check file permissions
sudo chown -R www-data:www-data /app/staticfiles
```

## 📊 Monitoring Commands

### Service Management
```bash
# Check service status
sudo systemctl status campshub360
sudo systemctl status nginx

# Restart services
sudo systemctl restart campshub360
sudo systemctl restart nginx

# View logs
sudo journalctl -u campshub360 -f
sudo tail -f /var/log/nginx/campshub360_access.log
```

### Health Checks
```bash
# Basic health check
curl http://your-domain.com/health/

# Detailed health check
curl http://your-domain.com/health/detailed/

# Check system resources
htop
df -h
free -h
```

## 🔄 Maintenance

### Regular Tasks
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Restart services
sudo systemctl restart campshub360

# Check disk space
df -h

# Monitor logs
sudo journalctl -u campshub360 --since "1 hour ago"
```

### Backup Database
```bash
# Create backup
PGPASSWORD=your-password pg_dump -h your-rds-endpoint -U postgres campshub360 > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
PGPASSWORD=your-password psql -h your-rds-endpoint -U postgres campshub360 < backup_file.sql
```

## 🎉 Deployment Complete!

Your CampsHub360 backend is now successfully deployed on AWS EC2 with:

- ✅ **EC2 Instance** running Ubuntu
- ✅ **RDS PostgreSQL** database
- ✅ **ElastiCache Redis** for caching
- ✅ **Nginx** reverse proxy
- ✅ **SSL Certificate** (if configured)
- ✅ **Health monitoring**
- ✅ **Log management**

### Access Your Application:
- **Main App**: `https://your-domain.com`
- **Admin Panel**: `https://your-domain.com/admin/`
- **API**: `https://your-domain.com/api/`
- **Health Check**: `https://your-domain.com/health/`

### Default Credentials:
- **Username**: `admin`
- **Password**: `admin123` (change this!)

---

**CampsHub360** - Successfully deployed on AWS EC2! 🚀
