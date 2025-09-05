"""
AWS Production settings for CampsHub360
Uses AWS RDS PostgreSQL for production deployment
"""
import os
from .settings import *

# AWS RDS PostgreSQL Database Configuration
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('AWS_POSTGRES_DB', 'campushub360'),
        'USER': os.getenv('AWS_POSTGRES_USER', 'postgres'),
        'PASSWORD': os.getenv('AWS_POSTGRES_PASSWORD'),
        'HOST': os.getenv('AWS_POSTGRES_HOST'),  # Your RDS endpoint
        'PORT': int(os.getenv('AWS_POSTGRES_PORT', '5432')),
        'CONN_MAX_AGE': 600,  # 10 minutes connection pooling
        'OPTIONS': {
            'connect_timeout': 10,
            'sslmode': 'require',  # AWS RDS requires SSL
        },
        'ATOMIC_REQUESTS': True,
    },
    'read_replica': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('AWS_POSTGRES_DB', 'campushub360'),
        'USER': os.getenv('AWS_POSTGRES_USER', 'postgres'),
        'PASSWORD': os.getenv('AWS_POSTGRES_PASSWORD'),
        'HOST': os.getenv('AWS_POSTGRES_REPLICA_HOST', os.getenv('AWS_POSTGRES_HOST')),
        'PORT': int(os.getenv('AWS_POSTGRES_REPLICA_PORT', os.getenv('AWS_POSTGRES_PORT', '5432'))),
        'CONN_MAX_AGE': 600,
        'OPTIONS': {
            'connect_timeout': 10,
            'sslmode': 'require',
        },
    }
}

# Re-enable database router for read replicas
DATABASE_ROUTERS = ['campshub360.db_router.DatabaseRouter']

# Use local memory cache for development (Redis compatibility issues fixed)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake-aws',
        'TIMEOUT': 300,
        'OPTIONS': {
            'MAX_ENTRIES': 1000,
        }
    },
    'sessions': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake-sessions-aws',
        'TIMEOUT': 86400,  # 24 hours
        'OPTIONS': {
            'MAX_ENTRIES': 1000,
        }
    },
    'query_cache': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake-query-aws',
        'TIMEOUT': 600,  # 10 minutes
        'OPTIONS': {
            'MAX_ENTRIES': 1000,
        }
    }
}

# Use Redis for sessions in production
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'sessions'

# Production security settings
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True

# CSRF Protection
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_HTTPONLY = True
CSRF_COOKIE_SAMESITE = 'Strict'

# Session Security
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Strict'
SESSION_COOKIE_AGE = 3600  # 1 hour

# AWS-specific settings
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'yourdomain.com,www.yourdomain.com').split(',')

# Disable debug in production
DEBUG = False

# AWS S3 for static files (optional)
# STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
# DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
# AWS_STORAGE_BUCKET_NAME = os.getenv('AWS_STORAGE_BUCKET_NAME')
# AWS_S3_REGION_NAME = os.getenv('AWS_S3_REGION_NAME', 'us-east-1')
# AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'

# Logging configuration for AWS CloudWatch
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False,
        },
        'campshub360': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
