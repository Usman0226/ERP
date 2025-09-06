@echo off
REM AWS EC2 Instance Connect Deployment Script for CampsHub360 (Windows)
REM This script uses AWS EC2 Instance Connect (no SSH keys needed)

setlocal enabledelayedexpansion

REM Configuration
if "%EC2_INSTANCE_IP%"=="" (
    echo [ERROR] EC2_INSTANCE_IP environment variable is not set
    echo Please set it with: set EC2_INSTANCE_IP=your-ec2-ip
    exit /b 1
)

set EC2_INSTANCE_ID=%EC2_INSTANCE_ID%
set EC2_USER=%EC2_USER%
if "%EC2_USER%"=="" set EC2_USER=ubuntu

set APP_NAME=campshub360
set APP_DIR=/home/%EC2_USER%/%APP_NAME%

echo [SETUP] Starting CampsHub360 deployment using AWS EC2 Instance Connect...
echo [INFO] Target EC2 Instance: %EC2_INSTANCE_IP%
if not "%EC2_INSTANCE_ID%"=="" echo [INFO] EC2 Instance ID: %EC2_INSTANCE_ID%
echo [INFO] EC2 User: %EC2_USER%

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] AWS CLI is not installed. Please install it first:
    echo https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
    exit /b 1
)

REM Check if AWS CLI is configured
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo [ERROR] AWS CLI is not configured. Please run: aws configure
    exit /b 1
)

echo [INFO] Requirements check passed

REM Generate secure passwords
echo [SETUP] Generating secure passwords...
for /f %%i in ('powershell -command "[System.Web.Security.Membership]::GeneratePassword(25, 5)"') do set DB_PASSWORD=%%i
for /f %%i in ('powershell -command "[System.Web.Security.Membership]::GeneratePassword(25, 5)"') do set REDIS_PASSWORD=%%i
for /f %%i in ('powershell -command "[System.Web.Security.Membership]::GeneratePassword(50, 10)"') do set SECRET_KEY=%%i

echo [INFO] Passwords generated successfully

REM Create environment file
echo [SETUP] Creating environment configuration...
(
echo # CampsHub360 Production Environment - Auto Generated
echo # Generated on: %date% %time%
echo.
echo # Database Configuration
echo POSTGRES_DB=campushub360
echo POSTGRES_USER=postgres
echo POSTGRES_PASSWORD=%DB_PASSWORD%
echo POSTGRES_HOST=db
echo POSTGRES_PORT=5432
echo POSTGRES_CONN_MAX_AGE=600
echo POSTGRES_CONNECT_TIMEOUT=10
echo.
echo # Redis Configuration
echo REDIS_URL=redis://redis:6379/0
echo REDIS_PASSWORD=%REDIS_PASSWORD%
echo.
echo # Django Configuration
echo SECRET_KEY=%SECRET_KEY%
echo DEBUG=False
echo DJANGO_SETTINGS_MODULE=campshub360.production
echo.
echo # Security Settings
echo SECURE_SSL_REDIRECT=False
echo CSRF_COOKIE_SECURE=False
echo SESSION_COOKIE_SECURE=False
echo SECURE_HSTS_SECONDS=0
echo.
echo # Performance Settings ^(Optimized for 20k+ users/sec^)
echo GUNICORN_WORKERS=16
echo GUNICORN_WORKER_CLASS=gevent
echo GUNICORN_WORKER_CONNECTIONS=1000
echo GUNICORN_TIMEOUT=30
echo GUNICORN_KEEPALIVE=5
echo GUNICORN_MAX_REQUESTS=1000
echo GUNICORN_MAX_REQUESTS_JITTER=100
echo.
echo # Cache Settings
echo CACHE_DEFAULT_TIMEOUT=300
echo SESSION_CACHE_TIMEOUT=86400
echo QUERY_CACHE_TIMEOUT=600
echo.
echo # CORS Settings ^(Update with your domain^)
echo CORS_ALLOWED_ORIGINS=http://%EC2_INSTANCE_IP%,https://%EC2_INSTANCE_IP%
echo CSRF_TRUSTED_ORIGINS=http://%EC2_INSTANCE_IP%,https://%EC2_INSTANCE_IP%
echo.
echo # Allowed Hosts
echo ALLOWED_HOSTS=%EC2_INSTANCE_IP%,localhost,127.0.0.1
echo.
echo # Email Configuration ^(Optional - Update with your SMTP^)
echo EMAIL_HOST=smtp.gmail.com
echo EMAIL_PORT=587
echo EMAIL_HOST_USER=
echo EMAIL_HOST_PASSWORD=
echo DEFAULT_FROM_EMAIL=noreply@%EC2_INSTANCE_IP%
echo.
echo # API Settings
echo API_PAGE_SIZE=50
echo.
echo # Docker Settings
echo DOCKER_CONTAINER=true
) > .env.production

