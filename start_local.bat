@echo off
echo 🚀 Starting CampsHub360 High-Performance Backend...
echo.

REM Set local settings
set DJANGO_SETTINGS_MODULE=campshub360.local_settings

echo 📊 Running system check...
python manage.py check
if %errorlevel% neq 0 (
    echo ❌ System check failed!
    pause
    exit /b 1
)

echo ✅ System check passed!
echo.

echo 🔄 Running migrations...
python manage.py migrate
if %errorlevel% neq 0 (
    echo ❌ Migrations failed!
    pause
    exit /b 1
)

echo ✅ Migrations completed!
echo.

echo 👤 Creating superuser (if needed)...
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('✅ Superuser created: admin/admin123')
else:
    print('✅ Superuser already exists')
"

echo.
echo 🎉 Starting development server...
echo 📊 Health check: http://localhost:8000/health/
echo 🔧 Admin panel: http://localhost:8000/admin/
echo 📚 API docs: http://localhost:8000/api/
echo.
echo Press Ctrl+C to stop the server
echo.

python manage.py runserver 8000
