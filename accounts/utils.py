from django.utils import timezone
from .models import AuditLog, User
import uuid


def create_audit_log(user, action, object_type=None, object_id=None, ip=None, user_agent=None, meta=None):
    """
    Utility function to create audit logs manually
    
    Args:
        user: User instance or None
        action: String describing the action
        object_type: Type of object being acted upon
        object_id: ID of the object being acted upon
        ip: IP address of the user
        user_agent: User agent string
        meta: Additional metadata as dict
    """
    return AuditLog.objects.create(
        user=user,
        action=action,
        object_type=object_type or '',
        object_id=object_id,
        ip=ip,
        user_agent=user_agent or '',
        meta=meta or {}
    )


def create_sample_audit_logs():
    """Create sample audit logs for testing"""
    try:
        # Get the first user
        user = User.objects.first()
        if not user:
            print("No users found. Please create a user first.")
            return
        
        # Create sample audit logs
        sample_logs = [
            {
                'action': 'LOGIN',
                'object_type': 'User',
                'object_id': user.id,
                'ip': '127.0.0.1',
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'meta': {'login_method': 'password', 'success': True}
            },
            {
                'action': 'USER_UPDATED',
                'object_type': 'User',
                'object_id': user.id,
                'ip': '127.0.0.1',
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'meta': {'fields_changed': ['last_login'], 'old_values': {}, 'new_values': {'last_login': timezone.now().isoformat()}}
            },
            {
                'action': 'STUDENT_CREATED',
                'object_type': 'Student',
                'object_id': str(uuid.uuid4()),
                'ip': '127.0.0.1',
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'meta': {'student_name': 'John Doe', 'roll_number': 'STU001', 'grade_level': 'GRADE_10'}
            },
            {
                'action': 'FACULTY_UPDATED',
                'object_type': 'Faculty',
                'object_id': str(uuid.uuid4()),
                'ip': '127.0.0.1',
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'meta': {'faculty_name': 'Dr. Jane Smith', 'department': 'Computer Science', 'fields_changed': ['phone']}
            },
            {
                'action': 'EXAM_SCHEDULED',
                'object_type': 'ExamSchedule',
                'object_id': str(uuid.uuid4()),
                'ip': '127.0.0.1',
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'meta': {'exam_name': 'Midterm Exam', 'subject': 'Mathematics', 'date': '2024-01-15', 'duration': '2 hours'}
            },
            {
                'action': 'FEE_PAYMENT',
                'object_type': 'Payment',
                'object_id': str(uuid.uuid4()),
                'ip': '127.0.0.1',
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'meta': {'amount': 5000, 'currency': 'INR', 'payment_method': 'online', 'student_id': 'STU001'}
            },
            {
                'action': 'ATTENDANCE_MARKED',
                'object_type': 'AttendanceRecord',
                'object_id': str(uuid.uuid4()),
                'ip': '127.0.0.1',
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'meta': {'student_id': 'STU001', 'subject': 'Mathematics', 'status': 'present', 'date': '2024-01-10'}
            },
            {
                'action': 'SYSTEM_BACKUP',
                'object_type': 'System',
                'object_id': None,
                'ip': '127.0.0.1',
                'user_agent': 'System/Backup',
                'meta': {'backup_type': 'full', 'size': '2.5GB', 'duration': '15 minutes', 'status': 'success'}
            },
            {
                'action': 'LOGIN_FAILED',
                'object_type': '',
                'object_id': None,
                'ip': '192.168.1.100',
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'meta': {'identifier': 'invalid@email.com', 'reason': 'Invalid credentials', 'attempt_count': 3}
            },
            {
                'action': 'LOGOUT',
                'object_type': 'User',
                'object_id': user.id,
                'ip': '127.0.0.1',
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'meta': {'session_duration': '2 hours 30 minutes'}
            }
        ]
        
        # Create the audit logs
        created_logs = []
        for log_data in sample_logs:
            log = create_audit_log(
                user=user if log_data['action'] in ['LOGIN', 'USER_UPDATED', 'LOGOUT'] else None,
                action=log_data['action'],
                object_type=log_data['object_type'],
                object_id=log_data['object_id'],
                ip=log_data['ip'],
                user_agent=log_data['user_agent'],
                meta=log_data['meta']
            )
            created_logs.append(log)
        
        print(f"Created {len(created_logs)} sample audit logs")
        return created_logs
        
    except Exception as e:
        print(f"Error creating sample audit logs: {e}")
        return []
