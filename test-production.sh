#!/bin/bash

# CampsHub360 Production Test Suite
# Comprehensive testing of all production components

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

print_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

# Configuration
APP_DIR="/home/ubuntu/campushub-backend-2"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
DOMAIN=""
TEST_RESULTS=()
TOTAL_TESTS=0
PASSED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "Running: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        if [ "$expected_result" = "success" ]; then
            print_success "✓ $test_name - PASSED"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            TEST_RESULTS+=("✓ $test_name")
        else
            print_error "✗ $test_name - FAILED (unexpected success)"
            TEST_RESULTS+=("✗ $test_name")
        fi
    else
        if [ "$expected_result" = "failure" ]; then
            print_success "✓ $test_name - PASSED (expected failure)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            TEST_RESULTS+=("✓ $test_name")
        else
            print_error "✗ $test_name - FAILED"
            TEST_RESULTS+=("✗ $test_name")
        fi
    fi
    echo ""
}

# Function to test HTTP endpoint
test_http_endpoint() {
    local url="$1"
    local expected_status="$2"
    local test_name="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "Testing HTTP endpoint: $test_name"
    
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$status_code" = "$expected_status" ]; then
        print_success "✓ $test_name - PASSED (HTTP $status_code)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("✓ $test_name")
    else
        print_error "✗ $test_name - FAILED (HTTP $status_code, expected $expected_status)"
        TEST_RESULTS+=("✗ $test_name")
    fi
    echo ""
}

# Function to test HTTPS endpoint (if domain is set)
test_https_endpoint() {
    local url="$1"
    local expected_status="$2"
    local test_name="$3"
    
    if [ -n "$DOMAIN" ]; then
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        print_test "Testing HTTPS endpoint: $test_name"
        
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        
        if [ "$status_code" = "$expected_status" ]; then
            print_success "✓ $test_name - PASSED (HTTPS $status_code)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            TEST_RESULTS+=("✓ $test_name")
        else
            print_error "✗ $test_name - FAILED (HTTPS $status_code, expected $expected_status)"
            TEST_RESULTS+=("✗ $test_name")
        fi
        echo ""
    else
        print_warning "Skipping HTTPS tests - no domain configured"
    fi
}

# Get domain if available
if [ -f "$APP_DIR/.env" ]; then
    DOMAIN=$(grep "ALLOWED_HOSTS" "$APP_DIR/.env" | cut -d'=' -f2 | cut -d',' -f1 | tr -d ' ')
fi

print_header "CampsHub360 Production Test Suite"
echo "🕐 $(date)"
echo "🌐 Public IP: $PUBLIC_IP"
if [ -n "$DOMAIN" ]; then
    echo "🌍 Domain: $DOMAIN"
fi
echo ""

# System Tests
print_header "System Tests"

run_test "System uptime check" "uptime" "success"
run_test "Disk space check" "[ \$(df / | awk 'NR==2 {print \$5}' | sed 's/%//') -lt 90 ]" "success"
run_test "Memory usage check" "[ \$(free | awk 'NR==2{printf \"%.0f\", \$3*100/\$2}') -lt 90 ]" "success"
run_test "Load average check" "[ \$(uptime | awk -F'load average:' '{print \$2}' | awk '{print \$1}' | sed 's/,//' | cut -d'.' -f1) -lt \$(nproc) ]" "success"

# Service Tests
print_header "Service Tests"

run_test "CampsHub360 service status" "systemctl is-active --quiet campshub360" "success"
run_test "Nginx service status" "systemctl is-active --quiet nginx" "success"
run_test "Fail2ban service status" "systemctl is-active --quiet fail2ban" "success"

# Database Tests
print_header "Database Tests"

run_test "PostgreSQL connection" "cd $APP_DIR && source .env && source venv/bin/activate && python manage.py check --database default" "success"
run_test "Database migrations status" "cd $APP_DIR && source .env && source venv/bin/activate && python manage.py showmigrations --plan | grep -q 'No migrations'" "success"

# Cache Tests
print_header "Cache Tests"

run_test "Redis connection" "cd $APP_DIR && source .env && redis-cli -h \$(echo \$REDIS_URL | sed 's/redis:\/\/\\([^:]*\\):.*/\\1/') -p \$(echo \$REDIS_URL | sed 's/redis:\/\/[^:]*:\\([^/]*\\)\\/.*/\\1/') ping" "success"

# HTTP Endpoint Tests
print_header "HTTP Endpoint Tests"

test_http_endpoint "http://localhost:8000/health/" "200" "Health check endpoint"
test_http_endpoint "http://localhost:8000/admin/" "302" "Admin panel redirect"
test_http_endpoint "http://localhost:8000/dashboard/login/" "200" "Dashboard login page"

# Nginx Tests
print_header "Nginx Tests"

test_http_endpoint "http://$PUBLIC_IP/health/" "200" "Nginx health check proxy"
test_http_endpoint "http://$PUBLIC_IP/admin/" "302" "Nginx admin panel proxy"
test_http_endpoint "http://$PUBLIC_IP/dashboard/login/" "200" "Nginx dashboard proxy"

