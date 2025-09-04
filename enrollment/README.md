# Enrollment Management System

## Overview

The Enrollment Management System is a comprehensive solution for managing course enrollments based on departments, academic programs, faculty assignments, and course sections. It provides a structured approach to handle complex enrollment scenarios in educational institutions.

## Key Features

### 1. **Department-Based Course Management**
- Courses are organized by departments
- Faculty assignments are restricted to their respective departments
- Course sections are created based on department requirements

### 2. **Academic Program Integration**
- Courses are assigned to specific academic programs (UG, PG, PhD, etc.)
- Year-based course progression
- Mandatory vs. Elective course categorization

### 3. **Faculty Assignment System**
- Automatic faculty assignment to course sections
- Conflict detection for faculty schedules
- Workload management and tracking

### 4. **Course Section Management**
- Multiple sections for the same course
- Section capacity management
- Section-specific faculty assignments

### 5. **Student Enrollment Planning**
- Department-based enrollment plans
- Automatic course recommendations
- Priority-based course selection

### 6. **Waitlist Management**
- Automatic waitlist when courses are full
- Priority-based waitlist processing
- Seamless transition from waitlist to enrollment

## System Architecture

### Core Models

#### 1. **Department**
```python
class Department(models.Model):
    name = models.CharField(max_length=100)
    code = models.CharField(max_length=10)  # e.g., CS, ME, EE
    head_of_department = models.ForeignKey(Faculty)
    is_active = models.BooleanField(default=True)
```

#### 2. **AcademicProgram**
```python
class AcademicProgram(models.Model):
    name = models.CharField(max_length=200)  # e.g., "Bachelor of Computer Science"
    code = models.CharField(max_length=20)   # e.g., "BCS"
    level = models.CharField(choices=PROGRAM_LEVELS)  # UG, PG, PhD
    department = models.ForeignKey(Department)
    duration_years = models.PositiveIntegerField()
    total_credits = models.PositiveIntegerField()
```

#### 3. **Course**
```python
class Course(models.Model):
    code = models.CharField(max_length=20)  # e.g., "CS101"
    title = models.CharField(max_length=200)
    department = models.ForeignKey(Department)
    programs = models.ManyToManyField(AcademicProgram)
    level = models.CharField(choices=COURSE_LEVELS)
    credits = models.PositiveIntegerField()
    max_students = models.PositiveIntegerField()  # per section
```

#### 4. **CourseSection**
```python
class CourseSection(models.Model):
    course = models.ForeignKey(Course)
    section_number = models.CharField(max_length=10)  # e.g., "A", "B", "01"
    section_type = models.CharField(choices=SECTION_TYPES)  # LECTURE, LAB, TUTORIAL
    academic_year = models.CharField(max_length=9)
    semester = models.CharField(max_length=20)
    faculty = models.ForeignKey(Faculty)
    max_students = models.PositiveIntegerField()
    current_enrollment = models.PositiveIntegerField(default=0)
```

#### 5. **CourseAssignment**
```python
class CourseAssignment(models.Model):
    course = models.ForeignKey(Course)
    department = models.ForeignKey(Department)
    academic_program = models.ForeignKey(AcademicProgram)
    academic_year = models.CharField(max_length=9)
    semester = models.CharField(max_length=20)
    assignment_type = models.CharField(choices=ASSIGNMENT_TYPES)  # MANDATORY, ELECTIVE, OPTIONAL
    year_of_study = models.PositiveIntegerField()  # Which year in program
```

#### 6. **FacultyAssignment**
```python
class FacultyAssignment(models.Model):
    faculty = models.ForeignKey(Faculty)
    course_section = models.ForeignKey(CourseSection)
    status = models.CharField(choices=ASSIGNMENT_STATUS)  # ASSIGNED, CONFIRMED, REJECTED
    workload_hours = models.PositiveIntegerField()
    is_primary = models.BooleanField()  # Primary vs. secondary faculty
```

#### 7. **StudentEnrollmentPlan**
```python
class StudentEnrollmentPlan(models.Model):
    student = models.ForeignKey(Student)
    academic_program = models.ForeignKey(AcademicProgram)
    academic_year = models.CharField(max_length=9)
    semester = models.CharField(max_length=20)
    year_of_study = models.PositiveIntegerField()
    status = models.CharField(choices=PLAN_STATUS)  # DRAFT, APPROVED, ACTIVE
    advisor = models.ForeignKey(Faculty)
```

#### 8. **EnrollmentRequest**
```python
class EnrollmentRequest(models.Model):
    student = models.ForeignKey(Student)
    course_section = models.ForeignKey(CourseSection)
    enrollment_plan = models.ForeignKey(StudentEnrollmentPlan)
    status = models.CharField(choices=REQUEST_STATUS)  # PENDING, APPROVED, REJECTED
    requested_by = models.ForeignKey(User)
    approved_by = models.ForeignKey(User)
```

