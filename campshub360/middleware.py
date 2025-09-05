from time import time
from django.http import JsonResponse
from django.core.cache import cache, caches
from django.utils.deprecation import MiddlewareMixin
import hashlib
import json
from typing import Dict, Any


class HighPerformanceRateLimitMiddleware(MiddlewareMixin):
    """
    High-performance rate limiter with multiple strategies:
    - Token bucket per IP
    - User-based rate limiting
    - Endpoint-specific limits
    - Burst protection
    """

    def __init__(self, get_response):
        self.get_response = get_response
        from os import getenv
        
        # Rate limiting configuration
        self.rpm = int(getenv('RATE_LIMIT_RPM', '1000'))  # Increased for high performance
        self.bucket = int(getenv('RATE_LIMIT_BUCKET', '2000'))
        self.burst_limit = int(getenv('RATE_LIMIT_BURST', '100'))
        self.user_rpm = int(getenv('USER_RATE_LIMIT_RPM', '2000'))
        
        # Cache backend for rate limiting
        self.rate_cache = caches['default']
        
        # Endpoint-specific limits
        self.endpoint_limits = {
            '/api/auth/login': {'rpm': 100, 'burst': 10},
            '/api/auth/register': {'rpm': 50, 'burst': 5},
            '/api/students/': {'rpm': 500, 'burst': 50},
            '/api/faculty/': {'rpm': 500, 'burst': 50},
            '/api/attendance/': {'rpm': 1000, 'burst': 100},
        }

    def __call__(self, request):
        # Skip rate limiting for certain paths
        if self._should_skip_rate_limit(request):
            return self.get_response(request)
        
        # Get client identifier
        client_id = self._get_client_id(request)
        endpoint = request.path
        
        # Check rate limits
        if not self._check_rate_limit(client_id, endpoint, request):
            return self._rate_limit_response()
        
        # Add performance headers
        response = self.get_response(request)
        self._add_performance_headers(response, request)
        
        return response

    def _should_skip_rate_limit(self, request) -> bool:
        """Skip rate limiting for certain paths"""
        skip_paths = ['/health/', '/metrics/', '/static/', '/media/']
        return any(request.path.startswith(path) for path in skip_paths)

    def _get_client_id(self, request) -> str:
        """Get unique client identifier"""
        # Try to get user ID first
        if hasattr(request, 'user') and request.user.is_authenticated:
            return f"user:{request.user.id}"
        
        # Fall back to IP address
        ip = self._get_real_ip(request)
        return f"ip:{ip}"

    def _get_real_ip(self, request) -> str:
        """Get real IP address considering proxies"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR', 'unknown')
        return ip

    def _check_rate_limit(self, client_id: str, endpoint: str, request) -> bool:
        """Check if request is within rate limits"""
        now = time()
        
        # Get endpoint-specific limits
        limits = self.endpoint_limits.get(endpoint, {'rpm': self.rpm, 'burst': self.burst_limit})
        
        # Check burst limit first (immediate protection)
        burst_key = f"burst:{client_id}:{endpoint}"
        burst_count = self.rate_cache.get(burst_key, 0)
        if burst_count >= limits['burst']:
            return False
        
        # Check token bucket rate limit
        bucket_key = f"bucket:{client_id}:{endpoint}"
        state = self.rate_cache.get(bucket_key)
        
        if state is None:
            tokens = limits['rpm'] // 60  # Convert RPM to per-second
            last_refill = now
        else:
            tokens, last_refill = state
        
        # Refill tokens based on time elapsed
        rate_per_sec = limits['rpm'] / 60.0
        time_elapsed = now - last_refill
        tokens = min(limits['rpm'] // 60, tokens + time_elapsed * rate_per_sec)
        
        # Check if we have enough tokens
        if tokens < 1:
            return False
        
        # Consume token and update burst counter
        tokens -= 1
        burst_count += 1
        
        # Update cache with short TTL for burst, longer for bucket
        self.rate_cache.set(bucket_key, (tokens, now), timeout=60)
        self.rate_cache.set(burst_key, burst_count, timeout=10)  # 10 second burst window
        
        return True

    def _rate_limit_response(self) -> JsonResponse:
        """Return rate limit exceeded response"""
        return JsonResponse({
            'error': 'Rate limit exceeded',
            'message': 'Too many requests. Please try again later.',
            'retry_after': 60
        }, status=429, headers={'Retry-After': '60'})

    def _generate_request_id(self, request) -> str:
        """Generate unique request ID"""
        data = f"{request.META.get('REMOTE_ADDR', '')}{time()}{request.path}"
        return hashlib.md5(data.encode()).hexdigest()[:16]

    def _add_performance_headers(self, response, request):
        """Add performance monitoring headers"""
        response['X-Request-ID'] = self._generate_request_id(request)
        response['X-Response-Time'] = str(time() - float(request.META.get('REQUEST_START_TIME', time())))
        
        # Add cache status headers
        if hasattr(request, '_cache_hit'):
            response['X-Cache-Status'] = 'HIT' if request._cache_hit else 'MISS'


class PerformanceMonitoringMiddleware(MiddlewareMixin):
    """Middleware for performance monitoring and optimization"""

    def __init__(self, get_response):
        self.get_response = get_response
        self.performance_cache = caches['default']

    def __call__(self, request):
        start_time = time()
        request.META['REQUEST_START_TIME'] = str(start_time)
        
        # Add request ID for tracing
        request.META['REQUEST_ID'] = self._generate_request_id(request)
        
        response = self.get_response(request)
        
        # Calculate response time
        response_time = time() - start_time
        response['X-Response-Time'] = str(response_time)
        response['X-Request-ID'] = request.META['REQUEST_ID']
        
        # Log slow requests
        if response_time > 1.0:  # Log requests taking more than 1 second
            self._log_slow_request(request, response_time)
        
        return response

    def _generate_request_id(self, request) -> str:
        """Generate unique request ID"""
        data = f"{request.META.get('REMOTE_ADDR', '')}{time()}{request.path}"
        return hashlib.md5(data.encode()).hexdigest()[:16]

    def _log_slow_request(self, request, response_time: float):
        """Log slow requests for monitoring"""
        # In production, you'd send this to a monitoring service
        slow_request_data = {
            'path': request.path,
            'method': request.method,
            'response_time': response_time,
            'user_agent': request.META.get('HTTP_USER_AGENT', ''),
            'ip': request.META.get('REMOTE_ADDR', ''),
            'timestamp': time()
        }
        
        # Store in cache for monitoring dashboard
        cache_key = f"slow_request:{int(time())}"
        self.performance_cache.set(cache_key, slow_request_data, timeout=3600)


class SecurityHeadersMiddleware(MiddlewareMixin):
    """Add security headers for high-security applications"""

    def __call__(self, request):
        response = self.get_response(request)
        
        # Security headers
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-Frame-Options'] = 'DENY'
        response['X-XSS-Protection'] = '1; mode=block'
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        response['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
        
        # Content Security Policy - Updated to allow CDN resources
        csp = (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' "
            "https://code.jquery.com https://cdn.jsdelivr.net; "
            "style-src 'self' 'unsafe-inline' "
            "https://cdn.jsdelivr.net https://cdnjs.cloudflare.com https://fonts.googleapis.com; "
            "img-src 'self' data: https:; "
            "font-src 'self' data: https://fonts.gstatic.com https://cdnjs.cloudflare.com; "
            "connect-src 'self'; "
            "frame-ancestors 'none';"
        )
        response['Content-Security-Policy'] = csp
        
        return response


