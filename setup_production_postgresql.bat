@echo off
echo 🚀 Setting up CampsHub360 with PostgreSQL for Production
echo ========================================================

REM Set environment variables for production PostgreSQL
set DJANGO_SETTINGS_MODULE=campshub360.production
set POSTGRES_HOST=db
set POSTGRES_PORT=5432
set POSTGRES_DB=campushub360
set POSTGRES_USER=postgres
set POSTGRES_PASSWORD=secure_password_123

echo ✅ Environment variables set for production PostgreSQL
echo.
echo 📊 Database Configuration:
echo    Host: %POSTGRES_HOST% (Docker container)
echo    Port: %POSTGRES_PORT%
echo    Database: %POSTGRES_DB%
echo    User: %POSTGRES_USER%
echo.

echo 🐳 Starting Docker services...
docker-compose -f docker-compose.high-performance.yml up -d

echo.
echo ⏳ Waiting for services to be ready...
timeout /t 30 /nobreak

echo 🔄 Running database migrations...
python manage.py migrate

echo.
echo 🎯 Production PostgreSQL setup complete!
echo 🌐 Application will be available at: http://localhost:8000
echo.
pause
