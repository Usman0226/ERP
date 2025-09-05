#!/bin/bash

# CampsHub360 Production Monitoring and Maintenance Script
# Comprehensive monitoring, health checks, and maintenance tasks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_debug() {
    echo -e "${CYAN}[DEBUG]${NC} $1"
}

# Configuration
APP_NAME="campshub360"
APP_DIR="/home/ubuntu/campushub-backend-2"
LOG_DIR="/var/log/django"
NGINX_LOG_DIR="/var/log/nginx"
BACKUP_DIR="/home/ubuntu/backups"
MONITOR_LOG="$LOG_DIR/monitor.log"

# Create directories if they don't exist
mkdir -p $LOG_DIR
mkdir -p $BACKUP_DIR

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $MONITOR_LOG
}

# Function to check service status
check_service_status() {
    local service_name=$1
    if systemctl is-active --quiet $service_name; then
        echo "✅ $service_name is running"
        log_message "SERVICE_CHECK: $service_name - OK"
        return 0
    else
        echo "❌ $service_name is not running"
        log_message "SERVICE_CHECK: $service_name - FAILED"
        return 1
    fi
}

# Function to check disk usage
check_disk_usage() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "💾 Disk usage: ${usage}%"
    log_message "DISK_USAGE: ${usage}%"
    
    if [ $usage -gt 90 ]; then
        print_error "Disk usage is critical: ${usage}%"
        log_message "ALERT: Disk usage critical - ${usage}%"
        return 1
    elif [ $usage -gt 80 ]; then
        print_warning "Disk usage is high: ${usage}%"
        log_message "WARNING: Disk usage high - ${usage}%"
    fi
    return 0
}

# Function to check memory usage
check_memory_usage() {
    local usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    echo "🧠 Memory usage: ${usage}%"
    log_message "MEMORY_USAGE: ${usage}%"
    
    if (( $(echo "$usage > 90" | bc -l) )); then
        print_error "Memory usage is critical: ${usage}%"
        log_message "ALERT: Memory usage critical - ${usage}%"
        return 1
    elif (( $(echo "$usage > 80" | bc -l) )); then
        print_warning "Memory usage is high: ${usage}%"
        log_message "WARNING: Memory usage high - ${usage}%"
    fi
    return 0
}

# Function to check load average
check_load_average() {
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cores=$(nproc)
    echo "⚡ Load average: $load (${cores} cores)"
    log_message "LOAD_AVERAGE: $load (${cores} cores)"
    
    if (( $(echo "$load > $cores" | bc -l) )); then
        print_warning "Load average is high: $load"
        log_message "WARNING: Load average high - $load"
    fi
    return 0
}

