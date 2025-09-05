# High-Performance Gunicorn configuration for 20k+ users/sec
import multiprocessing
import os

# Server socket
bind = os.getenv('GUNICORN_BIND', "127.0.0.1:8000")
backlog = int(os.getenv('GUNICORN_BACKLOG', '2048'))

# Worker processes - Optimized for production
workers = int(os.getenv('GUNICORN_WORKERS', multiprocessing.cpu_count() * 2 + 1))
worker_class = os.getenv('GUNICORN_WORKER_CLASS', 'gevent')
worker_connections = int(os.getenv('GUNICORN_WORKER_CONNECTIONS', '1000'))
timeout = int(os.getenv('GUNICORN_TIMEOUT', '30'))
keepalive = int(os.getenv('GUNICORN_KEEPALIVE', '5'))

# Restart workers after this many requests, to help prevent memory leaks
max_requests = int(os.getenv('GUNICORN_MAX_REQUESTS', '1000'))
max_requests_jitter = int(os.getenv('GUNICORN_MAX_REQUESTS_JITTER', '100'))

# Memory management
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
