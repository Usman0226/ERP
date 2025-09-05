"""
Security configurations and utilities for CampsHub360 production deployment.
"""

import os
import secrets
import string
from django.core.management.base import BaseCommand


def generate_secret_key(length=50):
    """Generate a secure secret key for Django"""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*(-_=+)"
    return ''.join(secrets.choice(alphabet) for _ in range(length))


def validate_environment_security():
    """Validate that all required security environment variables are set"""
    required_vars = [
        'SECRET_KEY',
        'POSTGRES_PASSWORD',
        'ALLOWED_HOSTS',
    ]
    
    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")
    
    # Validate SECRET_KEY strength
    secret_key = os.getenv('SECRET_KEY')
    if len(secret_key) < 50:
        raise ValueError("SECRET_KEY must be at least 50 characters long")
    
    # Validate ALLOWED_HOSTS
    allowed_hosts = os.getenv('ALLOWED_HOSTS', '').split(',')
    if not allowed_hosts or allowed_hosts == ['']:
        raise ValueError("ALLOWED_HOSTS must be set in production")
    
    return True


def get_security_headers():
    """Get comprehensive security headers for production"""
    return {
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
        'Permissions-Policy': 'geolocation=(), microphone=(), camera=(), payment=(), usb=()',
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
        'Content-Security-Policy': (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' "
            "https://code.jquery.com https://cdn.jsdelivr.net; "
            "style-src 'self' 'unsafe-inline' "
            "https://cdn.jsdelivr.net https://cdnjs.cloudflare.com https://fonts.googleapis.com; "
            "img-src 'self' data: https:; "
            "font-src 'self' data: https://fonts.gstatic.com https://cdnjs.cloudflare.com; "
            "connect-src 'self'; "
            "frame-ancestors 'none';"
        ),
    }


class SecurityCommand(BaseCommand):
    """Django management command for security operations"""
    help = 'Security utilities for CampsHub360'

    def add_arguments(self, parser):
        parser.add_argument(
            '--generate-secret-key',
            action='store_true',
            help='Generate a new secret key',
        )
        parser.add_argument(
            '--validate-env',
            action='store_true',
            help='Validate environment security settings',
        )

    def handle(self, *args, **options):
        if options['generate_secret_key']:
            secret_key = generate_secret_key()
            self.stdout.write(
                self.style.SUCCESS(f'Generated secret key: {secret_key}')
            )
            self.stdout.write(
                self.style.WARNING('Add this to your .env file as SECRET_KEY=...')
            )

        if options['validate_env']:
            try:
                validate_environment_security()
                self.stdout.write(
                    self.style.SUCCESS('Environment security validation passed')
                )
            except ValueError as e:
                self.stdout.write(
                    self.style.ERROR(f'Security validation failed: {e}')
                )