#### 9. **WaitlistEntry**
```python
class WaitlistEntry(models.Model):
    student = models.ForeignKey(Student)
    course_section = models.ForeignKey(CourseSection)
    enrollment_request = models.ForeignKey(EnrollmentRequest)
    position = models.PositiveIntegerField()  # Position in waitlist
    is_active = models.BooleanField(default=True)
```

## How It Works

### 1. **Course Setup Process**

1. **Create Department**
   ```python
   cs_dept = Department.objects.create(
       name="Computer Science",
       code="CS",
       head_of_department=faculty_member
   )
   ```

2. **Create Academic Program**
   ```python
   bcs_program = AcademicProgram.objects.create(
       name="Bachelor of Computer Science",
       code="BCS",
       level="UG",
       department=cs_dept,
       duration_years=4,
       total_credits=120
   )
   ```

3. **Create Course**
   ```python
   cs101 = Course.objects.create(
       code="CS101",
       title="Introduction to Computer Science",
       department=cs_dept,
       level="UG",
       credits=3,
       max_students=50
   )
   cs101.programs.add(bcs_program)
   ```

4. **Assign Course to Department/Program**
   ```python
   CourseAssignment.objects.create(
       course=cs101,
       department=cs_dept,
       academic_program=bcs_program,
       academic_year="2024-2025",
       semester="FALL",
       assignment_type="MANDATORY",
       year_of_study=1
   )
   ```

### 2. **Faculty Assignment Process**

1. **Create Course Section**
   ```python
   section_a = CourseSection.objects.create(
       course=cs101,
       section_number="A",
       academic_year="2024-2025",
       semester="FALL",
       faculty=professor_smith,
       max_students=50
   )
   ```

2. **Assign Faculty (Automatic)**
   ```python
   # The system automatically creates FacultyAssignment
   # and validates no schedule conflicts
   ```

### 3. **Student Enrollment Process**

1. **Create Enrollment Plan**
   ```python
   # System automatically creates plan based on student's department/program
   plan = EnrollmentService.create_department_based_enrollment_plan(
       student=john_doe,
       academic_year="2024-2025",
       semester="FALL"
   )
   ```

2. **Enroll in Course Section**
   ```python
   enrollment = EnrollmentService.enroll_student_in_course(
       student=john_doe,
       course_section=section_a
   )
   ```

3. **Handle Waitlist (if full)**
   ```python
   # If section is full, student is automatically added to waitlist
   # When space becomes available, first person on waitlist is enrolled
   ```

## Usage Examples

### 1. **Get Available Courses for Student**
```python
available_courses = EnrollmentService.get_available_courses_for_student(
    student=john_doe,
    academic_year="2024-2025",
    semester="FALL"
)
```

### 2. **Create Department Course Sections**
```python
created_sections = DepartmentEnrollmentService.create_department_course_sections(
    department=cs_dept,
    academic_year="2024-2025",
    semester="FALL"
)
```

### 3. **Assign Faculty to Department Courses**
```python
assigned_count = DepartmentEnrollmentService.assign_faculty_to_department_courses(
    department=cs_dept,
    academic_year="2024-2025",
    semester="FALL"
)
```

### 4. **Get Student Enrollment Summary**
```python
summary = EnrollmentService.get_student_enrollment_summary(
    student=john_doe,
    academic_year="2024-2025",
    semester="FALL"
)
```

## Benefits

### 1. **Structured Organization**
- Clear hierarchy: Department → Program → Course → Section
- Logical faculty assignments within departments
- Systematic course progression

### 2. **Automated Processes**
- Automatic enrollment plan creation
- Automatic faculty assignment
- Automatic waitlist management

### 3. **Conflict Prevention**
- Faculty schedule conflict detection
- Department-based access control
- Capacity management

### 4. **Flexibility**
- Support for multiple sections
- Elective vs. mandatory course handling
- Waitlist and approval workflows

### 5. **Scalability**
- Handles large numbers of students
- Efficient database queries
- Transaction-based operations

## Configuration

### 1. **Add to INSTALLED_APPS**
```python
INSTALLED_APPS = [
    # ... other apps
    'enrollment',
]
```

### 2. **Run Migrations**
```bash
python manage.py makemigrations enrollment
python manage.py migrate
```

### 3. **Register in Admin**
The models are automatically registered in the Django admin interface with proper list displays, filters, and actions.

## Future Enhancements

1. **Advanced Scheduling**
   - Room assignment optimization
   - Faculty workload balancing
   - Schedule conflict resolution

2. **Analytics Dashboard**
   - Enrollment trends
   - Course popularity metrics
   - Faculty workload analysis

3. **Integration Features**
   - Student information system integration
   - Learning management system integration
   - Financial system integration

4. **Mobile Support**
   - Student enrollment app
   - Faculty assignment app
   - Admin management app

## Support

For questions or issues with the enrollment system, please refer to the admin interface or contact the development team.
