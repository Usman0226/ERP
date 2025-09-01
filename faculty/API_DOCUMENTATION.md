# Faculty Management API Documentation

## Overview

The Faculty Management API provides comprehensive endpoints for managing faculty members, their subjects, schedules, leave requests, performance evaluations, and documents in the CampsHub360 system.

## Base URL

```
/api/v1/faculty/
```

## Authentication

All endpoints require authentication using JWT tokens. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## Endpoints

### Faculty Management

#### 1. List All Faculty Members
- **URL**: `/api/faculty/`
- **Method**: `GET`
- **Description**: Retrieve a list of all faculty members
- **Query Parameters**:
  - `status`: Filter by status (ACTIVE, INACTIVE, ON_LEAVE, RETIRED, TERMINATED)
  - `designation`: Filter by designation (PROFESSOR, ASSOCIATE_PROFESSOR, etc.)
  - `department`: Filter by department (COMPUTER_SCIENCE, MATHEMATICS, etc.)
  - `employment_type`: Filter by employment type (FULL_TIME, PART_TIME, etc.)
  - `search`: Search in first_name, last_name, employee_id, email, phone_number, specialization
  - `ordering`: Order by fields (first_name, last_name, date_of_joining, etc.)

**Response**:
```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "uuid",
      "user": {
        "id": "uuid",
        "username": "EMP001",
        "email": "john.doe@example.com",
        "first_name": "John",
        "last_name": "Doe"
      },
      "employee_id": "EMP001",
      "full_name": "John Doe",
      "designation": "PROFESSOR",
      "department": "COMPUTER_SCIENCE",
      "employment_type": "FULL_TIME",
      "status": "ACTIVE",
      "email": "john.doe@example.com",
      "phone_number": "+1234567890",
      "date_of_joining": "2020-01-01",
      "is_active_faculty": true,
      "created_at": "2023-01-01T00:00:00Z"
    }
  ]
}
```

#### 2. Create Faculty Member
- **URL**: `/api/faculty/`
- **Method**: `POST`
- **Description**: Create a new faculty member with associated user account

**Request Body**:
```json
{
  "user_id": "uuid",
  "email": "john.doe@example.com",
  "password": "securepassword123",
  "employee_id": "EMP001",
  "first_name": "John",
  "last_name": "Doe",
  "middle_name": "Michael",
  "date_of_birth": "1980-01-01",
  "gender": "M",
  "designation": "PROFESSOR",
  "department": "COMPUTER_SCIENCE",
  "employment_type": "FULL_TIME",
  "date_of_joining": "2020-01-01",
  "phone_number": "+1234567890",
  "alternate_phone": "+1234567891",
  "address_line_1": "123 Main Street",
  "address_line_2": "Apt 4B",
  "city": "New York",
  "state": "NY",
  "postal_code": "10001",
  "country": "USA",
  "highest_qualification": "PhD",
  "specialization": "Computer Science",
  "university": "MIT",
  "year_of_completion": 2010,
  "experience_years": 10.0,
  "previous_institution": "Stanford University",
  "achievements": "Published 20+ papers",
  "research_interests": "Machine Learning, AI",
  "is_head_of_department": false,
  "is_mentor": true,
  "mentor_for_grades": "Grade 10, Grade 11",
  "emergency_contact_name": "Jane Doe",
  "emergency_contact_phone": "+1234567892",
  "emergency_contact_relationship": "Spouse",
  "bio": "Experienced professor with expertise in computer science",
  "notes": "Additional notes"
}
```

#### 3. Get Faculty Details
- **URL**: `/api/faculty/{id}/`
- **Method**: `GET`
- **Description**: Retrieve detailed information about a specific faculty member