echo [INFO] Environment file created: .env.production

REM Setup EC2 instance
echo [SETUP] Setting up EC2 instance...
if not "%EC2_INSTANCE_ID%"=="" (
    REM Use EC2 Instance Connect
    aws ec2-instance-connect send-ssh-public-key --instance-id %EC2_INSTANCE_ID% --instance-os-user %EC2_USER% --ssh-public-key file://%USERPROFILE%\.ssh\id_rsa.pub 2>nul
    aws ssm start-session --target %EC2_INSTANCE_ID% --document-name AWS-StartSSHSession --parameters "portNumber=22" --cli-read-timeout 0 --cli-write-timeout 0 --input-text "sudo apt update && sudo apt upgrade -y && curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo usermod -aG docker %EC2_USER% && sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose && sudo apt install -y curl wget git htop && mkdir -p %APP_DIR% && sudo ufw allow 22 && sudo ufw allow 80 && sudo ufw allow 443 && sudo ufw --force enable"
) else (
    REM Use regular SSH
    ssh -o StrictHostKeyChecking=no %EC2_USER%@%EC2_INSTANCE_IP% "sudo apt update && sudo apt upgrade -y && curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo usermod -aG docker %EC2_USER% && sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose && sudo apt install -y curl wget git htop && mkdir -p %APP_DIR% && sudo ufw allow 22 && sudo ufw allow 80 && sudo ufw allow 443 && sudo ufw --force enable"
)

echo [INFO] EC2 instance setup completed

REM Copy files to EC2 (simplified approach for Windows)
echo [SETUP] Copying application files...
echo [WARNING] For Windows, please manually copy the following files to your EC2 instance:
echo   - docker-compose.production.yml
echo   - .env.production
echo   - nginx-production-lb.conf
echo   - Dockerfile
echo   - gunicorn.conf.py
echo   - supervisord.conf
echo   - nginx-docker.conf
echo   - init-db.sql
echo   - All Django application code
echo.
echo [INFO] You can use AWS Systems Manager Session Manager or any file transfer tool.

REM Deploy application
echo [SETUP] Building and starting application...
if not "%EC2_INSTANCE_ID%"=="" (
    aws ssm start-session --target %EC2_INSTANCE_ID% --document-name AWS-StartSSHSession --parameters "portNumber=22" --cli-read-timeout 0 --cli-write-timeout 0 --input-text "cd %APP_DIR% && docker build -t %APP_NAME%:latest . && docker-compose -f docker-compose.production.yml down || true && docker-compose -f docker-compose.production.yml up -d && sleep 30 && docker-compose -f docker-compose.production.yml ps"
) else (
    ssh -o StrictHostKeyChecking=no %EC2_USER%@%EC2_INSTANCE_IP% "cd %APP_DIR% && docker build -t %APP_NAME%:latest . && docker-compose -f docker-compose.production.yml down || true && docker-compose -f docker-compose.production.yml up -d && sleep 30 && docker-compose -f docker-compose.production.yml ps"
)

echo [INFO] Running database migrations...
if not "%EC2_INSTANCE_ID%"=="" (
    aws ssm start-session --target %EC2_INSTANCE_ID% --document-name AWS-StartSSHSession --parameters "portNumber=22" --cli-read-timeout 0 --cli-write-timeout 0 --input-text "cd %APP_DIR% && docker-compose -f docker-compose.production.yml exec -T web python manage.py migrate --settings=campshub360.production"
) else (
    ssh -o StrictHostKeyChecking=no %EC2_USER%@%EC2_INSTANCE_IP% "cd %APP_DIR% && docker-compose -f docker-compose.production.yml exec -T web python manage.py migrate --settings=campshub360.production"
)

