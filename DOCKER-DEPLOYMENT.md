# CampsHub360 Docker Deployment Guide

This guide provides comprehensive instructions for deploying CampsHub360 backend as a Docker container optimized for handling 20k+ users per second on AWS EC2.

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- AWS EC2 instance (recommended: t3.large or larger)
- Domain name (optional, for SSL)
- SSH access to your EC2 instance

### 1. Local Development Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd campshub360-backend

# Start local development environment
docker-compose up -d

# Access the application
# - Main app: http://localhost
# - Load balancer test: http://localhost:8080
```

### 2. Production Deployment

#### Step 1: Prepare Environment Variables

Create a `.env.production` file with your production settings:

```bash
# Database Configuration
POSTGRES_DB=campushub360
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-strong-password-here
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Django Configuration
SECRET_KEY=your-super-secret-key-change-this-in-production-at-least-50-characters-long
DEBUG=False
DJANGO_SETTINGS_MODULE=campshub360.production

# Security Settings
SECURE_SSL_REDIRECT=True
CSRF_COOKIE_SECURE=True
SESSION_COOKIE_SECURE=True

# Performance Settings (Optimized for 20k+ users/sec)
GUNICORN_WORKERS=16
GUNICORN_WORKER_CLASS=gevent
GUNICORN_WORKER_CONNECTIONS=1000

# CORS Settings
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
CSRF_TRUSTED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Allowed Hosts
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,your-ec2-ip

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
```

#### Step 2: Deploy to AWS EC2

**For Linux/Mac:**
```bash
# Set your EC2 instance IP
export EC2_INSTANCE_IP=your-ec2-ip-address

# Run deployment script
./deploy-aws.sh
```

**For Windows:**
```cmd
# Set your EC2 instance IP
set EC2_INSTANCE_IP=your-ec2-ip-address

# Run deployment script
deploy-aws.bat
```

#### Step 3: Manual Deployment (Alternative)

If you prefer manual deployment:

```bash
# 1. Build the Docker image
docker build -t campshub360-backend:latest .

# 2. Copy files to EC2
scp docker-compose.production.yml ubuntu@your-ec2-ip:/home/ubuntu/
scp .env.production ubuntu@your-ec2-ip:/home/ubuntu/.env
scp nginx-production-lb.conf ubuntu@your-ec2-ip:/home/ubuntu/

# 3. Transfer Docker image
docker save campshub360-backend:latest | gzip | ssh ubuntu@your-ec2-ip "gunzip | docker load"

# 4. Deploy on EC2
ssh ubuntu@your-ec2-ip
cd /home/ubuntu
docker-compose -f docker-compose.production.yml up -d
```

## 🏗️ Architecture Overview

### High-Performance Configuration

The deployment is optimized for 20k+ users per second with:

- **Multiple Django Instances**: 4 replicas with load balancing
- **Nginx Load Balancer**: Handles SSL termination and request distribution
- **Redis Caching**: Session storage and query caching
- **PostgreSQL**: Optimized database configuration
- **Gunicorn with Gevent**: Async workers for high concurrency

### Container Structure

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx LB      │    │   Django App    │    │   PostgreSQL    │
│   (Port 80/443) │───▶│   (Port 8000)   │───▶│   (Port 5432)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │     Redis       │
                       │   (Port 6379)   │
                       └─────────────────┘
```

## ⚙️ Performance Optimizations

### Gunicorn Configuration

- **Workers**: 16 (2x CPU cores + 1)
- **Worker Class**: Gevent (async)
- **Worker Connections**: 1000 per worker
- **Max Requests**: 1000 (prevents memory leaks)
- **Keepalive**: 5 seconds

### Nginx Configuration

- **Worker Processes**: Auto (CPU cores)
- **Worker Connections**: 4096
- **Rate Limiting**: 100 req/s for API, 10 req/m for login
- **Gzip Compression**: Enabled
- **Static File Caching**: 1 year

### Database Optimizations

- **Connection Pooling**: 10-minute max age
- **Shared Buffers**: 256MB
- **Effective Cache Size**: 1GB
- **Work Memory**: 4MB

## 🔧 Configuration Options

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GUNICORN_WORKERS` | 16 | Number of Gunicorn workers |
| `GUNICORN_WORKER_CLASS` | gevent | Worker class (gevent/uvicorn) |
| `GUNICORN_WORKER_CONNECTIONS` | 1000 | Connections per worker |
| `POSTGRES_HOST` | db | Database host |
| `REDIS_URL` | redis://redis:6379/0 | Redis connection URL |
| `SECRET_KEY` | - | Django secret key (required) |

### Scaling Options

To handle more users, you can:

1. **Increase Workers**: Set `GUNICORN_WORKERS=32`
2. **Add More Instances**: Increase replicas in docker-compose
3. **Use External Services**: 
   - AWS RDS for PostgreSQL
   - AWS ElastiCache for Redis
   - AWS Application Load Balancer

## 📊 Monitoring and Logs

### View Logs

```bash
# All services
docker-compose -f docker-compose.production.yml logs -f

