from django.db import migrations, models
import django.utils.timezone


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name='Outbox',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('topic', models.CharField(max_length=100)),
                ('key', models.CharField(blank=True, max_length=100)),
                ('payload', models.JSONField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('available_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('delivered_at', models.DateTimeField(blank=True, null=True)),
                ('attempts', models.IntegerField(default=0)),
                ('last_error', models.TextField(blank=True)),
            ],
        ),
        migrations.AddIndex(
            model_name='outbox',
            index=models.Index(fields=['topic', 'available_at', 'delivered_at'], name='outbox_topic_avail_deliv_idx'),
        ),
    ]


