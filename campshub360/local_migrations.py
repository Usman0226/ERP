"""
Local development migration overrides
Disables PostgreSQL-specific migrations for SQLite compatibility
"""
from django.db import migrations

# Empty migration to replace PostgreSQL-specific ones
class EmptyMigration(migrations.Migration):
    dependencies = []
    operations = []

# SQLite-compatible index migration
class SQLiteIndexMigration(migrations.Migration):
    dependencies = [
        ('students', '0005_student_indexes'),
    ]
    
    operations = [
        migrations.RunSQL(
            sql="""
            -- SQLite-compatible indexes for students table
            CREATE INDEX IF NOT EXISTS idx_students_roll_number 
            ON students_student (roll_number);
            
            CREATE INDEX IF NOT EXISTS idx_students_email 
            ON students_student (email) WHERE email IS NOT NULL;
            
            CREATE INDEX IF NOT EXISTS idx_students_academic_year_grade_section_status 
            ON students_student (academic_year, grade_level, section, status);
            
            CREATE INDEX IF NOT EXISTS idx_students_created_at_desc 
            ON students_student (created_at DESC);
            
            CREATE INDEX IF NOT EXISTS idx_students_status_active 
            ON students_student (status) WHERE status = 'ACTIVE';
            """,
            reverse_sql="""
            DROP INDEX IF EXISTS idx_students_roll_number;
            DROP INDEX IF EXISTS idx_students_email;
            DROP INDEX IF EXISTS idx_students_academic_year_grade_section_status;
            DROP INDEX IF EXISTS idx_students_created_at_desc;
            DROP INDEX IF EXISTS idx_students_status_active;
            """
        ),
    ]