**Response**:
```json
{
  "id": "uuid",
  "user": {
    "id": "uuid",
    "username": "EMP001",
    "email": "john.doe@example.com",
    "first_name": "John",
    "last_name": "Doe"
  },
  "employee_id": "EMP001",
  "first_name": "John",
  "last_name": "Doe",
  "middle_name": "Michael",
  "date_of_birth": "1980-01-01",
  "gender": "M",
  "designation": "PROFESSOR",
  "department": "COMPUTER_SCIENCE",
  "employment_type": "FULL_TIME",
  "status": "ACTIVE",
  "date_of_joining": "2020-01-01",
  "date_of_leaving": null,
  "email": "john.doe@example.com",
  "phone_number": "+1234567890",
  "alternate_phone": "+1234567891",
  "address_line_1": "123 Main Street",
  "address_line_2": "Apt 4B",
  "city": "New York",
  "state": "NY",
  "postal_code": "10001",
  "country": "USA",
  "highest_qualification": "PhD",
  "specialization": "Computer Science",
  "university": "MIT",
  "year_of_completion": 2010,
  "experience_years": 10.0,
  "previous_institution": "Stanford University",
  "achievements": "Published 20+ papers",
  "research_interests": "Machine Learning, AI",
  "is_head_of_department": false,
  "is_mentor": true,
  "mentor_for_grades": "Grade 10, Grade 11",
  "emergency_contact_name": "Jane Doe",
  "emergency_contact_phone": "+1234567892",
  "emergency_contact_relationship": "Spouse",
  "profile_picture": null,
  "bio": "Experienced professor with expertise in computer science",
  "notes": "Additional notes",
  "full_name": "John Michael Doe",
  "is_active_faculty": true,
  "created_at": "2023-01-01T00:00:00Z",
  "updated_at": "2023-01-01T00:00:00Z",
  "subjects": [],
  "schedules": [],
  "leaves": [],
  "performances": [],
  "documents": []
}
```

#### 4. Update Faculty Member
- **URL**: `/api/faculty/{id}/`
- **Method**: `PUT` / `PATCH`
- **Description**: Update faculty member information

#### 5. Delete Faculty Member
- **URL**: `/api/faculty/{id}/`
- **Method**: `DELETE`
- **Description**: Delete a faculty member

### Faculty Statistics

#### 6. Get Faculty Statistics
- **URL**: `/api/faculty/statistics/`
- **Method**: `GET`
- **Description**: Get comprehensive faculty statistics

**Response**:
```json
{
  "total_faculty": 50,
  "active_faculty": 45,
  "department_statistics": [
    {
      "department": "COMPUTER_SCIENCE",
      "count": 15
    },
    {
      "department": "MATHEMATICS",
      "count": 10
    }
  ],
  "designation_statistics": [
    {
      "designation": "PROFESSOR",
      "count": 20
    },
    {
      "designation": "ASSOCIATE_PROFESSOR",
      "count": 15
    }
  ],
  "employment_statistics": [
    {
      "employment_type": "FULL_TIME",
      "count": 40
    },
    {
      "employment_type": "PART_TIME",
      "count": 10
    }
  ]
}
```

### Faculty Categories

#### 7. Get Active Faculty
- **URL**: `/api/faculty/active_faculty/`
- **Method**: `GET`
- **Description**: Get all active faculty members

#### 8. Get Department Heads
- **URL**: `/api/faculty/department_heads/`
- **Method**: `GET`
- **Description**: Get all department heads

#### 9. Get Mentors
- **URL**: `/api/faculty/mentors/`
- **Method**: `GET`
- **Description**: Get all faculty mentors

### Faculty-Specific Data

#### 10. Get Faculty Schedule
- **URL**: `/api/faculty/{id}/schedule/`
- **Method**: `GET`
- **Description**: Get schedule for a specific faculty member

#### 11. Get Faculty Subjects
- **URL**: `/api/faculty/{id}/subjects/`
- **Method**: `GET`
- **Description**: Get subjects taught by a specific faculty member

#### 12. Get Faculty Leave History
- **URL**: `/api/faculty/{id}/leaves/`
- **Method**: `GET`
- **Description**: Get leave history for a specific faculty member

#### 13. Get Faculty Performance History
- **URL**: `/api/faculty/{id}/performance/`
- **Method**: `GET`
- **Description**: Get performance history for a specific faculty member

## Faculty Subjects Management

### List Subjects
- **URL**: `/api/subjects/`
- **Method**: `GET`
- **Query Parameters**:
  - `faculty`: Filter by faculty ID
  - `grade_level`: Filter by grade level
  - `academic_year`: Filter by academic year
  - `is_primary_subject`: Filter by primary subject status

### Create Subject
- **URL**: `/api/subjects/`
- **Method**: `POST`

### Get Subjects by Subject Name
- **URL**: `/api/subjects/by_subject/`
- **Method**: `GET`
- **Query Parameters**: `subject_name`

### Get Subjects by Grade Level
- **URL**: `/api/subjects/by_grade/`
- **Method**: `GET`
- **Query Parameters**: `grade_level`

## Faculty Schedule Management

