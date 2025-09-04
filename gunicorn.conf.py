# High-Performance Gunicorn configuration for 20k+ users/sec
import multiprocessing
import os

# Server socket
bind = os.getenv('GUNICORN_BIND', "0.0.0.0:10000")
backlog = int(os.getenv('GUNICORN_BACKLOG', '4096'))

# Worker processes - Optimized for high concurrency
workers = int(os.getenv('GUNICORN_WORKERS', multiprocessing.cpu_count() * 4 + 1))
worker_class = os.getenv('GUNICORN_WORKER_CLASS', 'gevent')  # Async workers for high concurrency
worker_connections = int(os.getenv('GUNICORN_WORKER_CONNECTIONS', '2000'))
timeout = int(os.getenv('GUNICORN_TIMEOUT', '30'))
keepalive = int(os.getenv('GUNICORN_KEEPALIVE', '5'))

# Restart workers after this many requests, to help prevent memory leaks
max_requests = int(os.getenv('GUNICORN_MAX_REQUESTS', '10000'))
max_requests_jitter = int(os.getenv('GUNICORN_MAX_REQUESTS_JITTER', '1000'))

# Memory management
max_requests_jitter = 1000
preload_app = True  # Load application code before forking workers

# Logging - Enhanced for monitoring
accesslog = "-"
errorlog = "-"
loglevel = os.getenv('GUNICORN_LOG_LEVEL', 'info')
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s %(p)s'

# Process naming
proc_name = "campshub360-high-perf"

# Server mechanics
daemon = False
pidfile = "/tmp/gunicorn.pid"
user = None
group = None
tmp_upload_dir = None

# SSL (not needed for Render)
keyfile = None
certfile = None

# Performance tuning
worker_tmp_dir = "/dev/shm"  # Use RAM for temporary files
worker_class = "gevent"  # Use gevent for async I/O

# Graceful shutdown
graceful_timeout = 30
forwarded_allow_ips = "*"

# Security
limit_request_line = 4096
limit_request_fields = 100
limit_request_field_size = 8192

# Environment variables for high performance
raw_env = [
    'DJANGO_SETTINGS_MODULE=campshub360.production',
    'PYTHONPATH=/app',
]
