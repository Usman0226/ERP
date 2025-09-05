# CampsHub360 Backend - Production Ready

A comprehensive Django-based backend system for educational institution management, optimized for production deployment on AWS EC2.

## 🚀 Features

### Core Management
- **Student Management**: Complete student lifecycle management with enrollment, documents, and custom fields
- **Faculty Management**: Comprehensive faculty administration with performance tracking and leave management
- **Academic Management**: Course management, timetables, and academic calendar
- **Attendance System**: Real-time attendance tracking and reporting
- **Exam Management**: Complete exam lifecycle from scheduling to results
- **Fee Management**: Comprehensive fee structure and payment tracking
- **Placement Management**: Job placement and career services
- **Research & Development**: Research project and publication management
- **Transportation**: Bus routes and student transportation management
- **Mentoring**: Faculty-student mentoring programs
- **Feedback System**: Comprehensive feedback and rating system

### Technical Features
- **RESTful APIs**: 400+ well-structured REST endpoints
- **JWT Authentication**: Secure token-based authentication
- **Production Ready**: Optimized for AWS EC2 deployment
- **High Performance**: Rate limiting, caching, and optimization
- **Security**: Comprehensive security headers and protection
- **Monitoring**: Built-in health checks and performance monitoring
- **Scalable**: Designed for horizontal scaling

## 🛠️ Technology Stack

- **Backend Framework**: Django 5.2.5
- **API Framework**: Django REST Framework 3.16.1
- **Authentication**: JWT with Simple JWT 5.5.1
- **Database**: PostgreSQL (production ready)
- **Caching**: Redis support
- **Server**: Gunicorn with Gevent workers
- **Web Server**: Nginx
- **Deployment**: Docker & Systemd support

## 🚀 Quick Production Deployment

### Prerequisites
- AWS EC2 instance (Ubuntu 20.04+)
- Domain name (optional)
- SSL certificate
- AWS RDS PostgreSQL (recommended)
- AWS ElastiCache Redis (optional)

### 1. Clone and Setup

```bash
# Clone repository
git clone <your-repo-url> /app
cd /app

# Set up environment
cp env.production.example .env
# Edit .env with your production values
```

### 2. Deploy

```bash
# Make deployment script executable
chmod +x deploy.sh

# Run deployment (requires sudo for system setup)
./deploy.sh
```

### 3. Configure

Update your `.env` file with production values:

```env
SECRET_KEY=your-super-secret-key-here
DEBUG=False
ALLOWED_HOSTS=your-ec2-ip,your-domain.com

# Database (AWS RDS)
POSTGRES_DB=campshub360_prod
POSTGRES_USER=campshub360_user
POSTGRES_PASSWORD=your-secure-password
POSTGRES_HOST=your-rds-endpoint.region.rds.amazonaws.com

# Redis (AWS ElastiCache)
REDIS_URL=redis://your-elasticache-endpoint:6379/1
```

## 📚 API Documentation

### Authentication
```http
POST /api/auth/token/
{
    "username": "your_username",
    "password": "your_password"
}
```

### Key API Endpoints

#### Students
- `GET /api/v1/students/students/` - List students
- `POST /api/v1/students/students/` - Create student
- `GET /api/v1/students/students/{id}/` - Student details

#### Faculty
- `GET /api/v1/faculty/api/faculty/` - List faculty
- `POST /api/v1/faculty/api/faculty/` - Create faculty

#### Academics
- `GET /api/v1/academics/api/courses/` - List courses
- `GET /api/v1/academics/api/timetables/` - Timetables

#### Attendance
- `GET /api/v1/attendance/attendance/sessions/` - Attendance sessions
- `POST /api/v1/attendance/attendance/records/` - Mark attendance

#### Exams
- `GET /api/v1/exams/api/exam-sessions/` - Exam sessions
- `GET /api/v1/exams/api/exam-results/` - Exam results

#### Fees
- `GET /api/v1/fees/api/student-fees/` - Student fees
- `POST /api/v1/fees/api/payments/` - Record payment

### Health Checks
- `GET /health/` - Basic health check
- `GET /health/detailed/` - Detailed system status
- `GET /health/ready/` - Readiness check

## 🏗️ Project Structure