# Specific service
docker-compose -f docker-compose.production.yml logs -f web
docker-compose -f docker-compose.production.yml logs -f nginx
```

### Health Checks

- **Application Health**: `http://your-domain/health/`
- **Container Status**: `docker-compose -f docker-compose.production.yml ps`

### Performance Monitoring

The application includes:
- Request/response time logging
- Database query monitoring
- Redis cache hit/miss tracking
- Nginx access logs with timing

## 🔒 Security Features

### SSL/TLS Configuration

1. **Automatic HTTPS Redirect**: HTTP traffic redirected to HTTPS
2. **Modern TLS**: TLS 1.2 and 1.3 only
3. **Strong Ciphers**: ECDHE and DHE cipher suites
4. **HSTS**: HTTP Strict Transport Security enabled

### Security Headers

- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000`
- `Content-Security-Policy`

### Rate Limiting

- **API Endpoints**: 100 requests/second
- **Login Endpoints**: 10 requests/minute
- **Connection Limits**: 50 connections per IP

## 🚨 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   ```bash
   # Check database container
   docker-compose -f docker-compose.production.yml logs db
   
   # Test connection
   docker-compose -f docker-compose.production.yml exec web python manage.py dbshell
   ```

2. **High Memory Usage**
   ```bash
   # Check memory usage
   docker stats
   
   # Reduce workers if needed
   export GUNICORN_WORKERS=8
   docker-compose -f docker-compose.production.yml up -d
   ```

3. **SSL Certificate Issues**
   ```bash
   # Check certificate files
   ls -la /etc/ssl/certs/campshub360.crt
   ls -la /etc/ssl/private/campshub360.key
   
   # Test SSL
   openssl s_client -connect your-domain.com:443
   ```

### Performance Tuning

1. **Database Optimization**
   ```sql
   -- Check slow queries
   SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;
   
   -- Add indexes for frequently queried fields
   CREATE INDEX CONCURRENTLY idx_field_name ON table_name (field_name);
   ```

2. **Redis Optimization**
   ```bash
   # Check Redis memory usage
   docker-compose -f docker-compose.production.yml exec redis redis-cli info memory
   
   # Monitor cache hit rate
   docker-compose -f docker-compose.production.yml exec redis redis-cli info stats
   ```

## 📈 Scaling for Higher Load

### Horizontal Scaling

1. **Multiple EC2 Instances**
   - Deploy on 2-3 EC2 instances
   - Use AWS Application Load Balancer
   - Configure auto-scaling groups

2. **Database Scaling**
   - Use AWS RDS with read replicas
   - Implement database sharding
   - Add connection pooling (PgBouncer)

3. **Cache Scaling**
   - Use AWS ElastiCache Redis cluster
   - Implement cache warming strategies
   - Add CDN for static assets

### Vertical Scaling

1. **Increase EC2 Instance Size**
   - t3.large → t3.xlarge → t3.2xlarge
   - Adjust `GUNICORN_WORKERS` accordingly

2. **Optimize Database**
   - Increase RDS instance size
   - Add read replicas
   - Optimize queries and indexes

## 🔄 Updates and Maintenance

### Application Updates

```bash
# 1. Build new image
docker build -t campshub360-backend:new-version .

# 2. Update deployment
export DOCKER_TAG=new-version
./deploy-aws.sh

# 3. Rollback if needed
export DOCKER_TAG=previous-version
./deploy-aws.sh
```

### Database Migrations

```bash
# Run migrations
docker-compose -f docker-compose.production.yml exec web python manage.py migrate

# Create superuser
docker-compose -f docker-compose.production.yml exec web python manage.py createsuperuser
```

### Backup Strategy

```bash
# Database backup
docker-compose -f docker-compose.production.yml exec db pg_dump -U postgres campushub360 > backup.sql

# Media files backup
tar -czf media-backup.tar.gz media/

# Restore database
docker-compose -f docker-compose.production.yml exec -T db psql -U postgres campushub360 < backup.sql
```

## 📞 Support

For issues and questions:
1. Check the logs first
2. Review this documentation
3. Check Django and Docker documentation
4. Create an issue in the repository

---

**Note**: This deployment is optimized for high-traffic scenarios. For smaller applications, you can reduce the number of workers and instances to save resources.
