"""
Health check endpoints for monitoring and load balancers
"""
from django.http import JsonResponse
from django.db import connection
from django.core.cache import cache
from django.conf import settings
import time
import os

# Optional imports for system monitoring
try:
    import psutil
    PSUTIL_AVAILABLE = True
except ImportError:
    PSUTIL_AVAILABLE = False


def health_check(request):
    """Basic health check endpoint"""
    return JsonResponse({
        'status': 'healthy',
        'timestamp': time.time(),
        'service': 'campshub360-backend'
    })


def detailed_health_check(request):
    """Detailed health check with system metrics"""
    health_data = {
        'status': 'healthy',
        'timestamp': time.time(),
        'service': 'campshub360-backend',
        'checks': {}
    }
    
    # Database check
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            health_data['checks']['database'] = {
                'status': 'healthy',
                'response_time': 0
            }
    except Exception as e:
        health_data['checks']['database'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        health_data['status'] = 'unhealthy'
    
    # Cache check
    try:
        start_time = time.time()
        cache.set('health_check', 'test', 10)
        cache.get('health_check')
        health_data['checks']['cache'] = {
            'status': 'healthy',
            'response_time': time.time() - start_time
        }
    except Exception as e:
        health_data['checks']['cache'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        health_data['status'] = 'unhealthy'
    
    # System resources
    try:
        if PSUTIL_AVAILABLE:
            health_data['checks']['system'] = {
                'status': 'healthy',
                'cpu_percent': psutil.cpu_percent(),
                'memory_percent': psutil.virtual_memory().percent,
                'disk_percent': psutil.disk_usage('/').percent
            }
        else:
            health_data['checks']['system'] = {
                'status': 'limited',
                'message': 'psutil not available - system metrics disabled'
            }
    except Exception as e:
        health_data['checks']['system'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
    
    return JsonResponse(health_data)


def readiness_check(request):
    """Readiness check for Kubernetes/Docker"""
    try:
        # Check if database is ready
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        # Check if cache is ready
        cache.set('readiness_check', 'test', 10)
        cache.get('readiness_check')
        
        return JsonResponse({
            'status': 'ready',
            'timestamp': time.time()
        })
    except Exception as e:
        return JsonResponse({
            'status': 'not_ready',
            'error': str(e),
            'timestamp': time.time()
        }, status=503)


def liveness_check(request):
    """Liveness check for Kubernetes/Docker"""
    return JsonResponse({
        'status': 'alive',
        'timestamp': time.time(),
        'pid': os.getpid()
    })
