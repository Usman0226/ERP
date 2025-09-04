@echo off
echo 🗄️  Setting up CampsHub360 with PostgreSQL for Local Development
echo ================================================================

REM Set environment variables for local PostgreSQL
set DJANGO_SETTINGS_MODULE=campshub360.local_settings
set POSTGRES_HOST=localhost
set POSTGRES_PORT=5432
set POSTGRES_DB=campushub360
set POSTGRES_USER=postgres
set POSTGRES_PASSWORD=123456

echo ✅ Environment variables set for local PostgreSQL
echo.
echo 📊 Database Configuration:
echo    Host: %POSTGRES_HOST%
echo    Port: %POSTGRES_PORT%
echo    Database: %POSTGRES_DB%
echo    User: %POSTGRES_USER%
echo.

echo 🔄 Running database migrations...
python manage.py migrate

echo.
echo 🎯 PostgreSQL setup complete!
echo 🚀 You can now run: python manage.py runserver
echo.
pause
