@echo off
REM High-Performance Deployment Script for CampsHub360 (Windows)

echo 🚀 Starting CampsHub360 High-Performance Deployment...

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not running. Please start Docker and try again.
    pause
    exit /b 1
)

REM Check if Docker Compose is available
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose is not installed. Please install Docker Compose and try again.
    pause
    exit /b 1
)

REM Create .env file if it doesn't exist
if not exist .env (
    echo 📝 Creating .env file from template...
    copy env.example .env
    echo ⚠️  Please edit .env file with your configuration before continuing.
    echo    Key variables to set:
    echo    - SECRET_KEY (generate a secure key)
    echo    - POSTGRES_PASSWORD (set a secure password)
    echo    - ALLOWED_HOSTS (set your domain)
    pause
)

REM Create necessary directories
echo 📁 Creating necessary directories...
if not exist logs mkdir logs
if not exist staticfiles mkdir staticfiles
if not exist media mkdir media

REM Build and start services
echo 🔨 Building and starting services...
docker-compose up -d --build

REM Wait for services to be ready
echo ⏳ Waiting for services to be ready...
timeout /t 30 /nobreak >nul

REM Check if services are running
echo 🔍 Checking service status...
docker-compose ps

REM Run database migrations
echo 🗄️  Running database migrations...
docker-compose exec web python manage.py migrate

REM Collect static files
echo 📦 Collecting static files...
docker-compose exec web python manage.py collectstatic --noinput

REM Test health endpoint
echo 🏥 Testing health endpoint...
timeout /t 10 /nobreak >nul
curl -f http://localhost/health/ >nul 2>&1
if errorlevel 1 (
    echo ❌ Health check failed. Check the logs:
    docker-compose logs web
    pause
    exit /b 1
) else (
    echo ✅ Health check passed!
)

echo 🎉 Deployment completed successfully!
echo.
echo 📊 Service URLs:
echo    - Application: http://localhost
echo    - Health Check: http://localhost/health/
echo    - Admin Panel: http://localhost/admin/
echo.
echo 📋 Useful commands:
echo    - View logs: docker-compose logs -f
echo    - Stop services: docker-compose down
echo    - Restart services: docker-compose restart
echo    - Scale web services: docker-compose up -d --scale web=3
echo.
echo 🔧 Performance monitoring:
echo    - Check service status: docker-compose ps
echo    - Monitor resources: docker stats
echo    - View detailed health: curl http://localhost/health/detailed/
echo.
echo 🚀 Your CampsHub360 backend is now running with high-performance optimizations!
pause