### List Schedules
- **URL**: `/api/schedules/`
- **Method**: `GET`
- **Query Parameters**:
  - `faculty`: Filter by faculty ID
  - `day_of_week`: Filter by day of week
  - `grade_level`: Filter by grade level
  - `is_online`: Filter by online status

### Create Schedule
- **URL**: `/api/schedules/`
- **Method**: `POST`

### Get Today's Schedule
- **URL**: `/api/schedules/today_schedule/`
- **Method**: `GET`

### Get Faculty Schedule
- **URL**: `/api/schedules/faculty_schedule/`
- **Method**: `GET`
- **Query Parameters**: `faculty_id`

### Get Room Schedule
- **URL**: `/api/schedules/room_schedule/`
- **Method**: `GET`
- **Query Parameters**: `room_number`

## Faculty Leave Management

### List Leaves
- **URL**: `/api/leaves/`
- **Method**: `GET`
- **Query Parameters**:
  - `faculty`: Filter by faculty ID
  - `leave_type`: Filter by leave type
  - `status`: Filter by status
  - `approved_by`: Filter by approver

### Create Leave Request
- **URL**: `/api/leaves/`
- **Method**: `POST`

### Get Pending Approvals
- **URL**: `/api/leaves/pending_approvals/`
- **Method**: `GET`

### Get Approved Leaves
- **URL**: `/api/leaves/approved_leaves/`
- **Method**: `GET`

### Get Current Leaves
- **URL**: `/api/leaves/current_leaves/`
- **Method**: `GET`

### Approve Leave
- **URL**: `/api/leaves/{id}/approve_leave/`
- **Method**: `POST`

### Reject Leave
- **URL**: `/api/leaves/{id}/reject_leave/`
- **Method**: `POST`
- **Request Body**:
```json
{
  "rejection_reason": "Insufficient notice period"
}
```

## Faculty Performance Management

### List Performance Evaluations
- **URL**: `/api/performance/`
- **Method**: `GET`
- **Query Parameters**:
  - `faculty`: Filter by faculty ID
  - `academic_year`: Filter by academic year
  - `evaluation_period`: Filter by evaluation period
  - `evaluated_by`: Filter by evaluator

### Create Performance Evaluation
- **URL**: `/api/performance/`
- **Method**: `POST`

### Get Top Performers
- **URL**: `/api/performance/top_performers/`
- **Method**: `GET`

### Get Performance Summary
- **URL**: `/api/performance/performance_summary/`
- **Method**: `GET`
- **Query Parameters**: `academic_year`

### Get Performance History
- **URL**: `/api/performance/{id}/performance_history/`
- **Method**: `GET`

## Faculty Document Management

### List Documents
- **URL**: `/api/documents/`
- **Method**: `GET`
- **Query Parameters**:
  - `faculty`: Filter by faculty ID
  - `document_type`: Filter by document type
  - `is_verified`: Filter by verification status
  - `verified_by`: Filter by verifier

### Create Document
- **URL**: `/api/documents/`
- **Method**: `POST`

### Get Unverified Documents
- **URL**: `/api/documents/unverified_documents/`
- **Method**: `GET`

### Verify Document
- **URL**: `/api/documents/{id}/verify_document/`
- **Method**: `POST`

### Get Documents by Type
- **URL**: `/api/documents/by_type/`
- **Method**: `GET`
- **Query Parameters**: `document_type`

## Data Models

### Faculty Model Fields

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| user | OneToOneField | Associated user account |
| employee_id | CharField | Unique employee identifier |
| first_name | CharField | First name |
| last_name | CharField | Last name |
| middle_name | CharField | Middle name (optional) |
| date_of_birth | DateField | Date of birth |
| gender | CharField | Gender (M/F/O) |
| designation | CharField | Academic designation |
| department | CharField | Department |
| employment_type | CharField | Employment type |
| status | CharField | Current status |
| date_of_joining | DateField | Date of joining |
| date_of_leaving | DateField | Date of leaving (optional) |
| email | EmailField | Email address |
| phone_number | CharField | Primary phone number |
| alternate_phone | CharField | Alternate phone number |
| address_line_1 | CharField | Address line 1 |
| address_line_2 | CharField | Address line 2 (optional) |
| city | CharField | City |
| state | CharField | State |
| postal_code | CharField | Postal code |
| country | CharField | Country |
| highest_qualification | CharField | Highest qualification |
| specialization | CharField | Specialization (optional) |
| university | CharField | University (optional) |
| year_of_completion | IntegerField | Year of completion (optional) |
| experience_years | DecimalField | Years of experience |
| previous_institution | CharField | Previous institution (optional) |
| achievements | TextField | Achievements (optional) |
| research_interests | TextField | Research interests (optional) |
| is_head_of_department | BooleanField | Department head status |
| is_mentor | BooleanField | Mentor status |
| mentor_for_grades | CharField | Grades mentored (optional) |
| emergency_contact_name | CharField | Emergency contact name |
| emergency_contact_phone | CharField | Emergency contact phone |
| emergency_contact_relationship | CharField | Emergency contact relationship |
| profile_picture | ImageField | Profile picture (optional) |
| bio | TextField | Biography (optional) |
| notes | TextField | Additional notes (optional) |

