#!/bin/bash

# Health check script for CampsHub360 Docker deployment

set -e

# Configuration
HEALTH_URL="http://localhost/health/"
TIMEOUT=10
MAX_RETRIES=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_error "curl is not installed. Please install curl to run health checks."
    exit 1
fi

# Function to check health endpoint
check_health() {
    local retries=0
    
    while [ $retries -lt $MAX_RETRIES ]; do
        print_status "Checking health endpoint: $HEALTH_URL (attempt $((retries + 1))/$MAX_RETRIES)"
        
        if curl -f -s --max-time $TIMEOUT "$HEALTH_URL" > /dev/null; then
            print_status "Health check passed! Application is running."
            return 0
        else
            print_warning "Health check failed. Retrying in 5 seconds..."
            sleep 5
            retries=$((retries + 1))
        fi
    done
    
    print_error "Health check failed after $MAX_RETRIES attempts."
    return 1
}

# Function to check Docker containers
check_containers() {
    print_status "Checking Docker containers..."
    
    if command -v docker-compose &> /dev/null; then
        # Check if docker-compose is running
        if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
            print_status "Docker containers are running."
            docker-compose -f docker-compose.production.yml ps
        else
            print_error "Docker containers are not running."
            return 1
        fi
    elif command -v docker &> /dev/null; then
        # Check Docker containers directly
        if docker ps | grep -q "campshub360"; then
            print_status "Docker containers are running."
            docker ps | grep "campshub360"
        else
            print_error "Docker containers are not running."
            return 1
        fi
    else
        print_warning "Docker is not available. Skipping container check."
    fi
}

# Function to check system resources
check_resources() {
    print_status "Checking system resources..."
    
    # Check memory usage
    if command -v free &> /dev/null; then
        echo "Memory usage:"
        free -h
    fi
    
    # Check disk usage
    if command -v df &> /dev/null; then
        echo "Disk usage:"
        df -h
    fi
    
    # Check CPU load
    if command -v uptime &> /dev/null; then
        echo "System load:"
        uptime
    fi
}

# Function to show application logs
show_logs() {
    print_status "Showing recent application logs..."
    
    if command -v docker-compose &> /dev/null; then
        docker-compose -f docker-compose.production.yml logs --tail=20
    elif command -v docker &> /dev/null; then
        docker logs --tail=20 $(docker ps -q --filter "name=campshub360")
    else
        print_warning "Docker is not available. Cannot show logs."
    fi
}

# Main function
main() {
    print_status "Starting CampsHub360 health check..."
    
    # Check containers first
    if ! check_containers; then
        print_error "Container check failed. Please check your Docker deployment."
        exit 1
    fi
    
    # Check system resources
    check_resources
    
    # Check health endpoint
    if check_health; then
        print_status "All health checks passed! ✅"
        exit 0
    else
        print_error "Health checks failed! ❌"
        show_logs
        exit 1
    fi
}

# Parse command line arguments
case "${1:-}" in
    --containers-only)
        check_containers
        ;;
    --health-only)
        check_health
        ;;
    --resources-only)
        check_resources
        ;;
    --logs-only)
        show_logs
        ;;
    --help)
        echo "Usage: $0 [OPTION]"
        echo "Options:"
        echo "  --containers-only    Check only Docker containers"
        echo "  --health-only        Check only health endpoint"
        echo "  --resources-only     Check only system resources"
        echo "  --logs-only          Show only application logs"
        echo "  --help               Show this help message"
        echo ""
        echo "Default: Run all health checks"
        exit 0
        ;;
    *)
        main
        ;;
esac
