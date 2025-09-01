# Faculty Management App

## Overview

The Faculty Management app is a comprehensive Django application for managing faculty members, their subjects, schedules, leave requests, performance evaluations, and documents in the CampsHub360 system.

## Features

### Core Functionality
- **Faculty Profile Management**: Complete faculty member profiles with personal, academic, and professional information
- **Subject Assignment**: Track subjects taught by faculty members across different grade levels
- **Schedule Management**: Manage faculty timetables and class schedules
- **Leave Management**: Handle leave requests with approval workflow
- **Performance Evaluation**: Track and evaluate faculty performance
- **Document Management**: Store and verify faculty documents and certificates

### Key Models

1. **Faculty**: Main faculty member profile
2. **FacultySubject**: Subjects taught by faculty members
3. **FacultySchedule**: Faculty timetables and schedules
4. **FacultyLeave**: Leave requests and approvals
5. **FacultyPerformance**: Performance evaluations and assessments
6. **FacultyDocument**: Faculty documents and certificates

## Installation

1. The app is already included in the main project settings
2. Run migrations:
   ```bash
   python manage.py makemigrations faculty
   python manage.py migrate
   ```

## API Endpoints

### Base URL: `/api/v1/faculty/`

### Faculty Management
- `GET /api/faculty/` - List all faculty members
- `POST /api/faculty/` - Create new faculty member
- `GET /api/faculty/{id}/` - Get faculty details
- `PUT /api/faculty/{id}/` - Update faculty member
- `DELETE /api/faculty/{id}/` - Delete faculty member

### Special Endpoints
- `GET /api/faculty/statistics/` - Get faculty statistics
- `GET /api/faculty/active_faculty/` - Get active faculty members
- `GET /api/faculty/department_heads/` - Get department heads
- `GET /api/faculty/mentors/` - Get faculty mentors

### Faculty-Specific Data
- `GET /api/faculty/{id}/schedule/` - Get faculty schedule
- `GET /api/faculty/{id}/subjects/` - Get faculty subjects
- `GET /api/faculty/{id}/leaves/` - Get faculty leave history
- `GET /api/faculty/{id}/performance/` - Get faculty performance history

### Subject Management
- `GET /api/subjects/` - List all subjects
- `POST /api/subjects/` - Create new subject assignment
- `GET /api/subjects/by_subject/` - Get subjects by name
- `GET /api/subjects/by_grade/` - Get subjects by grade level

### Schedule Management
- `GET /api/schedules/` - List all schedules
- `POST /api/schedules/` - Create new schedule
- `GET /api/schedules/today_schedule/` - Get today's schedule
- `GET /api/schedules/faculty_schedule/` - Get specific faculty schedule
- `GET /api/schedules/room_schedule/` - Get room schedule

### Leave Management
- `GET /api/leaves/` - List all leave requests
- `POST /api/leaves/` - Create leave request
- `GET /api/leaves/pending_approvals/` - Get pending approvals
- `GET /api/leaves/approved_leaves/` - Get approved leaves
- `GET /api/leaves/current_leaves/` - Get current active leaves
- `POST /api/leaves/{id}/approve_leave/` - Approve leave request
- `POST /api/leaves/{id}/reject_leave/` - Reject leave request

### Performance Management
- `GET /api/performance/` - List all performance evaluations
- `POST /api/performance/` - Create performance evaluation
- `GET /api/performance/top_performers/` - Get top performers
- `GET /api/performance/performance_summary/` - Get performance summary
- `GET /api/performance/{id}/performance_history/` - Get performance history

### Document Management
- `GET /api/documents/` - List all documents
- `POST /api/documents/` - Upload new document
- `GET /api/documents/unverified_documents/` - Get unverified documents
- `POST /api/documents/{id}/verify_document/` - Verify document
- `GET /api/documents/by_type/` - Get documents by type

## Data Models

### Faculty Model
Comprehensive faculty profile with fields for:
- Personal information (name, DOB, gender, contact details)
- Employment details (designation, department, employment type)
- Academic credentials (qualifications, experience, achievements)
- Administrative roles (department head, mentor status)
- Emergency contact information

### FacultySubject Model
Tracks subjects taught by faculty members:
- Subject name and grade level
- Academic year
- Primary subject designation

### FacultySchedule Model
Manages faculty timetables:
- Day of week and time slots
- Subject and grade level
- Room assignment
- Online/offline status

### FacultyLeave Model
Handles leave requests:
- Leave type (sick, casual, annual, etc.)
- Date range and reason
- Approval workflow
- Status tracking

### FacultyPerformance Model
Tracks performance evaluations:
- Multiple evaluation criteria
- Automatic overall score calculation
- Strengths and improvement areas
- Recommendations

### FacultyDocument Model
Manages faculty documents:
- Document type classification
- File upload and storage
- Verification workflow
- Document metadata

## Admin Interface

The app provides a comprehensive Django admin interface with:
- Organized field sets for better data entry
- Filtering and search capabilities
- Bulk actions for leave approval and document verification
- Read-only computed fields
- Related data display

## Authentication & Permissions

- All API endpoints require JWT authentication
- Faculty members are automatically granted staff status
- Role-based permissions can be implemented based on designation
- Department-specific access controls available

## Testing

The app includes comprehensive test coverage:
- Model tests for all data models
- API tests for all endpoints
- Validation and business logic tests
- Integration tests for workflows

Run tests with:
```bash
python manage.py test faculty
```

## Usage Examples

### Creating a Faculty Member
```python
from faculty.models import Faculty
from django.contrib.auth import get_user_model

User = get_user_model()
user = User.objects.create_user(
    email='john.doe@example.com',
    username='EMP001',
    password='securepassword123'
)

faculty = Faculty.objects.create(
    user=user,
    employee_id='EMP001',
    first_name='John',
    last_name='Doe',
    designation='PROFESSOR',
    department='COMPUTER_SCIENCE',
    # ... other required fields
)
```

### Adding a Subject
```python
from faculty.models import FacultySubject

subject = FacultySubject.objects.create(
    faculty=faculty,
    subject_name='Python Programming',
    grade_level='Grade 10',
    academic_year='2023-2024',
    is_primary_subject=True
)
```

### Creating a Schedule
```python
from faculty.models import FacultySchedule
from datetime import time

schedule = FacultySchedule.objects.create(
    faculty=faculty,
    day_of_week='MONDAY',
    start_time=time(9, 0),
    end_time=time(10, 0),
    subject='Python Programming',
    grade_level='Grade 10',
    room_number='A101'
)
```

## Configuration

### Settings
The app is automatically configured when added to `INSTALLED_APPS`:
```python
INSTALLED_APPS = [
    # ... other apps
    'faculty',
]
```

### URLs
Include the faculty URLs in your main URL configuration:
```python
urlpatterns = [
    # ... other URLs
    path('api/v1/faculty/', include('faculty.urls', namespace='faculty')),
]
```

## File Structure

```
faculty/
├── __init__.py
├── admin.py          # Admin interface configuration
├── apps.py           # App configuration
├── models.py         # Data models
├── serializers.py    # API serializers
├── signals.py        # Django signals
├── tests.py          # Test cases
├── urls.py           # URL routing
├── views.py          # API views
├── migrations/       # Database migrations
├── API_DOCUMENTATION.md  # Detailed API documentation
└── README.md         # This file
```

## Contributing

1. Follow Django coding standards
2. Add tests for new features
3. Update documentation for API changes
4. Ensure all tests pass before submitting

## Support

For questions and support:
- Check the API documentation in `API_DOCUMENTATION.md`
- Review the test cases for usage examples
- Contact the development team for specific issues
