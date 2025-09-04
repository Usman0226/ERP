#!/usr/bin/env bash
# High-Performance Deployment Script for CampsHub360

set -e

echo "🚀 Starting CampsHub360 High-Performance Deployment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp env.example .env
    echo "⚠️  Please edit .env file with your configuration before continuing."
    echo "   Key variables to set:"
    echo "   - SECRET_KEY (generate a secure key)"
    echo "   - POSTGRES_PASSWORD (set a secure password)"
    echo "   - ALLOWED_HOSTS (set your domain)"
    read -p "Press Enter to continue after editing .env file..."
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p logs
mkdir -p staticfiles
mkdir -p media

# Build and start services
echo "🔨 Building and starting services..."
docker-compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Run database migrations
echo "🗄️  Running database migrations..."
docker-compose exec web python manage.py migrate

# Collect static files
echo "📦 Collecting static files..."
docker-compose exec web python manage.py collectstatic --noinput

# Create superuser (optional)
echo "👤 Do you want to create a superuser? (y/n)"
read -p "> " create_superuser
if [ "$create_superuser" = "y" ] || [ "$create_superuser" = "Y" ]; then
    docker-compose exec web python manage.py createsuperuser
fi

# Test health endpoint
echo "🏥 Testing health endpoint..."
sleep 10
if curl -f http://localhost/health/ > /dev/null 2>&1; then
    echo "✅ Health check passed!"
else
    echo "❌ Health check failed. Check the logs:"
    docker-compose logs web
    exit 1
fi

echo "🎉 Deployment completed successfully!"
echo ""
echo "📊 Service URLs:"
echo "   - Application: http://localhost"
echo "   - Health Check: http://localhost/health/"
echo "   - Admin Panel: http://localhost/admin/"
echo ""
echo "📋 Useful commands:"
echo "   - View logs: docker-compose logs -f"
echo "   - Stop services: docker-compose down"
echo "   - Restart services: docker-compose restart"
echo "   - Scale web services: docker-compose up -d --scale web=3"
echo ""
echo "🔧 Performance monitoring:"
echo "   - Check service status: docker-compose ps"
echo "   - Monitor resources: docker stats"
echo "   - View detailed health: curl http://localhost/health/detailed/"
echo ""
echo "🚀 Your CampsHub360 backend is now running with high-performance optimizations!"