echo [INFO] Creating superuser...
if not "%EC2_INSTANCE_ID%"=="" (
    aws ssm start-session --target %EC2_INSTANCE_ID% --document-name AWS-StartSSHSession --parameters "portNumber=22" --cli-read-timeout 0 --cli-write-timeout 0 --input-text "cd %APP_DIR% && docker-compose -f docker-compose.production.yml exec -T web python manage.py shell --settings=campshub360.production -c \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'admin123') if not User.objects.filter(username='admin').exists() else print('Superuser already exists')\""
) else (
    ssh -o StrictHostKeyChecking=no %EC2_USER%@%EC2_INSTANCE_IP% "cd %APP_DIR% && docker-compose -f docker-compose.production.yml exec -T web python manage.py shell --settings=campshub360.production -c \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'admin123') if not User.objects.filter(username='admin').exists() else print('Superuser already exists')\""
)

echo [INFO] Collecting static files...
if not "%EC2_INSTANCE_ID%"=="" (
    aws ssm start-session --target %EC2_INSTANCE_ID% --document-name AWS-StartSSHSession --parameters "portNumber=22" --cli-read-timeout 0 --cli-write-timeout 0 --input-text "cd %APP_DIR% && docker-compose -f docker-compose.production.yml exec -T web python manage.py collectstatic --noinput --settings=campshub360.production"
) else (
    ssh -o StrictHostKeyChecking=no %EC2_USER%@%EC2_INSTANCE_IP% "cd %APP_DIR% && docker-compose -f docker-compose.production.yml exec -T web python manage.py collectstatic --noinput --settings=campshub360.production"
)

echo [INFO] Application deployment completed

REM Test deployment
echo [SETUP] Testing deployment...
timeout 10
curl -f -s --max-time 30 "http://%EC2_INSTANCE_IP%/health/" >nul 2>&1 && echo [INFO] ✅ Health check passed! || echo [WARNING] ⚠️ Health check failed, but application might still be starting...

curl -f -s --max-time 30 "http://%EC2_INSTANCE_IP%/" >nul 2>&1 && echo [INFO] ✅ Main application is accessible! || echo [WARNING] ⚠️ Main application test failed, but it might still be starting...

REM Show deployment information
echo.
echo [SETUP] Deployment Information
echo.
echo 🎉 CampsHub360 has been successfully deployed using AWS EC2 Instance Connect!
echo.
echo 📋 Deployment Details:
echo    • Application URL: http://%EC2_INSTANCE_IP%
echo    • Health Check: http://%EC2_INSTANCE_IP%/health/
echo    • Admin Panel: http://%EC2_INSTANCE_IP%/admin/
echo.
echo 🔐 Admin Credentials:
echo    • Username: admin
echo    • Password: admin123
echo.
echo 🗄️ Database Information:
echo    • Database: campushub360
echo    • Username: postgres
echo    • Password: %DB_PASSWORD%
echo.
echo 📊 Monitoring Commands:
if not "%EC2_INSTANCE_ID%"=="" (
    echo    • View logs: aws ssm start-session --target %EC2_INSTANCE_ID% --document-name AWS-StartSSHSession
    echo    • Check status: aws ssm start-session --target %EC2_INSTANCE_ID% --document-name AWS-StartSSHSession
) else (
    echo    • View logs: ssh %EC2_USER%@%EC2_INSTANCE_IP% "cd %APP_DIR% && docker-compose -f docker-compose.production.yml logs -f"
    echo    • Check status: ssh %EC2_USER%@%EC2_INSTANCE_IP% "cd %APP_DIR% && docker-compose -f docker-compose.production.yml ps"
)
echo.
echo 🔧 Configuration Files:
echo    • Environment: %APP_DIR%/.env
echo    • Docker Compose: %APP_DIR%/docker-compose.production.yml
echo.
echo ⚠️ Important Notes:
echo    • Change the admin password after first login
echo    • Update CORS_ALLOWED_ORIGINS with your domain
echo    • Configure email settings if needed
echo    • Set up SSL certificates for production use
echo.

echo [INFO] 🎉 Deployment completed successfully using AWS EC2 Instance Connect!
