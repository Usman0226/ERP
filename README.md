# CampsHub360 Backend

A comprehensive Django-based backend system for educational institution management, optimized for AWS EC2 deployment.

## 🚀 Quick Start

### Prerequisites
- AWS EC2 instance (Ubuntu 20.04+)
- AWS RDS PostgreSQL database
- AWS ElastiCache Redis cluster

### Deploy to EC2

```bash
# Clone repository
git clone <your-repo-url> /app
cd /app

# Run deployment script
sudo ./deploy.sh
```

The script will:
- Install dependencies
- Test AWS connections
- Run database migrations
- Set up services
- Configure nginx

## 🔧 Configuration

Create `.env` file with your settings:

```env
# Django Settings
SECRET_KEY=your-super-secret-key-here
DEBUG=False
ALLOWED_HOSTS=your-ec2-ip,your-domain.com

# Database (AWS RDS)
POSTGRES_DB=campshub360
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-secure-password
POSTGRES_HOST=your-rds-endpoint.region.rds.amazonaws.com
POSTGRES_PORT=5432

# Redis (AWS ElastiCache)
REDIS_URL=redis://your-elasticache-endpoint:6379/1
```

## 📚 API Endpoints

### Authentication
```http
POST /api/auth/token/
{
    "username": "your_username",
    "password": "your_password"
}
```

### Key Endpoints
- `GET /api/v1/students/students/` - List students
- `GET /api/v1/faculty/api/faculty/` - List faculty
- `GET /api/v1/academics/api/courses/` - List courses
- `GET /health/` - Health check

## 🛠️ Technology Stack

- **Django 5.2.5** - Web framework
- **PostgreSQL** - Database
- **Redis** - Caching
- **Gunicorn** - WSGI server
- **Nginx** - Web server

## 🐳 Docker Deployment

```bash
# Build and run with Docker
docker-compose -f docker-compose.ec2.yml up -d
```

## 📊 Monitoring

- Health check: `http://your-domain/health/`
- Logs: `sudo journalctl -u campshub360 -f`
- Service status: `sudo systemctl status campshub360`

## 🔒 Security

- SSL/TLS ready
- Security headers
- CSRF protection
- Rate limiting
- Firewall configuration

## 🆘 Support

### Common Commands
```bash
# Check service status
sudo systemctl status campshub360

# View logs
sudo journalctl -u campshub360 -f

# Restart service
sudo systemctl restart campshub360

# Test configuration
python manage.py check --deploy
```

### Troubleshooting
- **Database connection**: Check RDS security groups
- **Redis connection**: Check ElastiCache security groups
- **Static files**: Run `python manage.py collectstatic --noinput`

---

**CampsHub360** - Educational Management System