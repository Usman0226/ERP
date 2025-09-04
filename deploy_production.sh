#!/bin/bash

# CampsHub360 Production Deployment Script
set -e

echo "🚀 Starting CampsHub360 Production Deployment..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please create it from env.example"
    exit 1
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Validate required environment variables
required_vars=("SECRET_KEY" "POSTGRES_PASSWORD" "ALLOWED_HOSTS")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Required environment variable $var is not set"
        exit 1
    fi
done

echo "✅ Environment variables validated"

# Set production settings
export DJANGO_SETTINGS_MODULE=campshub360.production

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Run database migrations
echo "🗄️ Running database migrations..."
python manage.py migrate

# Collect static files
echo "📁 Collecting static files..."
python manage.py collectstatic --noinput

# Create superuser if it doesn't exist
echo "👤 Creating superuser..."
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('Superuser created: admin/admin123')
else:
    print('Superuser already exists')
EOF

# Run security checks
echo "🔒 Running security checks..."
python manage.py check --deploy

# Start services with Docker Compose
echo "🐳 Starting services with Docker Compose..."
docker-compose -f docker-compose.high-performance.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Run health checks
echo "🏥 Running health checks..."
curl -f http://localhost:8000/health/ || {
    echo "❌ Health check failed"
    docker-compose -f docker-compose.high-performance.yml logs web
    exit 1
}

echo "✅ Production deployment completed successfully!"
echo "🌐 Application is running at: http://localhost:8000"
echo "📊 Health check: http://localhost:8000/health/"
echo "📈 Detailed health: http://localhost:8000/health/detailed/"

# Show service status
echo "📋 Service Status:"
docker-compose -f docker-compose.high-performance.yml ps
