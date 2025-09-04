"""
Database router for read/write splitting
Routes read operations to read replica, writes to primary
"""
from django.conf import settings


class DatabaseRouter:
    """
    A router to control all database operations on models in the
    application and route them to appropriate databases.
    """
    
    read_operations = {
        'get', 'filter', 'exclude', 'order_by', 'distinct', 
        'values', 'values_list', 'count', 'exists', 'aggregate',
        'annotate', 'select_related', 'prefetch_related'
    }
    
    write_operations = {
        'create', 'update', 'delete', 'bulk_create', 'bulk_update',
        'bulk_delete', 'save', 'delete'
    }

    def db_for_read(self, model, **hints):
        """Point all read operations to the read replica."""
        if 'read_replica' in settings.DATABASES:
            return 'read_replica'
        return 'default'

    def db_for_write(self, model, **hints):
        """Point all write operations to the primary database."""
        return 'default'

    def allow_relation(self, obj1, obj2, **hints):
        """Allow relations if both objects are in the same database."""
        db_set = {'default', 'read_replica'}
        if obj1._state.db in db_set and obj2._state.db in db_set:
            return True
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """Ensure migrations only run on the primary database."""
        return db == 'default'
