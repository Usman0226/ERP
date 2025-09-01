# CampsHub360 Backend

A comprehensive Django-based backend system for educational institution management, featuring student and faculty management, advanced API testing capabilities, and a modern web dashboard.

## 🚀 Features

### Core Management
- **Student Management**: Complete student lifecycle management with enrollment, documents, and custom fields
- **Faculty Management**: Comprehensive faculty administration with performance tracking and leave management
- **User Authentication**: JWT-based authentication system with role-based access control
- **Dashboard**: Modern web interface for administrative tasks and data visualization

### Advanced API Testing
- **Postman-like Interface**: Built-in API testing tool with collections and environments
- **Test Automation**: Write and run automated test suites for API endpoints
- **Environment Management**: Support for multiple deployment environments
- **Request History**: Track and analyze API usage patterns

### Technical Features
- **RESTful APIs**: Well-structured REST endpoints with comprehensive filtering and pagination
- **Database Support**: SQLite (development) and PostgreSQL (production) ready
- **File Handling**: Document upload and management for students and faculty
- **Custom Fields**: Extensible data model with custom field support
- **Bulk Operations**: Import/export functionality for large datasets

## 🛠️ Technology Stack

- **Backend Framework**: Django 5.2.5
- **API Framework**: Django REST Framework 3.16.1
- **Authentication**: JWT with Simple JWT 5.5.1
- **Database**: SQLite (dev) / PostgreSQL (prod)
- **File Processing**: Pandas, OpenPyXL for Excel operations
- **Deployment**: Gunicorn, Uvicorn
- **Frontend**: Django Templates with Bootstrap

## 📋 Prerequisites

- Python 3.8+
- pip (Python package installer)
- Git
- PostgreSQL (for production)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd campshub360-backend
```

### 2. Create Virtual Environment

```bash
python -m venv venv
# On Windows
venv\Scripts\activate
# On macOS/Linux
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Environment Setup

Create a `.env` file in the project root:

```env
SECRET_KEY=your-secret-key-here
DEBUG=True
DATABASE_URL=postgresql://user:password@localhost:5432/campshub360
ALLOWED_HOSTS=localhost,127.0.0.1
```

### 5. Database Setup

```bash
# For SQLite (development)
python manage.py migrate

# For PostgreSQL (production)
# Update settings.py with your database configuration
python manage.py migrate
```

### 6. Create Superuser

```bash
python manage.py createsuperuser
```

### 7. Run the Development Server

```bash
python manage.py runserver
```

Visit `http://localhost:8000` to access the application.

## 📚 API Documentation

### Base URLs
- **Students API**: `/api/v1/students/`
- **Faculty API**: `/api/v1/faculty/`
- **Authentication**: `/api/auth/`
- **Dashboard**: `/dashboard/`

### Authentication

All API endpoints require JWT authentication:

```http
Authorization: Bearer <your_jwt_token>
```

Get a token:
```http
POST /api/auth/token/
Content-Type: application/json

{
    "username": "your_username",
    "password": "your_password"
}
```

### Key Endpoints

#### Students
- `GET /api/v1/students/students/` - List all students
- `POST /api/v1/students/students/` - Create new student
- `GET /api/v1/students/students/{id}/` - Get student details
- `PUT /api/v1/students/students/{id}/` - Update student
- `DELETE /api/v1/students/students/{id}/` - Delete student

#### Faculty
- `GET /api/v1/faculty/` - List all faculty members
- `POST /api/v1/faculty/` - Create new faculty member
- `GET /api/v1/faculty/{id}/` - Get faculty details
- `PUT /api/v1/faculty/{id}/` - Update faculty member

For detailed API documentation, see:
- [Students API Documentation](students/API_DOCUMENTATION.md)
- [Faculty API Documentation](faculty/API_DOCUMENTATION.md)

## 🧪 API Testing

CampsHub360 includes a built-in API testing interface similar to Postman:

### Access Testing Interface
1. Navigate to `/dashboard/api-testing-dashboard/`
2. Use the Postman-like interface to test your APIs
3. Create collections, environments, and test scripts
4. Run automated test suites

### Features
- **Collections**: Organize API requests
- **Environments**: Manage different deployment configurations
- **Test Scripts**: Write JavaScript tests for API responses
- **Automation**: Schedule and run test suites

## 🏗️ Project Structure

```
campshub360-backend/
├── accounts/                 # User authentication and management
├── campshub360/             # Main project configuration
├── dashboard/               # Web dashboard and API testing interface
├── faculty/                 # Faculty management app
├── students/                # Student management app
├── manage.py               # Django management script
├── requirements.txt         # Python dependencies
└── README.md               # This file
```

## 🔧 Configuration

### Development Settings

The project uses environment variables for configuration. Key settings in `campshub360/settings.py`:

- `DEBUG`: Set to `True` for development
- `SECRET_KEY`: Django secret key
- `DATABASES`: Database configuration
- `ALLOWED_HOSTS`: Allowed host names

### Production Settings

For production deployment:

1. Set `DEBUG=False`
2. Configure proper `SECRET_KEY`
3. Set up PostgreSQL database
4. Configure `ALLOWED_HOSTS`
5. Set up static file serving
6. Configure HTTPS

## 🚀 Deployment

### Using Gunicorn

```bash
gunicorn campshub360.wsgi:application --bind 0.0.0.0:8000
```

### Using Uvicorn

```bash
uvicorn campshub360.asgi:application --host 0.0.0.0 --port 8000
```

### Docker (Recommended)

Create a `Dockerfile`:

```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 8000

CMD ["gunicorn", "campshub360.wsgi:application", "--bind", "0.0.0.0:8000"]
```

## 🧪 Testing

Run the test suite:

```bash
python manage.py test
```

Run specific app tests:

```bash
python manage.py test students
python manage.py test faculty
```

## 📊 Database Management

### Create Migrations

```bash
python manage.py makemigrations
```

### Apply Migrations

```bash
python manage.py migrate
```

### Database Shell

```bash
python manage.py dbshell
```

## 🔒 Security Features

- JWT-based authentication
- Role-based access control
- CSRF protection
- SQL injection prevention
- XSS protection
- Secure password validation

## 📈 Performance Optimization

- Database query optimization
- Pagination for large datasets
- Efficient filtering and search
- Caching support (can be added)
- Database indexing

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:

- Check the API documentation in each app directory
- Review the API testing guide: [API_TESTING_GUIDE.md](API_TESTING_GUIDE.md)
- Create an issue in the repository
- Contact the development team

## 🔄 Changelog

### Version 1.0.0
- Initial release with student and faculty management
- Built-in API testing interface
- JWT authentication system
- Comprehensive REST APIs
- Modern web dashboard

## 📚 Additional Resources

- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework Documentation](https://www.django-rest-framework.org/)
- [JWT Documentation](https://django-rest-framework-simplejwt.readthedocs.io/)

---

**CampsHub360** - Empowering Educational Institutions with Modern Technology
