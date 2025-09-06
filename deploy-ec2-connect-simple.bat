@echo off
REM Simple One-Command Deployment for CampsHub360 using AWS EC2 Instance Connect (Windows)
REM Usage: deploy-ec2-connect-simple.bat your-ec2-ip [instance-id]

if "%1"=="" (
    echo Usage: %0 ^<ec2-ip-address^> [instance-id]
    echo Example: %0 54.123.45.67 i-1234567890abcdef0
    exit /b 1
)

set EC2_INSTANCE_IP=%1
set EC2_INSTANCE_ID=%2

echo 🚀 Starting CampsHub360 deployment to EC2 using Instance Connect: %EC2_INSTANCE_IP%

REM Set environment variables for the EC2 Instance Connect deployment script
set EC2_INSTANCE_IP=%EC2_INSTANCE_IP%
if not "%EC2_INSTANCE_ID%"=="" (
    set EC2_INSTANCE_ID=%EC2_INSTANCE_ID%
    echo 📋 Using Instance ID: %EC2_INSTANCE_ID%
)

REM Run the EC2 Instance Connect deployment
call deploy-ec2-connect.bat

echo.
echo ✅ Deployment completed using AWS EC2 Instance Connect!
echo 🌐 Your application is now running at: http://%EC2_INSTANCE_IP%
echo 👤 Admin login: admin / admin123
echo 🔍 Health check: http://%EC2_INSTANCE_IP%/health/
echo.
echo 💡 To connect to your instance:
if not "%EC2_INSTANCE_ID%"=="" (
    echo    AWS CLI: aws ssm start-session --target %EC2_INSTANCE_ID% --document-name AWS-StartSSHSession
    echo    AWS Console: EC2 → Instances → Select instance → Connect → EC2 Instance Connect
) else (
    echo    SSH: ssh ubuntu@%EC2_INSTANCE_IP%
)