# HTTPS Tests (if domain is configured)
if [ -n "$DOMAIN" ]; then
    print_header "HTTPS Tests"
    
    test_https_endpoint "https://$DOMAIN/health/" "200" "HTTPS health check"
    test_https_endpoint "https://$DOMAIN/admin/" "302" "HTTPS admin panel"
    test_https_endpoint "https://$DOMAIN/dashboard/login/" "200" "HTTPS dashboard"
    
    # Test HTTP to HTTPS redirect
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "Testing HTTP to HTTPS redirect"
    
    local redirect_status=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/health/" 2>/dev/null || echo "000")
    
    if [ "$redirect_status" = "301" ] || [ "$redirect_status" = "302" ]; then
        print_success "✓ HTTP to HTTPS redirect - PASSED (HTTP $redirect_status)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("✓ HTTP to HTTPS redirect")
    else
        print_error "✗ HTTP to HTTPS redirect - FAILED (HTTP $redirect_status)"
        TEST_RESULTS+=("✗ HTTP to HTTPS redirect")
    fi
    echo ""
fi

# Security Tests
print_header "Security Tests"

run_test "Firewall status" "ufw status | grep -q 'Status: active'" "success"
run_test "Fail2ban status" "fail2ban-client status | grep -q 'Number of jail'" "success"
run_test "SSL certificate check" "[ -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]" "success"
run_test "Environment file permissions" "[ \$(stat -c %a $APP_DIR/.env) = '640' ]" "success"

# Performance Tests
print_header "Performance Tests"

# Test response times
TOTAL_TESTS=$((TOTAL_TESTS + 1))
print_test "Testing response times"

local health_time=$(curl -s -o /dev/null -w "%{time_total}" "http://$PUBLIC_IP/health/" 2>/dev/null || echo "999")
local health_time_ms=$(echo "$health_time * 1000" | bc | cut -d'.' -f1)

if [ "$health_time_ms" -lt 1000 ]; then
    print_success "✓ Health check response time - PASSED (${health_time_ms}ms)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS+=("✓ Health check response time")
else
    print_error "✗ Health check response time - FAILED (${health_time_ms}ms)"
    TEST_RESULTS+=("✗ Health check response time")
fi
echo ""

# Log Tests
print_header "Log Tests"

run_test "Django log file exists" "[ -f /var/log/django/campshub360.log ]" "success"
run_test "Nginx access log exists" "[ -f /var/log/nginx/campshub360_access.log ]" "success"
run_test "Nginx error log exists" "[ -f /var/log/nginx/campshub360_error.log ]" "success"
run_test "Log rotation configured" "[ -f /etc/logrotate.d/campshub360 ]" "success"

# Backup Tests
print_header "Backup Tests"

run_test "Backup directory exists" "[ -d /home/ubuntu/backups ]" "success"
run_test "Monitoring script exists" "[ -f /usr/local/bin/campshub360-monitor.sh ]" "success"
run_test "Monitoring script executable" "[ -x /usr/local/bin/campshub360-monitor.sh ]" "success"

# API Tests
print_header "API Tests"

# Test API endpoints if they exist
if curl -s "http://$PUBLIC_IP/api/" > /dev/null 2>&1; then
    test_http_endpoint "http://$PUBLIC_IP/api/" "200" "API root endpoint"
else
    print_warning "API endpoints not found or not accessible"
fi

# Test Results Summary
print_header "Test Results Summary"

echo "📊 Test Results:"
echo "   Total Tests: $TOTAL_TESTS"
echo "   Passed: $PASSED_TESTS"
echo "   Failed: $((TOTAL_TESTS - PASSED_TESTS))"
echo "   Success Rate: $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%"
echo ""

echo "📋 Detailed Results:"
for result in "${TEST_RESULTS[@]}"; do
    echo "   $result"
done
echo ""

# Overall Status
if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    print_success "🎉 All tests passed! Production setup is working correctly."
    echo ""
    print_warning "Access your application:"
    print_status "🌐 Application: http://$PUBLIC_IP"
    if [ -n "$DOMAIN" ]; then
        print_status "🌐 Application (HTTPS): https://$DOMAIN"
    fi
    print_status "🔧 Admin Panel: http://$PUBLIC_IP/admin/"
    print_status "❤️ Health Check: http://$PUBLIC_IP/health/"
    print_status "📡 API: http://$PUBLIC_IP/api/"
    
    echo ""
    print_warning "Useful commands:"
    print_status "📋 Monitor: ./monitor-production.sh"
    print_status "📋 Maintenance: ./monitor-production.sh maintenance"
    print_status "📋 Backup: ./monitor-production.sh backup"
    print_status "📋 View logs: sudo journalctl -u campshub360 -f"
    
    exit 0
else
    print_error "❌ Some tests failed. Please check the issues above."
    echo ""
    print_warning "Common issues and solutions:"
    print_warning "1. Service not running: sudo systemctl restart campshub360"
    print_warning "2. Database connection: Check RDS security groups"
    print_warning "3. Redis connection: Check ElastiCache security groups"
    print_warning "4. Nginx issues: sudo nginx -t && sudo systemctl restart nginx"
    print_warning "5. SSL issues: Check domain DNS and certificate"
    
    exit 1
fi
