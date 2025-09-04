"""
Performance Monitoring System for High-Performance Applications
Tracks metrics, alerts on issues, and provides optimization insights
"""
import time
import threading
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from django.core.cache import cache
from django.conf import settings
from django.db import connection
import logging

# Optional imports for system monitoring
try:
    import psutil
    PSUTIL_AVAILABLE = True
except ImportError:
    PSUTIL_AVAILABLE = False

logger = logging.getLogger(__name__)


class PerformanceMonitor:
    """Comprehensive performance monitoring system"""
    
    def __init__(self):
        self.metrics_cache = cache
        self.alert_thresholds = {
            'response_time': 1.0,  # 1 second
            'db_query_time': 0.5,  # 500ms
            'memory_usage': 80,    # 80%
            'cpu_usage': 80,       # 80%
            'error_rate': 5,       # 5%
            'cache_hit_rate': 70,  # 70%
        }
        self.monitoring_active = True
        self._start_background_monitoring()
    
    def record_request_metrics(self, request_data: Dict[str, Any]):
        """Record metrics for a request"""
        timestamp = int(time.time())
        key = f"metrics:request:{timestamp}"
        
        # Store request metrics
        self.metrics_cache.set(key, request_data, 3600)  # 1 hour
        
        # Update aggregated metrics
        self._update_aggregated_metrics(request_data)
        
        # Check for alerts
        self._check_alerts(request_data)
    
    def record_database_metrics(self, query_data: Dict[str, Any]):
        """Record database query metrics"""
        timestamp = int(time.time())
        key = f"metrics:db:{timestamp}"
        
        self.metrics_cache.set(key, query_data, 3600)
        self._update_db_aggregated_metrics(query_data)
    
    def record_cache_metrics(self, cache_data: Dict[str, Any]):
        """Record cache performance metrics"""
        timestamp = int(time.time())
        key = f"metrics:cache:{timestamp}"
        
        self.metrics_cache.set(key, cache_data, 3600)
        self._update_cache_aggregated_metrics(cache_data)
    
    def get_system_metrics(self) -> Dict[str, Any]:
        """Get current system metrics"""
        if PSUTIL_AVAILABLE:
            return {
                'cpu_percent': psutil.cpu_percent(interval=1),
                'memory_percent': psutil.virtual_memory().percent,
                'disk_usage': psutil.disk_usage('/').percent,
                'network_io': psutil.net_io_counters()._asdict(),
                'timestamp': datetime.now().isoformat()
            }
        else:
            return {
                'cpu_percent': 0,
                'memory_percent': 0,
                'disk_usage': 0,
                'network_io': {},
                'timestamp': datetime.now().isoformat(),
                'note': 'psutil not available - system metrics disabled'
            }
    
    def get_performance_summary(self, time_window: int = 300) -> Dict[str, Any]:
        """Get performance summary for the last time_window seconds"""
        now = int(time.time())
        start_time = now - time_window
        
        # Get request metrics
        request_metrics = self._get_metrics_in_range('request', start_time, now)
        db_metrics = self._get_metrics_in_range('db', start_time, now)
        cache_metrics = self._get_metrics_in_range('cache', start_time, now)
        
        return {
            'time_window': time_window,
            'requests': self._calculate_request_summary(request_metrics),
            'database': self._calculate_db_summary(db_metrics),
            'cache': self._calculate_cache_summary(cache_metrics),
            'system': self.get_system_metrics(),
            'alerts': self._get_active_alerts()
        }
    
    def _start_background_monitoring(self):
        """Start background monitoring thread"""
        def monitor_loop():
            while self.monitoring_active:
                try:
                    # Record system metrics every 30 seconds
                    system_metrics = self.get_system_metrics()
                    timestamp = int(time.time())
                    key = f"metrics:system:{timestamp}"
                    self.metrics_cache.set(key, system_metrics, 3600)
                    
                    # Check for system alerts
                    self._check_system_alerts(system_metrics)
                    
                    time.sleep(30)
                except Exception as e:
                    logger.error(f"Error in background monitoring: {e}")
                    time.sleep(60)
        
        monitor_thread = threading.Thread(target=monitor_loop, daemon=True)
        monitor_thread.start()
    
    def _update_aggregated_metrics(self, request_data: Dict[str, Any]):
        """Update aggregated request metrics"""
        current_minute = int(time.time() // 60)
        key = f"aggregated:requests:{current_minute}"
        
        aggregated = self.metrics_cache.get(key, {
            'total_requests': 0,
            'total_response_time': 0,
            'error_count': 0,
            'status_codes': {}
        })
        
        aggregated['total_requests'] += 1
        aggregated['total_response_time'] += request_data.get('response_time', 0)
        
        if request_data.get('status_code', 200) >= 400:
            aggregated['error_count'] += 1
        
        status_code = request_data.get('status_code', 200)
        aggregated['status_codes'][str(status_code)] = aggregated['status_codes'].get(str(status_code), 0) + 1
        
        self.metrics_cache.set(key, aggregated, 3600)
    
    def _update_db_aggregated_metrics(self, query_data: Dict[str, Any]):
        """Update aggregated database metrics"""
        current_minute = int(time.time() // 60)
        key = f"aggregated:db:{current_minute}"
        
        aggregated = self.metrics_cache.get(key, {
            'total_queries': 0,
            'total_query_time': 0,
            'slow_queries': 0,
            'query_types': {}
        })
        
        aggregated['total_queries'] += 1
        query_time = query_data.get('execution_time', 0)
        aggregated['total_query_time'] += query_time
        
        if query_time > 0.5:  # Slow query threshold
            aggregated['slow_queries'] += 1
        
        query_type = query_data.get('query_type', 'unknown')
        aggregated['query_types'][query_type] = aggregated['query_types'].get(query_type, 0) + 1
        
        self.metrics_cache.set(key, aggregated, 3600)
    
    def _update_cache_aggregated_metrics(self, cache_data: Dict[str, Any]):
        """Update aggregated cache metrics"""
        current_minute = int(time.time() // 60)
        key = f"aggregated:cache:{current_minute}"
        
        aggregated = self.metrics_cache.get(key, {
            'total_requests': 0,
            'hits': 0,
            'misses': 0,
            'hit_rate': 0
        })
        
        aggregated['total_requests'] += 1
        if cache_data.get('hit', False):
            aggregated['hits'] += 1
        else:
            aggregated['misses'] += 1
        
        if aggregated['total_requests'] > 0:
            aggregated['hit_rate'] = (aggregated['hits'] / aggregated['total_requests']) * 100
        
        self.metrics_cache.set(key, aggregated, 3600)
    
    def _get_metrics_in_range(self, metric_type: str, start_time: int, end_time: int) -> List[Dict[str, Any]]:
        """Get metrics within a time range"""
        metrics = []
        for timestamp in range(start_time, end_time + 1):
            key = f"metrics:{metric_type}:{timestamp}"
            metric_data = self.metrics_cache.get(key)
            if metric_data:
                metrics.append(metric_data)
        return metrics
    
    def _calculate_request_summary(self, request_metrics: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Calculate request performance summary"""
        if not request_metrics:
            return {}
        
        response_times = [m.get('response_time', 0) for m in request_metrics]
        status_codes = [m.get('status_code', 200) for m in request_metrics]
        
        return {
            'total_requests': len(request_metrics),
            'avg_response_time': sum(response_times) / len(response_times) if response_times else 0,
            'max_response_time': max(response_times) if response_times else 0,
            'min_response_time': min(response_times) if response_times else 0,
            'error_rate': (sum(1 for code in status_codes if code >= 400) / len(status_codes)) * 100,
            'status_codes': {str(code): status_codes.count(code) for code in set(status_codes)}
        }
    
    def _calculate_db_summary(self, db_metrics: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Calculate database performance summary"""
        if not db_metrics:
            return {}
        
        query_times = [m.get('execution_time', 0) for m in db_metrics]
        
        return {
            'total_queries': len(db_metrics),
            'avg_query_time': sum(query_times) / len(query_times) if query_times else 0,
            'max_query_time': max(query_times) if query_times else 0,
            'slow_queries': sum(1 for time in query_times if time > 0.5),
            'query_types': {}
        }
    
    def _calculate_cache_summary(self, cache_metrics: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Calculate cache performance summary"""
        if not cache_metrics:
            return {}
        
        hits = sum(1 for m in cache_metrics if m.get('hit', False))
        total = len(cache_metrics)
        
        return {
            'total_requests': total,
            'hits': hits,
            'misses': total - hits,
            'hit_rate': (hits / total) * 100 if total > 0 else 0
        }
    
    def _check_alerts(self, request_data: Dict[str, Any]):
        """Check for performance alerts"""
        alerts = []
        
        # Response time alert
        if request_data.get('response_time', 0) > self.alert_thresholds['response_time']:
            alerts.append({
                'type': 'high_response_time',
                'value': request_data['response_time'],
                'threshold': self.alert_thresholds['response_time'],
                'timestamp': datetime.now().isoformat()
            })
        
        # Error rate alert
        if request_data.get('status_code', 200) >= 400:
            alerts.append({
                'type': 'error_response',
                'status_code': request_data['status_code'],
                'path': request_data.get('path', ''),
                'timestamp': datetime.now().isoformat()
            })
        
        # Store alerts
        if alerts:
            for alert in alerts:
                alert_key = f"alert:{int(time.time())}:{alert['type']}"
                self.metrics_cache.set(alert_key, alert, 86400)  # 24 hours
    
    def _check_system_alerts(self, system_metrics: Dict[str, Any]):
        """Check for system-level alerts"""
        alerts = []
        
        # Only check system alerts if psutil is available
        if not PSUTIL_AVAILABLE:
            return
        
        # CPU usage alert
        if system_metrics.get('cpu_percent', 0) > self.alert_thresholds['cpu_usage']:
            alerts.append({
                'type': 'high_cpu_usage',
                'value': system_metrics['cpu_percent'],
                'threshold': self.alert_thresholds['cpu_usage'],
                'timestamp': datetime.now().isoformat()
            })
        
        # Memory usage alert
        if system_metrics.get('memory_percent', 0) > self.alert_thresholds['memory_usage']:
            alerts.append({
                'type': 'high_memory_usage',
                'value': system_metrics['memory_percent'],
                'threshold': self.alert_thresholds['memory_usage'],
                'timestamp': datetime.now().isoformat()
            })
        
        # Store alerts
        if alerts:
            for alert in alerts:
                alert_key = f"alert:{int(time.time())}:{alert['type']}"
                self.metrics_cache.set(alert_key, alert, 86400)
    
    def _get_active_alerts(self) -> List[Dict[str, Any]]:
        """Get active alerts from the last hour"""
        now = int(time.time())
        hour_ago = now - 3600
        
        alerts = []
        for timestamp in range(hour_ago, now + 1):
            # Check for different alert types
            for alert_type in ['high_response_time', 'error_response', 'high_cpu_usage', 'high_memory_usage']:
                alert_key = f"alert:{timestamp}:{alert_type}"
                alert_data = self.metrics_cache.get(alert_key)
                if alert_data:
                    alerts.append(alert_data)
        
        return alerts
    
    def get_optimization_recommendations(self) -> List[Dict[str, Any]]:
        """Get performance optimization recommendations"""
        recommendations = []
        
        # Get recent performance data
        summary = self.get_performance_summary(1800)  # Last 30 minutes
        
        # Check response time
        if summary.get('requests', {}).get('avg_response_time', 0) > 0.5:
            recommendations.append({
                'type': 'response_time',
                'priority': 'high',
                'message': 'Average response time is high. Consider adding caching or optimizing database queries.',
                'current_value': summary['requests']['avg_response_time'],
                'target_value': 0.2
            })
        
        # Check cache hit rate
        cache_hit_rate = summary.get('cache', {}).get('hit_rate', 0)
        if cache_hit_rate < 70:
            recommendations.append({
                'type': 'cache_optimization',
                'priority': 'medium',
                'message': 'Cache hit rate is low. Consider increasing cache TTL or adding more cache layers.',
                'current_value': cache_hit_rate,
                'target_value': 80
            })
        
        # Check database performance
        avg_query_time = summary.get('database', {}).get('avg_query_time', 0)
        if avg_query_time > 0.3:
            recommendations.append({
                'type': 'database_optimization',
                'priority': 'high',
                'message': 'Database queries are slow. Consider adding indexes or optimizing queries.',
                'current_value': avg_query_time,
                'target_value': 0.1
            })
        
        return recommendations


# Global performance monitor instance
performance_monitor = PerformanceMonitor()


def monitor_performance(view_func):
    """Decorator to monitor view performance"""
    def wrapper(request, *args, **kwargs):
        start_time = time.time()
        
        try:
            response = view_func(request, *args, **kwargs)
            status_code = response.status_code
        except Exception as e:
            status_code = 500
            raise
        finally:
            response_time = time.time() - start_time
            
            # Record metrics
            request_data = {
                'path': request.path,
                'method': request.method,
                'response_time': response_time,
                'status_code': status_code,
                'user_id': getattr(request.user, 'id', None) if hasattr(request, 'user') else None,
                'timestamp': datetime.now().isoformat()
            }
            
            performance_monitor.record_request_metrics(request_data)
        
        return response
    return wrapper
