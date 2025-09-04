@echo off
echo 🚀 Starting CampsHub360 Local Development Server
echo ================================================

REM Set environment for local development
set DJANGO_SETTINGS_MODULE=campshub360.local_settings

echo ✅ Using local PostgreSQL settings
echo 📊 Database: campushub360 on localhost:5432
echo.

REM Test database connection first
echo 🔍 Testing database connection...
python manage.py shell -c "from django.db import connection; cursor = connection.cursor(); cursor.execute('SELECT 1'); print('✅ Database connection successful')" 2>nul
if errorlevel 1 (
    echo ❌ Database connection failed!
    echo Please make sure PostgreSQL is running and accessible.
    echo.
    echo 💡 Try running: setup_local_postgresql.bat
    pause
    exit /b 1
)

echo.
echo 🎯 Starting Django development server...
echo 🌐 Server will be available at: http://127.0.0.1:8000
echo.
echo Press Ctrl+C to stop the server
echo.

python manage.py runserver