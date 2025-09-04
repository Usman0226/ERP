# Academics App

The Academics app is a comprehensive Django application for managing academic operations including courses, syllabuses, timetables, student enrollments, and academic calendars.

## Features

### 1. Course Management
- **Course Creation**: Create and manage academic courses with detailed information
- **Course Levels**: Support for Undergraduate, Postgraduate, Doctorate, Diploma, and Certificate levels
- **Prerequisites**: Define course prerequisites and dependencies
- **Faculty Assignment**: Assign multiple faculty members to courses
- **Status Management**: Track course status (Active, Inactive, Draft, Archived)

### 2. Syllabus Management
- **Syllabus Creation**: Create detailed course syllabuses with learning objectives
- **Topic Management**: Organize course content by weeks with specific topics
- **Version Control**: Track syllabus versions and updates
- **Approval Workflow**: Implement syllabus approval process
- **Learning Resources**: Manage textbooks, readings, and additional resources

### 3. Timetable Management
- **Class Scheduling**: Create and manage class schedules
- **Conflict Detection**: Automatically detect timetable conflicts
- **Room Management**: Assign classrooms and venues
- **Schedule Types**: Support for regular classes, exams, make-up classes, and special events
- **Weekly Views**: Generate weekly schedules for faculty and courses

### 4. Student Enrollment
- **Course Registration**: Manage student course enrollments
- **Grade Tracking**: Record and track student grades and performance
- **Attendance Monitoring**: Track student attendance percentages
- **Enrollment Status**: Monitor enrollment status (Enrolled, Dropped, Completed, Withdrawn)

### 5. Academic Calendar
- **Event Management**: Schedule academic events, holidays, and deadlines
- **Date Range Support**: Handle multi-day events and recurring schedules
- **Academic Day Tracking**: Distinguish between academic and non-academic days
- **Calendar Views**: Monthly and upcoming event views

## Models

### Course
- Course code, title, description
- Level, credits, duration
- Maximum students, prerequisites
- Faculty assignments, status

### Syllabus
- Course reference, version, academic year
- Learning objectives, course outline
- Assessment methods, grading policy
- Textbooks, additional resources
- Approval status and workflow

### SyllabusTopic
- Week-based topic organization
- Learning outcomes, readings, activities
- Duration and ordering within weeks

### Timetable
- Course scheduling with time slots
- Room assignments, faculty assignments
- Day of week, start/end times
- Conflict detection capabilities

### CourseEnrollment
- Student-course relationships
- Academic year and semester tracking
- Grades, attendance, status

### AcademicCalendar
- Event scheduling and management
- Date ranges and academic day flags
- Event categorization and descriptions

## API Endpoints

### Courses
- `GET /api/v1/academics/api/courses/` - List all courses
- `POST /api/v1/academics/api/courses/` - Create new course
- `GET /api/v1/academics/api/courses/{id}/` - Get course details
- `PUT /api/v1/academics/api/courses/{id}/` - Update course
- `DELETE /api/v1/academics/api/courses/{id}/` - Delete course
- `GET /api/v1/academics/api/courses/{id}/detail/` - Get detailed course info
- `GET /api/v1/academics/api/courses/by_faculty/` - Get courses by faculty
- `GET /api/v1/academics/api/courses/by_level/` - Get courses by level
- `GET /api/v1/academics/api/courses/statistics/` - Get course statistics

### Syllabi
- `GET /api/v1/academics/api/syllabi/` - List all syllabi
- `POST /api/v1/academics/api/syllabi/` - Create new syllabus
- `GET /api/v1/academics/api/syllabi/{id}/` - Get syllabus details
- `PUT /api/v1/academics/api/syllabi/{id}/` - Update syllabus
- `DELETE /api/v1/academics/api/syllabi/{id}/` - Delete syllabus
- `GET /api/v1/academics/api/syllabi/{id}/detail/` - Get detailed syllabus
- `POST /api/v1/academics/api/syllabi/{id}/approve/` - Approve syllabus
- `GET /api/v1/academics/api/syllabi/by_academic_year/` - Get syllabi by year