# Function to check application health
check_app_health() {
    local health_url="http://localhost:8000/health/"
    local response=$(curl -s -o /dev/null -w "%{http_code}" $health_url 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        echo "❤️ Application health check: OK"
        log_message "HEALTH_CHECK: OK"
        return 0
    else
        print_error "Application health check failed: HTTP $response"
        log_message "HEALTH_CHECK: FAILED - HTTP $response"
        return 1
    fi
}

# Function to check database connection
check_database_connection() {
    cd $APP_DIR
    source .env
    source venv/bin/activate
    
    if python manage.py check --database default > /dev/null 2>&1; then
        echo "🗄️ Database connection: OK"
        log_message "DATABASE_CHECK: OK"
        return 0
    else
        print_error "Database connection failed"
        log_message "DATABASE_CHECK: FAILED"
        return 1
    fi
}

# Function to check Redis connection
check_redis_connection() {
    source $APP_DIR/.env
    local redis_host=$(echo $REDIS_URL | sed 's/redis:\/\/\([^:]*\):.*/\1/')
    local redis_port=$(echo $REDIS_URL | sed 's/redis:\/\/[^:]*:\([^/]*\)\/.*/\1/')
    
    if redis-cli -h "$redis_host" -p "$redis_port" ping > /dev/null 2>&1; then
        echo "🔴 Redis connection: OK"
        log_message "REDIS_CHECK: OK"
        return 0
    else
        print_error "Redis connection failed"
        log_message "REDIS_CHECK: FAILED"
        return 1
    fi
}

# Function to check log file sizes
check_log_sizes() {
    echo "📋 Log file sizes:"
    for log_file in $LOG_DIR/*.log $NGINX_LOG_DIR/campshub360_*.log; do
        if [ -f "$log_file" ]; then
            local size=$(du -h "$log_file" | cut -f1)
            echo "   $(basename $log_file): $size"
            log_message "LOG_SIZE: $(basename $log_file) - $size"
        fi
    done
}

# Function to perform maintenance tasks
perform_maintenance() {
    print_header "Performing Maintenance Tasks"
    
    # Clean old log files
    print_status "Cleaning old log files..."
    find $LOG_DIR -name "*.log.*" -mtime +7 -delete 2>/dev/null || true
    find $NGINX_LOG_DIR -name "campshub360_*.log.*" -mtime +7 -delete 2>/dev/null || true
    
    # Clean temporary files
    print_status "Cleaning temporary files..."
    find /tmp -name "campshub360*" -mtime +1 -delete 2>/dev/null || true
    
    # Update package lists (weekly)
    if [ $(date +%u) -eq 1 ]; then  # Monday
        print_status "Updating package lists..."
        apt update > /dev/null 2>&1 || true
    fi
    
    # Rotate logs
    print_status "Rotating logs..."
    logrotate -f /etc/logrotate.d/campshub360 > /dev/null 2>&1 || true
    
    print_success "Maintenance tasks completed"
}

# Function to create backup
create_backup() {
    print_header "Creating Backup"
    
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/campshub360_backup_$backup_date.tar.gz"
    
    print_status "Creating backup: $backup_file"
    
    # Create backup of application files (excluding venv and logs)
    tar -czf $backup_file \
        --exclude='venv' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.git' \
        --exclude='staticfiles' \
        --exclude='media' \
        --exclude='*.log' \
        -C $APP_DIR . 2>/dev/null || true
    
    if [ -f "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        print_success "Backup created: $backup_file ($size)"
        log_message "BACKUP_CREATED: $backup_file ($size)"
        
        # Keep only last 7 backups
        ls -t $BACKUP_DIR/campshub360_backup_*.tar.gz | tail -n +8 | xargs rm -f 2>/dev/null || true
    else
        print_error "Backup creation failed"
        log_message "BACKUP_FAILED: $backup_file"
    fi
}

# Function to restart services
restart_services() {
    print_header "Restarting Services"
    
    print_status "Restarting CampsHub360 service..."
    sudo systemctl restart campshub360
    sleep 5
    
    if systemctl is-active --quiet campshub360; then
        print_success "CampsHub360 service restarted successfully"
        log_message "SERVICE_RESTART: campshub360 - SUCCESS"
    else
        print_error "CampsHub360 service restart failed"
        log_message "SERVICE_RESTART: campshub360 - FAILED"
    fi
    
    print_status "Restarting Nginx..."
    sudo systemctl restart nginx
    sleep 2
    
    if systemctl is-active --quiet nginx; then
        print_success "Nginx service restarted successfully"
        log_message "SERVICE_RESTART: nginx - SUCCESS"
    else
        print_error "Nginx service restart failed"
        log_message "SERVICE_RESTART: nginx - FAILED"
    fi
}

# Function to show system information
show_system_info() {
    print_header "System Information"
    
    echo "🖥️  Hostname: $(hostname)"
    echo "📅 Date: $(date)"
    echo "⏰ Uptime: $(uptime -p)"
    echo "🌐 Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'N/A')"
    echo "🏷️  Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo 'N/A')"
    echo "🌍 Region: $(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo 'N/A')"
    echo "💻 CPU: $(nproc) cores"
    echo "💾 RAM: $(free -h | awk 'NR==2{print $2}')"
    echo "💿 Disk: $(df -h / | awk 'NR==2{print $2}')"
}

# Function to show recent errors
show_recent_errors() {
    print_header "Recent Errors"
    
    echo "🔍 Checking for recent errors in logs..."
    
    # Check Django logs
    if [ -f "$LOG_DIR/campshub360_error.log" ]; then
        local django_errors=$(tail -n 50 "$LOG_DIR/campshub360_error.log" | grep -i error | wc -l)
        echo "Django errors (last 50 lines): $django_errors"
        if [ $django_errors -gt 0 ]; then
            echo "Recent Django errors:"
            tail -n 50 "$LOG_DIR/campshub360_error.log" | grep -i error | tail -n 5
        fi
    fi
    
    # Check Nginx logs
    if [ -f "$NGINX_LOG_DIR/campshub360_error.log" ]; then
        local nginx_errors=$(tail -n 50 "$NGINX_LOG_DIR/campshub360_error.log" | grep -i error | wc -l)
        echo "Nginx errors (last 50 lines): $nginx_errors"
        if [ $nginx_errors -gt 0 ]; then
            echo "Recent Nginx errors:"
            tail -n 50 "$NGINX_LOG_DIR/campshub360_error.log" | grep -i error | tail -n 5
        fi
    fi
    
    # Check systemd logs
    local systemd_errors=$(journalctl -u campshub360 --since "1 hour ago" | grep -i error | wc -l)
    echo "Systemd errors (last hour): $systemd_errors"
    if [ $systemd_errors -gt 0 ]; then
        echo "Recent systemd errors:"
        journalctl -u campshub360 --since "1 hour ago" | grep -i error | tail -n 3
    fi
}

# Main monitoring function
run_monitoring() {
    print_header "CampsHub360 Production Monitoring"
    echo "🕐 $(date)"
    echo ""
    
    local overall_status=0
    
    # System checks
    print_header "System Health"
    check_disk_usage || overall_status=1
    check_memory_usage || overall_status=1
    check_load_average || overall_status=1
    echo ""
    
    # Service checks
    print_header "Service Status"
    check_service_status "campshub360" || overall_status=1
    check_service_status "nginx" || overall_status=1
    check_service_status "fail2ban" || overall_status=1
    echo ""
    
    # Application checks
    print_header "Application Health"
    check_app_health || overall_status=1
    check_database_connection || overall_status=1
    check_redis_connection || overall_status=1
    echo ""
    
    # Log information
    print_header "Log Information"
    check_log_sizes
    echo ""
    
    # Overall status
    if [ $overall_status -eq 0 ]; then
        print_success "All systems operational"
        log_message "MONITORING: All systems OK"
    else
        print_error "Some issues detected - check logs"
        log_message "MONITORING: Issues detected"
    fi
    
    return $overall_status
}

# Main script logic
case "${1:-monitor}" in
    "monitor")
        run_monitoring
        ;;
    "maintenance")
        perform_maintenance
        ;;
    "backup")
        create_backup
        ;;
    "restart")
        restart_services
        ;;
    "info")
        show_system_info
        ;;
    "errors")
        show_recent_errors
        ;;
    "full")
        show_system_info
        echo ""
        run_monitoring
        echo ""
        show_recent_errors
        ;;
    *)
        echo "Usage: $0 {monitor|maintenance|backup|restart|info|errors|full}"
        echo ""
        echo "Commands:"
        echo "  monitor     - Run health checks and monitoring"
        echo "  maintenance - Perform maintenance tasks"
        echo "  backup      - Create application backup"
        echo "  restart     - Restart all services"
        echo "  info        - Show system information"
        echo "  errors      - Show recent errors"
        echo "  full        - Run all checks and show info"
        exit 1
        ;;
esac
