#!/usr/bin/env python
"""
Local development server runner for CampsHub360
Uses SQLite database and local settings for easy development
"""
import os
import sys
import django
from django.core.management import execute_from_command_line

if __name__ == "__main__":
    # Set Django settings module to local settings
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'campshub360.local_settings')
    
    # Setup Django
    django.setup()
    
    # Run migrations first
    print("🔄 Running database migrations...")
    execute_from_command_line(['manage.py', 'migrate'])
    
    # Create superuser if it doesn't exist
    print("👤 Creating superuser (if needed)...")
    try:
        from django.contrib.auth import get_user_model
        User = get_user_model()
        if not User.objects.filter(username='admin').exists():
            User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
            print("✅ Superuser created: admin/admin123")
        else:
            print("✅ Superuser already exists")
    except Exception as e:
        print(f"⚠️  Could not create superuser: {e}")
    
    # Start the development server
    print("🚀 Starting development server...")
    print("📊 Health check: http://localhost:8000/health/")
    print("🔧 Admin panel: http://localhost:8000/admin/")
    print("📚 API docs: http://localhost:8000/api/")
    print("\nPress Ctrl+C to stop the server")
    
    execute_from_command_line(['manage.py', 'runserver', '8000'])
