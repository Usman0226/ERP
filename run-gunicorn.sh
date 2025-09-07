#!/usr/bin/env bash
set -euo pipefail

export PYTHONUNBUFFERED=1
export DJANGO_SETTINGS_MODULE=campshub360.settings

# Default envs if not provided
: "${GUNICORN_BIND:=0.0.0.0:8000}"
: "${GUNICORN_WORKERS:=4}"
: "${GUNICORN_WORKER_CLASS:=gevent}"
: "${GUNICORN_WORKER_CONNECTIONS:=1000}"
: "${GUNICORN_TIMEOUT:=60}"
: "${GUNICORN_KEEPALIVE:=10}"

python manage.py collectstatic --noinput
python manage.py migrate --noinput

exec gunicorn \
  --config gunicorn.conf.py \
  --bind "$GUNICORN_BIND" \
  --workers "$GUNICORN_WORKERS" \
  --worker-class "$GUNICORN_WORKER_CLASS" \
  --worker-connections "$GUNICORN_WORKER_CONNECTIONS" \
  --timeout "$GUNICORN_TIMEOUT" \
  --keep-alive "$GUNICORN_KEEPALIVE" \
  campshub360.wsgi:application