```
campshub360-backend/
├── accounts/                 # User authentication
├── students/                 # Student management
├── faculty/                  # Faculty management
├── academics/                # Academic management
├── attendance/               # Attendance system
├── exams/                    # Exam management
├── fees/                     # Fee management
├── placements/               # Placement services
├── grads/                    # Graduation management
├── rnd/                      # Research & Development
├── facilities/               # Facilities management
├── transportation/           # Transportation services
├── mentoring/                # Mentoring programs
├── feedback/                 # Feedback system
├── open_requests/            # Open requests
├── dashboard/                # Web dashboard
├── campshub360/              # Main configuration
├── requirements.txt          # Production dependencies
├── deploy.sh                 # Deployment script
├── nginx.conf                # Nginx configuration
├── docker-compose.production.yml  # Docker deployment
└── README.PRODUCTION.md      # Detailed deployment guide
```

## 🔧 Configuration

### Environment Variables

Required production environment variables:

```env
# Django
SECRET_KEY=your-secret-key
DEBUG=False
ALLOWED_HOSTS=your-domain.com

# Database
POSTGRES_DB=campshub360_prod
POSTGRES_USER=campshub360_user
POSTGRES_PASSWORD=secure-password
POSTGRES_HOST=your-rds-endpoint

# Redis
REDIS_URL=redis://your-redis-endpoint:6379/1

# Email (AWS SES)
EMAIL_HOST=email-smtp.us-east-1.amazonaws.com
EMAIL_HOST_USER=your-ses-username
EMAIL_HOST_PASSWORD=your-ses-password
```

### Security Features

- SSL/TLS encryption
- Security headers (HSTS, CSP, etc.)
- Rate limiting
- CSRF protection
- XSS protection
- SQL injection prevention
- Secure session management

## 🚀 Deployment Options

### 1. Traditional Deployment (Recommended)

```bash
# Run deployment script
./deploy.sh
```

### 2. Docker Deployment

```bash
# Build and run with Docker Compose
docker-compose -f docker-compose.production.yml up -d
```

### 3. Manual Setup

See [README.PRODUCTION.md](README.PRODUCTION.md) for detailed manual setup instructions.

## 📊 Monitoring

### Health Checks
- Application health: `GET /health/`
- Database health: `GET /health/detailed/`
- System metrics: Built-in performance monitoring

### Log Files
- Application: `/var/log/django/campshub360.log`
- Nginx: `/var/log/nginx/campshub360_*.log`
- System: `journalctl -u campshub360`

### Performance Monitoring
- Request/response time tracking
- Database query monitoring
- Memory and CPU usage
- Rate limiting statistics

## 🔒 Security

### Production Security Checklist
- [ ] Change default admin password
- [ ] Set up SSL certificate
- [ ] Configure AWS RDS with SSL
- [ ] Set up AWS ElastiCache
- [ ] Configure firewall (ports 80, 443, 22 only)
- [ ] Set up regular backups
- [ ] Monitor access logs
- [ ] Enable security headers
- [ ] Configure CORS properly

### Security Commands
```bash
# Generate new secret key
python manage.py security --generate-secret-key

# Validate security settings
python manage.py security --validate-env
```

## 📈 Performance

### Optimization Features
- Database connection pooling
- Query optimization
- Caching with Redis
- Static file optimization
- Gzip compression
- Rate limiting
- Load balancing ready

### Scaling
- Horizontal scaling support
- Database read replicas
- Redis clustering
- CDN integration
- Auto-scaling groups

## 🆘 Support

### Troubleshooting
1. Check logs: `sudo journalctl -u campshub360 -f`
2. Verify services: `sudo systemctl status campshub360`
3. Test health: `curl http://localhost:8000/health/`
4. Check database: `python manage.py dbshell`

### Common Issues
- **Database connection**: Check RDS endpoint and credentials
- **Static files**: Run `python manage.py collectstatic --noinput`
- **Permissions**: Fix with `sudo chown -R www-data:www-data /app`
- **SSL issues**: Verify certificate configuration

## 📝 License

This project is licensed under the MIT License.

## 🔄 Version History

### Version 2.0.0 (Production Ready)
- Production-optimized configuration
- AWS EC2 deployment support
- Comprehensive security hardening
- Performance monitoring
- Docker support
- Automated deployment scripts

### Version 1.0.0
- Initial release with core features
- Student and faculty management
- REST API endpoints
- Web dashboard

---

**CampsHub360** - Production-Ready Educational Management System

For detailed deployment instructions, see [README.PRODUCTION.md](README.PRODUCTION.md)