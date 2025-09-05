# CampsHub360 Backend

Educational institution management system - Production ready for AWS EC2 deployment.

## 🚀 Quick Deployment

### Prerequisites
- AWS EC2 (Ubuntu 22.04+)
- AWS RDS PostgreSQL
- AWS ElastiCache Redis

### Deploy
```bash
git clone <your-repo-url> /app
cd /app
sudo ./deploy.sh
```

## 🔧 Configuration

Create `.env` file:
```env
SECRET_KEY=your-secret-key
DEBUG=False
ALLOWED_HOSTS=your-ec2-ip,your-domain.com
POSTGRES_HOST=your-rds-endpoint.region.rds.amazonaws.com
POSTGRES_PASSWORD=your-password
REDIS_URL=redis://your-redis-endpoint:6379/1
```

## 📚 API Endpoints

- `GET /api/v1/students/students/` - Students
- `GET /api/v1/faculty/api/faculty/` - Faculty
- `GET /api/v1/academics/api/courses/` - Courses
- `GET /health/` - Health check
- `POST /api/auth/token/` - Authentication

## 🛠️ Stack

- Django 5.1.4
- PostgreSQL
- Redis
- Gunicorn
- Nginx

## 🐳 Docker

```bash
docker-compose -f docker-compose.ec2.yml up -d
```

## 📊 Monitoring

- Health: `http://your-domain/health/`
- Logs: `sudo journalctl -u campshub360 -f`
- Status: `sudo systemctl status campshub360`

## 🆘 Commands

```bash
sudo systemctl restart campshub360
sudo journalctl -u campshub360 -f
python manage.py check --deploy
```

---

**CampsHub360** - Production Ready