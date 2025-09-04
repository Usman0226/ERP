from django.db import models
from django.utils import timezone


class Outbox(models.Model):
    topic = models.CharField(max_length=100)
    key = models.CharField(max_length=100, blank=True)
    payload = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)
    available_at = models.DateTimeField(default=timezone.now)
    delivered_at = models.DateTimeField(null=True, blank=True)
    attempts = models.IntegerField(default=0)
    last_error = models.TextField(blank=True)

    class Meta:
        indexes = [
            models.Index(fields=['topic', 'available_at', 'delivered_at']),
        ]