### Choice Fields

#### Gender Choices
- `M`: Male
- `F`: Female
- `O`: Other

#### Status Choices
- `ACTIVE`: Active
- `INACTIVE`: Inactive
- `ON_LEAVE`: On Leave
- `RETIRED`: Retired
- `TERMINATED`: Terminated

#### Employment Type Choices
- `FULL_TIME`: Full Time
- `PART_TIME`: Part Time
- `CONTRACT`: Contract
- `VISITING`: Visiting
- `ADJUNCT`: Adjunct

#### Designation Choices
- `PROFESSOR`: Professor
- `ASSOCIATE_PROFESSOR`: Associate Professor
- `ASSISTANT_PROFESSOR`: Assistant Professor
- `LECTURER`: Lecturer
- `INSTRUCTOR`: Instructor
- `HEAD_OF_DEPARTMENT`: Head of Department
- `DEAN`: Dean
- `PRINCIPAL`: Principal
- `VICE_PRINCIPAL`: Vice Principal

#### Department Choices
- `COMPUTER_SCIENCE`: Computer Science
- `MATHEMATICS`: Mathematics
- `PHYSICS`: Physics
- `CHEMISTRY`: Chemistry
- `BIOLOGY`: Biology
- `ENGLISH`: English
- `HISTORY`: History
- `GEOGRAPHY`: Geography
- `ECONOMICS`: Economics
- `COMMERCE`: Commerce
- `PHYSICAL_EDUCATION`: Physical Education
- `ARTS`: Arts
- `MUSIC`: Music
- `ADMINISTRATION`: Administration
- `OTHER`: Other

## Error Responses

### Validation Error
```json
{
  "field_name": [
    "This field is required."
  ]
}
```

### Not Found Error
```json
{
  "detail": "Not found."
}
```

### Permission Error
```json
{
  "detail": "You do not have permission to perform this action."
}
```

## Rate Limiting

API endpoints are subject to rate limiting to ensure fair usage. The current limits are:
- 1000 requests per hour per user
- 100 requests per minute per user

## Pagination

List endpoints support pagination with the following parameters:
- `page`: Page number
- `page_size`: Number of items per page (default: 20, max: 100)

## Filtering and Search

Most list endpoints support:
- **Filtering**: Use query parameters to filter results
- **Search**: Use the `search` parameter for text search
- **Ordering**: Use the `ordering` parameter to sort results

## Examples

### Creating a Faculty Member
```bash
curl -X POST "http://localhost:8000/api/v1/faculty/api/faculty/" \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "john.doe@example.com",
    "password": "securepassword123",
    "employee_id": "EMP001",
    "first_name": "John",
    "last_name": "Doe",
    "date_of_birth": "1980-01-01",
    "gender": "M",
    "designation": "PROFESSOR",
    "department": "COMPUTER_SCIENCE",
    "employment_type": "FULL_TIME",
    "date_of_joining": "2020-01-01",
    "phone_number": "+1234567890",
    "address_line_1": "123 Main Street",
    "city": "New York",
    "state": "NY",
    "postal_code": "10001",
    "highest_qualification": "PhD",
    "experience_years": 10.0,
    "emergency_contact_name": "Jane Doe",
    "emergency_contact_phone": "+1234567892",
    "emergency_contact_relationship": "Spouse"
  }'
```

### Getting Faculty Statistics
```bash
curl -X GET "http://localhost:8000/api/v1/faculty/api/faculty/statistics/" \
  -H "Authorization: Bearer <your_token>"
```

### Approving a Leave Request
```bash
curl -X POST "http://localhost:8000/api/v1/faculty/api/leaves/123e4567-e89b-12d3-a456-426614174000/approve_leave/" \
  -H "Authorization: Bearer <your_token>"
```

## Support

For API support and questions, please contact the development team or refer to the internal documentation.
