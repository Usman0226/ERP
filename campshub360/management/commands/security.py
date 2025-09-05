"""
Django management command for security operations.
"""
from django.core.management.base import BaseCommand
from campshub360.security import generate_secret_key, validate_environment_security


class Command(BaseCommand):
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