### Timetables
- `GET /api/v1/academics/api/timetables/` - List all timetables
- `POST /api/v1/academics/api/timetables/` - Create new timetable
- `GET /api/v1/academics/api/timetables/{id}/` - Get timetable details
- `PUT /api/v1/academics/api/timetables/{id}/` - Update timetable
- `DELETE /api/v1/academics/api/timetables/{id}/` - Delete timetable
- `GET /api/v1/academics/api/timetables/weekly_schedule/` - Get weekly schedule
- `GET /api/v1/academics/api/timetables/conflicts/` - Check for conflicts

### Enrollments
- `GET /api/v1/academics/api/enrollments/` - List all enrollments
- `POST /api/v1/academics/api/enrollments/` - Create new enrollment
- `GET /api/v1/academics/api/enrollments/{id}/` - Get enrollment details
- `PUT /api/v1/academics/api/enrollments/{id}/` - Update enrollment
- `DELETE /api/v1/academics/api/enrollments/{id}/` - Delete enrollment
- `GET /api/v1/academics/api/enrollments/by_student/` - Get enrollments by student
- `GET /api/v1/academics/api/enrollments/by_course/` - Get enrollments by course
- `GET /api/v1/academics/api/enrollments/statistics/` - Get enrollment statistics

### Academic Calendar
- `GET /api/v1/academics/api/academic-calendar/` - List all events
- `POST /api/v1/academics/api/academic-calendar/` - Create new event
- `GET /api/v1/academics/api/academic-calendar/{id}/` - Get event details
- `PUT /api/v1/academics/api/academic-calendar/{id}/` - Update event
- `DELETE /api/v1/academics/api/academic-calendar/{id}/` - Delete event
- `GET /api/v1/academics/api/academic-calendar/upcoming_events/` - Get upcoming events
- `GET /api/v1/academics/api/academic-calendar/by_month/` - Get events by month
- `GET /api/v1/academics/api/academic-calendar/academic_days/` - Get academic days

## Usage Examples

### Creating a Course
```python
from academics.models import Course
from faculty.models import Faculty

# Create faculty
faculty = Faculty.objects.create(
    first_name="John",
    last_name="Doe",
    email="john.doe@example.com"
)

# Create course
course = Course.objects.create(
    code="CS101",
    title="Introduction to Computer Science",
    description="Basic computer science concepts",
    level="UG",
    credits=3,
    max_students=50
)
course.faculty.add(faculty)
```

### Creating a Syllabus
```python
from academics.models import Syllabus, SyllabusTopic

# Create syllabus
syllabus = Syllabus.objects.create(
    course=course,
    version="1.0",
    academic_year="2024-2025",
    semester="Fall",
    learning_objectives="Learn basic programming concepts",
    course_outline="Week 1: Introduction, Week 2: Variables",
    assessment_methods="Quizzes, Assignments, Final Exam",
    grading_policy="A: 90-100, B: 80-89, C: 70-79",
    textbooks="Introduction to CS by Smith"
)

# Add topics
topic = SyllabusTopic.objects.create(
    syllabus=syllabus,
    week_number=1,
    title="Introduction to Programming",
    description="Basic programming concepts",
    learning_outcomes="Understand basic programming",
    duration_hours=3
)
```

### Creating a Timetable
```python
from academics.models import Timetable
from datetime import time

# Create timetable entry
timetable = Timetable.objects.create(
    course=course,
    timetable_type="REGULAR",
    academic_year="2024-2025",
    semester="Fall",
    day_of_week="MON",
    start_time=time(9, 0),
    end_time=time(10, 30),
    room="Room 101",
    faculty=faculty
)
```

## Admin Interface

The app provides a comprehensive Django admin interface for:
- Course management with filtering and search
- Syllabus creation and approval workflow
- Timetable scheduling and conflict detection
- Student enrollment tracking
- Academic calendar management

## Testing

Run the test suite:
```bash
python manage.py test academics
```

## Dependencies

- Django 4.2+
- Django REST Framework
- Django Filters
- Custom User model (accounts.User)

## Installation

1. Add 'academics' to INSTALLED_APPS in settings.py
2. Run migrations: `python manage.py migrate`
3. Include URLs in main urls.py
4. Access admin interface at `/admin/`

## Contributing

1. Follow Django coding standards
2. Add tests for new features
3. Update documentation
4. Ensure all tests pass

## License

This app is part of the CampsHub360 project.
