"""
High-Security Module for CampsHub360
Implements advanced security measures for production environments
"""
import hashlib
import hmac
import secrets
import time
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from django.conf import settings
from django.core.cache import cache
from django.http import HttpRequest, HttpResponse
from django.utils.crypto import constant_time_compare
from django.contrib.auth.models import User
import logging

logger = logging.getLogger(__name__)


class SecurityManager:
    """Advanced security management for high-performance applications"""
    
    def __init__(self):
        self.failed_attempts_cache = cache
        self.security_events_cache = cache
        self.max_failed_attempts = 5
        self.lockout_duration = 300  # 5 minutes
        self.rate_limit_window = 60  # 1 minute
        
    def check_brute_force_protection(self, identifier: str, request: HttpRequest) -> bool:
        """Check if identifier is locked due to brute force attempts"""
        lockout_key = f"security:lockout:{identifier}"
        return self.failed_attempts_cache.get(lockout_key) is not None
    
    def record_failed_attempt(self, identifier: str, request: HttpRequest):
        """Record a failed authentication attempt"""
        attempts_key = f"security:attempts:{identifier}"
        lockout_key = f"security:lockout:{identifier}"
        
        # Get current attempts
        attempts = self.failed_attempts_cache.get(attempts_key, 0) + 1
        
        if attempts >= self.max_failed_attempts:
            # Lock out the identifier
            self.failed_attempts_cache.set(lockout_key, True, self.lockout_duration)
            self._log_security_event('brute_force_lockout', {
                'identifier': identifier,
                'ip': self._get_client_ip(request),
                'user_agent': request.META.get('HTTP_USER_AGENT', ''),
                'attempts': attempts
            })
        else:
            # Increment attempts counter
            self.failed_attempts_cache.set(attempts_key, attempts, self.rate_limit_window)
    
    def clear_failed_attempts(self, identifier: str):
        """Clear failed attempts for successful authentication"""
        attempts_key = f"security:attempts:{identifier}"
        lockout_key = f"security:lockout:{identifier}"
        
        self.failed_attempts_cache.delete(attempts_key)
        self.failed_attempts_cache.delete(lockout_key)
    
    def generate_secure_token(self, length: int = 32) -> str:
        """Generate a cryptographically secure token"""
        return secrets.token_urlsafe(length)
    
    def hash_sensitive_data(self, data: str, salt: Optional[str] = None) -> str:
        """Hash sensitive data with optional salt"""
        if salt is None:
            salt = secrets.token_hex(16)
        
        data_to_hash = f"{data}:{salt}:{settings.SECRET_KEY}"
        return hashlib.sha256(data_to_hash.encode()).hexdigest()
    
    def verify_secure_hash(self, data: str, hash_value: str, salt: str) -> bool:
        """Verify a secure hash"""
        expected_hash = self.hash_sensitive_data(data, salt)
        return constant_time_compare(hash_value, expected_hash)
    
    def check_suspicious_activity(self, request: HttpRequest, user: Optional[User] = None) -> bool:
        """Check for suspicious activity patterns"""
        ip = self._get_client_ip(request)
        user_agent = request.META.get('HTTP_USER_AGENT', '')
        
        # Check for suspicious patterns
        suspicious_patterns = [
            'sqlmap', 'nikto', 'nmap', 'masscan', 'zap', 'burp',
            'wget', 'curl', 'python-requests', 'bot', 'crawler'
        ]
        
        user_agent_lower = user_agent.lower()
        for pattern in suspicious_patterns:
            if pattern in user_agent_lower:
                self._log_security_event('suspicious_user_agent', {
                    'ip': ip,
                    'user_agent': user_agent,
                    'user_id': user.id if user else None,
                    'path': request.path
                })
                return True
        
        # Check for rapid requests from same IP
        rapid_requests_key = f"security:rapid_requests:{ip}"
        request_count = self.failed_attempts_cache.get(rapid_requests_key, 0) + 1
        
        if request_count > 100:  # More than 100 requests per minute
            self._log_security_event('rapid_requests', {
                'ip': ip,
                'request_count': request_count,
                'user_id': user.id if user else None
            })
            return True
        
        self.failed_attempts_cache.set(rapid_requests_key, request_count, 60)
        return False
    
    def validate_request_integrity(self, request: HttpRequest) -> bool:
        """Validate request integrity and authenticity"""
        # Check for required headers
        required_headers = ['User-Agent', 'Accept']
        for header in required_headers:
            if header not in request.META:
                return False
        
        # Check for suspicious request patterns
        if len(request.path) > 2000:  # Extremely long URLs
            return False
        
        if len(request.META.get('QUERY_STRING', '')) > 2000:  # Long query strings
            return False
        
        return True
    
    def _get_client_ip(self, request: HttpRequest) -> str:
        """Get real client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR', 'unknown')
        return ip
    
    def _log_security_event(self, event_type: str, event_data: Dict[str, Any]):
        """Log security events for monitoring"""
        event = {
            'type': event_type,
            'timestamp': datetime.now().isoformat(),
            'data': event_data
        }
        
        # Store in cache for monitoring dashboard
        event_key = f"security:event:{int(time())}:{secrets.token_hex(8)}"
        self.security_events_cache.set(event_key, event, 86400)  # 24 hours
        
        # Log to application logs
        logger.warning(f"Security Event: {event_type}", extra=event_data)


class APIKeyManager:
    """Manage API keys for secure API access"""
    
    def __init__(self):
        self.cache = cache
    
    def generate_api_key(self, user_id: str, permissions: list = None) -> str:
        """Generate a new API key for a user"""
        if permissions is None:
            permissions = ['read']
        
        key_id = secrets.token_hex(16)
        key_secret = secrets.token_urlsafe(32)
        api_key = f"{key_id}.{key_secret}"
        
        # Store key metadata
        key_data = {
            'user_id': user_id,
            'permissions': permissions,
            'created_at': datetime.now().isoformat(),
            'last_used': None,
            'is_active': True
        }
        
        self.cache.set(f"api_key:{key_id}", key_data, 86400 * 30)  # 30 days
        return api_key
    
    def validate_api_key(self, api_key: str) -> Optional[Dict[str, Any]]:
        """Validate an API key and return its metadata"""
        try:
            key_id, key_secret = api_key.split('.', 1)
        except ValueError:
            return None
        
        key_data = self.cache.get(f"api_key:{key_id}")
        if not key_data or not key_data.get('is_active'):
            return None
        
        # Update last used timestamp
        key_data['last_used'] = datetime.now().isoformat()
        self.cache.set(f"api_key:{key_id}", key_data, 86400 * 30)
        
        return key_data
    
    def revoke_api_key(self, api_key: str) -> bool:
        """Revoke an API key"""
        try:
            key_id, _ = api_key.split('.', 1)
            key_data = self.cache.get(f"api_key:{key_id}")
            if key_data:
                key_data['is_active'] = False
                self.cache.set(f"api_key:{key_id}", key_data, 86400 * 30)
                return True
        except ValueError:
            pass
        return False


class DataEncryption:
    """Handle encryption/decryption of sensitive data"""
    
    def __init__(self):
        self.secret_key = settings.SECRET_KEY.encode()
    
    def encrypt_data(self, data: str) -> str:
        """Encrypt sensitive data"""
        from cryptography.fernet import Fernet
        import base64
        
        # Generate a key from the secret key
        key = base64.urlsafe_b64encode(hashlib.sha256(self.secret_key).digest())
        f = Fernet(key)
        
        encrypted_data = f.encrypt(data.encode())
        return base64.urlsafe_b64encode(encrypted_data).decode()
    
    def decrypt_data(self, encrypted_data: str) -> str:
        """Decrypt sensitive data"""
        from cryptography.fernet import Fernet
        import base64
        
        try:
            key = base64.urlsafe_b64encode(hashlib.sha256(self.secret_key).digest())
            f = Fernet(key)
            
            decoded_data = base64.urlsafe_b64decode(encrypted_data.encode())
            decrypted_data = f.decrypt(decoded_data)
            return decrypted_data.decode()
        except Exception:
            return None


# Global security manager instance
security_manager = SecurityManager()
api_key_manager = APIKeyManager()
data_encryption = DataEncryption()


def require_secure_connection(view_func):
    """Decorator to require HTTPS connections"""
    def wrapper(request, *args, **kwargs):
        if not request.is_secure() and not settings.DEBUG:
            from django.http import HttpResponseBadRequest
            return HttpResponseBadRequest("HTTPS required")
        return view_func(request, *args, **kwargs)
    return wrapper


def rate_limit_by_user(view_func):
    """Decorator to rate limit by user"""
    def wrapper(request, *args, **kwargs):
        if request.user.is_authenticated:
            user_id = str(request.user.id)
            if security_manager.check_brute_force_protection(user_id, request):
                from django.http import HttpResponseTooManyRequests
                return HttpResponseTooManyRequests("Rate limit exceeded")
        return view_func(request, *args, **kwargs)
    return wrapper


def log_security_events(view_func):
    """Decorator to log security events"""
    def wrapper(request, *args, **kwargs):
        # Check for suspicious activity
        if security_manager.check_suspicious_activity(request, getattr(request, 'user', None)):
            from django.http import HttpResponseForbidden
            return HttpResponseForbidden("Suspicious activity detected")
        
        # Validate request integrity
        if not security_manager.validate_request_integrity(request):
            from django.http import HttpResponseBadRequest
            return HttpResponseBadRequest("Invalid request")
        
        return view_func(request, *args, **kwargs)
    return wrapper
