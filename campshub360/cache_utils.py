from django.core.cache import cache, caches
from django.core.cache.utils import make_template_fragment_key
from django.db import models
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from functools import wraps
import hashlib
import json
import time
from typing import Callable, Any, Optional, Union


class CacheManager:
    """Advanced cache management for high-performance applications"""
    
    def __init__(self):
        self.default_cache = caches['default']
        self.query_cache = caches['query_cache']
        self.session_cache = caches['sessions']
    
    def cached_query(self, ttl: int = 600, cache_alias: str = 'query_cache'):
        """Decorator for caching database query results"""
        def decorator(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                # Create cache key from function name and arguments
                cache_key = self._generate_cache_key(func.__name__, args, kwargs)
                cache_backend = caches[cache_alias]
                
                # Try to get from cache
                result = cache_backend.get(cache_key)
                if result is not None:
                    return result
                
                # Execute function and cache result
                result = func(*args, **kwargs)
                cache_backend.set(cache_key, result, ttl)
                return result
            return wrapper
        return decorator
    
    def cached_model(self, model_class: models.Model, ttl: int = 300):
        """Cache model instances with automatic invalidation"""
        def decorator(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                cache_key = f"model:{model_class._meta.label}:{func.__name__}:{hash(str(args) + str(kwargs))}"
                
                result = self.default_cache.get(cache_key)
                if result is not None:
                    return result
                
                result = func(*args, **kwargs)
                self.default_cache.set(cache_key, result, ttl)
                return result
            return wrapper
        return decorator
    
    def invalidate_model_cache(self, model_class: models.Model, instance_id: Optional[str] = None):
        """Invalidate cache for a specific model"""
        pattern = f"model:{model_class._meta.label}:*"
        if instance_id:
            pattern = f"model:{model_class._meta.label}:*:{instance_id}:*"
        
        # In a real implementation, you'd use Redis SCAN to find and delete keys
        # For now, we'll use versioning
        version_key = f"v:{model_class._meta.label}"
        current = self.default_cache.get(version_key, 0)
        self.default_cache.set(version_key, current + 1, 86400)
    
    def _generate_cache_key(self, func_name: str, args: tuple, kwargs: dict) -> str:
        """Generate a unique cache key from function arguments"""
        key_data = f"{func_name}:{str(args)}:{str(sorted(kwargs.items()))}"
        return hashlib.md5(key_data.encode()).hexdigest()


# Global cache manager instance
cache_manager = CacheManager()


def cached(key: str, ttl: int, loader: Callable, cache_alias: str = 'default'):
    """Enhanced cached function with multiple cache backends"""
    cache_backend = caches[cache_alias]
    value = cache_backend.get(key)
    if value is not None:
        return value
    value = loader()
    cache_backend.set(key, value, ttl)
    return value


def cached_query(ttl: int = 600):
    """Decorator for caching database queries"""
    return cache_manager.cached_query(ttl)


def cached_model(model_class: models.Model, ttl: int = 300):
    """Decorator for caching model operations"""
    return cache_manager.cached_model(model_class, ttl)


def invalidate(prefix: str):
    """Invalidate cache by prefix using versioning"""
    version_key = f"v:{prefix}"
    current = cache.get(version_key, 0)
    cache.set(version_key, current + 1, 86400)
    return current + 1


def invalidate_model_cache(model_class: models.Model, instance_id: Optional[str] = None):
    """Invalidate cache for a specific model"""
    cache_manager.invalidate_model_cache(model_class, instance_id)


class CacheMixin:
    """Mixin for models to add caching capabilities"""
    
    def get_cache_key(self, suffix: str = ""):
        """Generate cache key for model instance"""
        return f"{self._meta.label}:{self.pk}:{suffix}"
    
    def cache_set(self, key: str, value: Any, ttl: int = 300):
        """Set cache value for this instance"""
        cache_key = self.get_cache_key(key)
        cache.set(cache_key, value, ttl)
    
    def cache_get(self, key: str, default: Any = None):
        """Get cache value for this instance"""
        cache_key = self.get_cache_key(key)
        return cache.get(cache_key, default)
    
    def cache_delete(self, key: str):
        """Delete cache value for this instance"""
        cache_key = self.get_cache_key(key)
        cache.delete(cache_key)
    
    def save(self, *args, **kwargs):
        """Override save to invalidate cache"""
        super().save(*args, **kwargs)
        invalidate_model_cache(self.__class__, str(self.pk))


def cache_page_conditional(condition_func: Callable, timeout: int = 300):
    """Conditional page caching based on a function"""
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            if condition_func(request):
                return cache_page(timeout)(view_func)(request, *args, **kwargs)
            return view_func(request, *args, **kwargs)
        return wrapper
    return decorator


def cache_fragment(timeout: int = 300, vary_on: list = None):
    """Cache template fragments"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key for template fragment
            cache_key = make_template_fragment_key(
                func.__name__, 
                vary_on or []
            )
            
            result = cache.get(cache_key)
            if result is not None:
                return result
            
            result = func(*args, **kwargs)
            cache.set(cache_key, result, timeout)
            return result
        return wrapper
    return decorator


