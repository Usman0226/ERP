# CampsHub360 Backend - Deployment Guide

## 🚨 Fixing the Render Deployment Error

The error you encountered:
```
ModuleNotFoundError: No module named 'app'
```

This happens because gunicorn is looking for `app:app` but your Django project has the WSGI application at `campshub360.wsgi:application`.

## ✅ Solution: Updated Configuration Files

I've created the following files to fix your deployment:

### 1. `render.yaml` - Render Configuration
```yaml
services:
  - type: web
    name: campshub360-backend
    env: python
    plan: free
    buildCommand: chmod +x build.sh && ./build.sh
    startCommand: gunicorn campshub360.wsgi:application
    envVars:
      - key: PYTHON_VERSION
        value: 3.11.0
      - key: DJANGO_SETTINGS_MODULE
        value: campshub360.production
      - key: SECRET_KEY
        generateValue: true
      - key: DEBUG
        value: false
      - key: ALLOWED_HOSTS
        value: ".onrender.com"
      - key: POSTGRES_DB
        value: "campshub360"
      - key: POSTGRES_USER
        value: "campshub360_user"
      - key: POSTGRES_HOST
        value: "localhost"
      - key: POSTGRES_PORT
        value: "5432"
```

### 2. `build.sh` - Build Script
```bash
#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
pip install -r requirements.txt

# Collect static files
python manage.py collectstatic --no-input

# Run database migrations
python manage.py migrate
```

### 3. `campshub360/production.py` - Production Settings
Production-specific Django settings that handle environment variables properly.

### 4. `gunicorn.conf.py` - Gunicorn Configuration
Optimized gunicorn settings for production deployment.

## 🚀 Step-by-Step Deployment on Render

### Step 1: Update Your Repository
1. Commit and push all the new configuration files to your repository
2. Ensure your repository is connected to Render

### Step 2: Configure Render Service
1. Go to your Render dashboard
2. Select your web service
3. Go to **Settings** tab
4. Update the following fields:

**Build Command:**
```bash
chmod +x build.sh && ./build.sh
```

**Start Command:**
```bash
gunicorn campshub360.wsgi:application
```

**Environment Variables:**
- `PYTHON_VERSION`: `3.11.0`
- `DJANGO_SETTINGS_MODULE`: `campshub360.production`
- `SECRET_KEY`: `Generate` (Render will auto-generate this)
- `DEBUG`: `false`
- `ALLOWED_HOSTS`: `.onrender.com`

### Step 3: Deploy
1. Click **Manual Deploy** → **Deploy Latest Commit**
2. Monitor the build logs
3. Wait for deployment to complete

## 🔧 Alternative: Manual Configuration

If you prefer to configure manually without the `render.yaml`:

### Build Command
```bash
chmod +x build.sh && ./build.sh
```

### Start Command
```bash
gunicorn campshub360.wsgi:application
```

### Environment Variables
Set these in your Render service settings:

| Key | Value |
|-----|-------|
| `PYTHON_VERSION` | `3.11.0` |
| `DJANGO_SETTINGS_MODULE` | `campshub360.production` |
| `SECRET_KEY` | `Generate` |
| `DEBUG` | `false` |
| `ALLOWED_HOSTS` | `.onrender.com` |

## 🗄️ Database Configuration

For production, you'll need a PostgreSQL database:

1. **Create a PostgreSQL service** in Render
2. **Add database environment variables** to your web service:
   - `POSTGRES_DB`
   - `POSTGRES_USER` 
   - `POSTGRES_PASSWORD`
   - `POSTGRES_HOST`
   - `POSTGRES_PORT`

## 📝 Important Notes

1. **WSGI Application Path**: Always use `campshub360.wsgi:application` for Django projects
2. **Settings Module**: Use `campshub360.production` for production deployment
3. **Static Files**: The build script will collect static files automatically
4. **Migrations**: Database migrations run automatically during build
5. **Environment Variables**: Never commit sensitive data like SECRET_KEY

## 🐛 Troubleshooting

### Common Issues:

1. **Module not found errors**: Check your `startCommand` uses the correct WSGI path
2. **Build failures**: Ensure `build.sh` has execute permissions
3. **Database connection errors**: Verify PostgreSQL environment variables
4. **Static file errors**: Check if `STATIC_ROOT` is configured in production settings

### Debug Commands:

If you need to debug, temporarily set `DEBUG=true` in your environment variables.

## 🔄 Redeployment

After making changes:
1. Commit and push your code
2. Go to your Render service
3. Click **Manual Deploy** → **Deploy Latest Commit**

## 📚 Additional Resources

- [Render Documentation](https://render.com/docs)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/)
- [Gunicorn Configuration](https://docs.gunicorn.org/en/stable/configure.html)

---

**Your deployment should now work correctly!** The key fix was changing from `gunicorn app:app` to `gunicorn campshub360.wsgi:application`.
