# API Documentation

**Base URL**: `http://localhost:8000/` (Dev) | `https://api.campushub360.xyz/` (Hosted domain)

##  Table of Contents

- [ Authentication](#-authentication)
  - [ Token Management](#token-management)
    - [1. Obtain Access Token](#1-obtain-access-token)
    - [2. Refresh Access Token](#2-refresh-access-token)
  - [Using Authentication](#using-authentication)
  - [Token Configuration](#token-configuration)
- [ Health Checks](#-health-checks)
  - [Basic Health Check](#basic-health-check)
  - [Detailed Health Check](#detailed-health-check)
  - [Readiness Check](#readiness-check)
  - [Liveness Check](#liveness-check)
- [ Students Module (`/api/v1/students/`)](#-students-module-apiv1students)
  - [Models and Data Structures](#models-and-data-structures)
    - [Student Model](#student-model)
  - [Standard CRUD Operations](#standard-crud-operations)
    - [List Students](#list-students)
    - [Create Student](#create-student)
    - [Get Student Details](#get-student-details)
    - [Update Student](#update-student)
    - [Delete Student](#delete-student)
  - [Advanced Endpoints](#advanced-endpoints)
    - [Get Student Documents](#get-student-documents)
    - [Get Student Enrollment History](#get-student-enrollment-history)
    - [Get Student Custom Fields](#get-student-custom-fields)
    - [Create Student Login Account](#create-student-login-account)
    - [Student Statistics](#student-statistics)
    - [Search Students](#search-students)
  - [Bulk Operations](#bulk-operations)
    - [Bulk Create Students](#bulk-create-students)
    - [Bulk Update Students](#bulk-update-students)
    - [Bulk Delete Students](#bulk-delete-students)
  - [Student Documents Management](#student-documents-management)
    - [List Student Documents](#list-student-documents)
    - [Create Student Document](#create-student-document)
    - [Update Student Document](#update-student-document)
    - [Delete Student Document](#delete-student-document)
  - [Custom Fields Management](#custom-fields-management)
    - [List Custom Fields](#list-custom-fields)
    - [Create Custom Field](#create-custom-field)
    - [Custom Field Types](#custom-field-types)
  - [Custom Field Values](#custom-field-values)
    - [Set Custom Field Value](#set-custom-field-value)
    - [Get Values by Student](#get-values-by-student)
- [ Academics Module (`/api/v1/academics/`)](#-academics-module-apiv1academics)
  - [Course Management](#course-management)
    - [List Courses](#list-courses)
    - [Create Course](#create-course)
    - [Get Course Details](#get-course-details)
    - [Update Course](#update-course)
    - [Delete Course](#delete-course)
    - [Get Course Details (Alternative)](#get-course-details-alternative)
  - [Other Academic Resources](#other-academic-resources)
    - [List Syllabi](#list-syllabi)
    - [List Timetables](#list-timetables)
    - [List Enrollments](#list-enrollments)
    - [Academic Calendar](#academic-calendar)
- [ Faculty Module (`/api/v1/faculty/`)](#-faculty-module-apiv1faculty)
  - [Faculty Management](#faculty-management)
    - [List Faculty](#list-faculty)
    - [Create Faculty](#create-faculty)
    - [Get Faculty Details](#get-faculty-details)
    - [Update Faculty](#update-faculty)
    - [Delete Faculty](#delete-faculty)
  - [Faculty Subjects and Schedules](#faculty-subjects-and-schedules)
    - [List Faculty Subjects](#list-faculty-subjects)
    - [List Faculty Schedules](#list-faculty-schedules)
- [ Placements Module (`/api/v1/placements/`)](#-placements-module-apiv1placements)
  - [Company Management](#company-management)
    - [List Companies](#list-companies)
    - [Create Company](#create-company)
    - [Get Company Details](#get-company-details)
    - [Update Company](#update-company)
    - [Delete Company](#delete-company)
  - [Job Postings and Applications](#job-postings-and-applications)
    - [List Job Postings](#list-job-postings)
    - [Create Job Posting](#create-job-posting)
    - [List Applications](#list-applications)
- [ Grads Module (`/api/v1/grads/`)](#-grads-module-apiv1grads)
  - [Grade Scale Management](#grade-scale-management)
    - [List Grade Scales](#list-grade-scales)
    - [Create Grade Scale](#create-grade-scale)
    - [Get Grade Scale Details](#get-grade-scale-details)
    - [Update Grade Scale](#update-grade-scale)
    - [Delete Grade Scale](#delete-grade-scale)
  - [Other Grade Resources](#other-grade-resources)
    - [List Terms](#list-terms)
    - [List Course Results](#list-course-results)
    - [List Term GPAs](#list-term-gpas)
    - [List Graduate Records](#list-graduate-records)
- [ R&D Module (`/api/v1/rnd/`)](#-rd-module-apiv1rnd)
  - [Researcher Management](#researcher-management)
    - [List Researchers](#list-researchers)
    - [Create Researcher](#create-researcher)
    - [Get Researcher Details](#get-researcher-details)
  - [Research Projects and Grants](#research-projects-and-grants)
    - [List Grants](#list-grants)
    - [List Projects](#list-projects)
    - [List Publications](#list-publications)
    - [List Patents](#list-patents)
    - [List Datasets](#list-datasets)
    - [List Collaborations](#list-collaborations)
- [ Other Modules](#-other-modules)
  - [Attendance Module (`/api/v1/attendance/`)](#attendance-module-apiv1attendance)
  - [Facilities Module (`/api/v1/facilities/`)](#facilities-module-apiv1facilities)
  - [Exams Module (`/api/v1/exams/`)](#exams-module-apiv1exams)
  - [Fees Module (`/api/v1/fees/`)](#fees-module-apiv1fees)
  - [Transportation Module (`/api/v1/transport/`)](#transportation-module-apiv1transport)
  - [Mentoring Module (`/api/v1/mentoring/`)](#mentoring-module-apiv1mentoring)
  - [Feedback Module (`/api/v1/feedback/`)](#feedback-module-apiv1feedback)
  - [Open Requests Module (`/api/v1/open-requests/`)](#open-requests-module-apiv1open-requests)
  - [Assignments Module (`/api/v1/assignments/`)](#assignments-module-apiv1assignments)
- [ Error Handling](#-error-handling)
  - [Standard Error Response Format](#standard-error-response-format)
  - [Common HTTP Status Codes](#common-http-status-codes)
  - [Authentication Errors](#authentication-errors)
  - [Validation Errors](#validation-errors)
- [ Data Models and Schemas](#-data-models-and-schemas)
  - [Student Schema](#student-schema)
  - [Course Schema](#course-schema)
  - [Faculty Schema](#faculty-schema)

---

##  Authentication

###  Token Management

#### 1. Obtain Access Token
```http
POST /api/auth/token/
Content-Type: application/json

{
  "email": "usman@gmail.com",
  "password": "123456"
}
```

**Response (200 OK)**:
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

#### 2. Refresh Access Token
```http
POST /api/auth/token/refresh/
Content-Type: application/json

{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response (200 OK)**:
```json
{
  "access": "new_access_token"
}
```

### Using Authentication

Include the access token in the Authorization header: `(In frontendsave in local storage)`

```
Authorization: Bearer your_access_token_here 
```

### Token Configuration
- **Access Token Lifetime**: 30 minutes
- **Refresh Token Lifetime**: 7 days
- **Token Blacklisting**: Enabled for security

---

## Health Checks

### Basic Health Check
```http
GET /health/
```

**Response (200 OK)**:
```json
{
  "status": "healthy",
  "message": "CampsHub360 is running",
  "version": "1.0.0"
}
```

### Detailed Health Check
```http
GET /health/detailed/
```

**Response (200 OK)**:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-26T11:30:00.123456Z",
  "services": {
    "database": {
      "status": "healthy",
      "message": "Database connection successful"
    },
    "cache": {
      "status": "healthy",
      "message": "Cache connection successful"
    },
    "static_files": {
      "status": "healthy",
      "message": "Static files directory accessible"
    },
    "media_files": {
      "status": "healthy",
      "message": "Media files directory accessible"
    }
  }
}
```

### Readiness Check
```http
GET /health/ready/
```

### Liveness Check
```http
GET /health/alive/
```

## Students Module (`/api/v1/students/`)

### Models and Data Structures

#### Student Model
```json
{
  "id": "uuid",
  "roll_number": "string (unique)",
  "first_name": "string",
  "last_name": "string",
  "middle_name": "string (optional)",
  "date_of_birth": "date",
  "gender": "M|F|O",
  "year_of_study": "1|2|3|4|5",
  "semester": "1-10",
  "section": "A|B|C|D|E (optional)",
  "academic_year": "string (optional)",
  "email": "string (optional)",
  "student_mobile": "string (optional)",
  "father_name": "string (optional)",
  "mother_name": "string (optional)",
  "father_mobile": "string (optional)",
  "mother_mobile": "string (optional)",
  "full_address": "string (optional)",
  "village": "string (optional)",
  "aadhar_number": "string (optional)",
  "religion": "HINDU|MUSLIM|CHRISTIAN|SIKH|BUDDHIST|JAIN|OTHER",
  "caste": "string (optional)",
  "subcaste": "string (optional)",
  "quota": "GENERAL|SC|ST|OBC|EWS|PHYSICALLY_CHALLENGED|SPORTS|NRI",
  "rank": "integer (optional)",
  "status": "ACTIVE|INACTIVE|GRADUATED|SUSPENDED|DROPPED",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Standard CRUD Operations

#### List Students
```http
GET /api/v1/students/students/
Authorization: Bearer your_token (Get it from local Storage)
```

**Query Parameters**:
- `page`
- `search`: Search by roll_number, name, email, phone
- `ordering`: Sort by roll_number, first_name, last_name, date_of_birth.
- `year_of_study`
- `status`
- `gender`

**Response (200 OK)**:
```json
{
  "count": 150,
  "next": "http://localhost:8000/api/v1/students/students/?page=2",
  "previous": null,
  "results": [
    {
      "id": "745e7ccb-b4f1-4db3-b32a-37f8bcf06e5b",
      "roll_number": "12345",
      "first_name": "John",
      "last_name": "Doe",
      "middle_name": null,
      "full_name": "John Doe",
      "date_of_birth": "2006-02-26",
      "age": 19,
      "gender": "M",
      "year_of_study": "1",
      "semester": "1",
      "section": null,
      "academic_year": null,
      "email": null,
      "student_mobile": null,
      "quota": null,
      "rank": null,
      "status": "ACTIVE",
      "created_at": "2025-10-20T11:30:33.112283Z",
      "updated_at": "2025-10-20T11:30:33.112294Z"
    }
  ]
}
```

#### Create Student
```http
POST /api/v1/students/students/
Authorization: Bearer your_token
Content-Type: application/json

{
  "first_name": "John",
  "last_name": "Doe",
  "roll_number": "12345",
  "date_of_birth": "2006-02-26",
  "gender": "M",
  "year_of_study": "1",
  "semester": "1",
  "email": "john.doe@student.university.edu",
  "student_mobile": "+1234567890",
  "father_name": "Robert Doe",
  "mother_name": "Jane Doe",
  "father_mobile": "+1234567891",
  "mother_mobile": "+1234567892",
  "full_address": "123 Main St, City, State 12345",
  "religion": "CHRISTIAN",
  "quota": "GENERAL",
  "status": "ACTIVE"
}
```

#### Get Student Details
```http
GET /api/v1/students/students/{id}/
Authorization: Bearer your_token
```

**Response (200 OK)**:
```json
{
  "id": "745e7ccb-b4f1-4db3-b32a-37f8bcf06e5b",
  "roll_number": "12345",
  "first_name": "John",
  "last_name": "Doe",
  "middle_name": null,
  "full_name": "John Doe",
  "date_of_birth": "2006-02-26",
  "age": 19,
  "gender": "M",
  "year_of_study": "1",
  "semester": "1",
  "section": null,
  "academic_year": null,
  "email": "john.doe@student.university.edu",
  "student_mobile": "+1234567890",
  "father_name": "Robert Doe",
  "mother_name": "Jane Doe",
  "father_mobile": "+1234567891",
  "mother_mobile": "+1234567892",
  "full_address": "123 Main St, City, State 12345",
  "village": null,
  "aadhar_number": null,
  "religion": "CHRISTIAN",
  "caste": null,
  "subcaste": null,
  "quota": "GENERAL",
  "rank": null,
  "status": "ACTIVE",
  "created_at": "2025-10-20T11:30:33.112283Z",
  "updated_at": "2025-10-20T11:30:33.112294Z",
  "user_info": {
    "id": "cad3d48b-0321-49f5-948b-78f5671ae93e",
    "username": "12345",
    "email": "12345@students.local",
    "is_active": true,
    "date_joined": "2025-10-20T11:30:33.143635Z"
  },
  "recent_sessions": []
}
```

#### Update Student
```http
PUT /api/v1/students/students/{id}/
Authorization: Bearer your_token
Content-Type: application/json

{
  "first_name": "Johnny",
  "email": "johnny.doe@student.university.edu"
}
```

#### Delete Student
```http
DELETE /api/v1/students/students/{id}/
Authorization: Bearer your_token
```

**Response**: 204 No Content

### Advanced Endpoints

#### Get Student Documents
```http
GET /api/v1/students/students/{id}/documents/
Authorization: Bearer your_token
```

**Response (200 OK)**:
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "student": "745e7ccb-b4f1-4db3-b32a-37f8bcf06e5b",
    "student_name": "John Doe",
    "student_roll_number": "12345",
    "document_type": "ADMISSION_FORM",
    "title": "Admission Form 2024",
    "description": "Original admission form",
    "document_file": "/media/documents/admission_form_12345.pdf",
    "file_size": 2048576,
    "file_url": "http://localhost:8000/media/documents/admission_form_12345.pdf",
    "uploaded_by": "admin-user-id",
    "uploaded_by_name": "Admin User",
    "created_at": "2025-10-20T11:30:33.112283Z",
    "updated_at": "2025-10-20T11:30:33.112294Z"
  }
]
```

#### Get Student Enrollment History
```http
GET /api/v1/students/students/{id}/enrollment-history/
Authorization: Bearer your_token
```

#### Get Student Custom Fields
```http
GET /api/v1/students/students/{id}/custom-fields/
Authorization: Bearer your_token
```

#### Create Student Login Account
```http
POST /api/v1/students/students/{id}/create-login/
Authorization: Bearer your_token
Content-Type: application/json

{
  "password": "custom_password" // optional
}
```

**Response (200 OK)**:
```json
{
  "message": "Login account created successfully"
}
```

#### Student Statistics
```http
GET /api/v1/students/students/stats/
Authorization: Bearer your_token
```

**Response (200 OK)**:
```json
{
  "total_students": 1500,
  "active_students": 1480,
  "students_with_login": 1200,
  "recent_enrollments": 25,
  "grade_distribution": [
    {"year_of_study": "1", "count": 400},
    {"year_of_study": "2", "count": 380},
    {"year_of_study": "3", "count": 350},
    {"year_of_study": "4", "count": 370}
  ],
  "status_distribution": [
    {"status": "ACTIVE", "count": 1480},
    {"status": "GRADUATED", "count": 20}
  ],
  "gender_distribution": [
    {"gender": "M", "count": 900},
    {"gender": "F", "count": 600}
  ]
}
```

#### Search Students
```http
GET /api/v1/students/students/search/?q=john
Authorization: Bearer your_token
```

**Query Parameters**:
- `q`: Search query (searches in roll_number, name, email, phone)

**Response**: List of matching students (max 20 results)

#### Bulk Operations

**Bulk Create Students**:
```http
POST /api/v1/students/students/bulk-create/
Authorization: Bearer your_token
Content-Type: application/json

{
  "students": [
    {
      "first_name": "Alice",
      "last_name": "Smith",
      "roll_number": "12346",
      "date_of_birth": "2006-03-15",
      "gender": "F"
    },
    {
      "first_name": "Bob",
      "last_name": "Johnson",
      "roll_number": "12347",
      "date_of_birth": "2006-01-20",
      "gender": "M"
    }
  ]
}
```

**Bulk Update Students**:
```http
POST /api/v1/students/students/bulk-update/
Authorization: Bearer your_token
Content-Type: application/json

{
  "updates": [
    {
      "roll_number": "12345",
      "email": "new.email@example.com"
    },
    {
      "roll_number": "12346",
      "status": "INACTIVE"
    }
  ]
}
```

**Bulk Delete Students**:
```http
DELETE /api/v1/students/students/bulk-delete/
Authorization: Bearer your_token
Content-Type: application/json

{
  "roll_numbers": ["12345", "12346", "12347"]
}
```

### Student Documents Management

#### List Student Documents
```http
GET /api/v1/students/documents/
Authorization: Bearer your_token
```

#### Create Student Document
```http
POST /api/v1/students/documents/
Authorization: Bearer your_token
Content-Type: multipart/form-data

document_type: "ADMISSION_FORM"
title: "Admission Form 2024"
description: "Original admission form"
student: "745e7ccb-b4f1-4db3-b32a-37f8bcf06e5b"
document_file: (file upload)
```

#### Update Student Document
```http
PUT /api/v1/students/documents/{id}/
Authorization: Bearer your_token
```

#### Delete Student Document
```http
DELETE /api/v1/students/documents/{id}/
Authorization: Bearer your_token
```

### Custom Fields Management

#### List Custom Fields
```http
GET /api/v1/students/custom-fields/
Authorization: Bearer your_token
```

#### Create Custom Field
```http
POST /api/v1/students/custom-fields/
Authorization: Bearer your_token
Content-Type: application/json

{
  "name": "emergency_contact",
  "label": "Emergency Contact",
  "field_type": "TEXT",
  "required": true,
  "help_text": "Emergency contact person name"
}
```

#### Custom Field Types
```http
GET /api/v1/students/custom-fields/types/
Authorization: Bearer your_token
```

**Response**:
```json
[
  {"value": "TEXT", "label": "Text"},
  {"value": "NUMBER", "label": "Number"},
  {"value": "EMAIL", "label": "Email"},
  {"value": "DATE", "label": "Date"},
  {"value": "BOOLEAN", "label": "Boolean"},
  {"value": "SELECT", "label": "Select"},
  {"value": "FILE", "label": "File"}
]
```

### Custom Field Values

#### Set Custom Field Value
```http
POST /api/v1/students/custom-field-values/
Authorization: Bearer your_token
Content-Type: application/json

{
  "student": "745e7ccb-b4f1-4db3-b32a-37f8bcf06e5b",
  "custom_field": "field-uuid",
  "value": "Emergency contact name"
}
```

#### Get Values by Student
```http
GET /api/v1/students/custom-field-values/by-student/?student_id=745e7ccb-b4f1-4db3-b32a-37f8bcf06e5b
Authorization: Bearer your_token
```

---

##  Academics Module (`/api/v1/academics/`)

### Course Management

#### List Courses
```http
GET /api/v1/academics/courses/
Authorization: Bearer your_token
```

**Response (200 OK)**:
```json
{
  "count": 50,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "code": "CS101",
      "title": "Introduction to Computer Science",
      "description": "Basic concepts of programming",
      "credits": 4,
      "level": "UNDERGRADUATE",
      "status": "ACTIVE",
      "department": "Computer Science",
      "prerequisites": [],
      "programs": ["B.Tech CSE", "B.Tech IT"],
      "created_at": "2025-10-20T11:30:33.112283Z",
      "updated_at": "2025-10-20T11:30:33.112294Z"
    }
  ]
}
```

#### Create Course
```http
POST /api/v1/academics/courses/
Authorization: Bearer your_token
Content-Type: application/json

{
  "code": "CS101",
  "title": "Introduction to Computer Science",
  "description": "Basic concepts of programming",
  "credits": 4,
  "level": "UNDERGRADUATE",
  "department": "Computer Science",
  "prerequisites": [],
  "programs": ["B.Tech CSE"]
}
```

#### Get Course Details
```http
GET /api/v1/academics/courses/{id}/
Authorization: Bearer your_token
```

#### Update Course
```http
PUT /api/v1/academics/courses/{id}/
Authorization: Bearer your_token
```

#### Delete Course
```http
DELETE /api/v1/academics/courses/{id}/
Authorization: Bearer your_token
```

#### Get Course Details (Alternative)
```http
GET /api/v1/academics/courses/{id}/detail/
Authorization: Bearer your_token
```

### Other Academic Resources

#### List Syllabi
```http
GET /api/v1/academics/syllabi/
Authorization: Bearer your_token
```

#### List Timetables
```http
GET /api/v1/academics/timetables/
Authorization: Bearer your_token
```

#### List Enrollments
```http
GET /api/v1/academics/enrollments/
Authorization: Bearer your_token
```

#### Academic Calendar
```http
GET /api/v1/academics/academic-calendar/
Authorization: Bearer your_token
```

---

##  Faculty Module (`/api/v1/faculty/`)

### Faculty Management

#### List Faculty
```http
GET /api/v1/faculty/faculty/
Authorization: Bearer your_token
```

**Response (200 OK)**:
```json
{
  "count": 25,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "Dr. John Smith",
      "first_name": "John",
      "last_name": "Smith",
      "middle_name": null,
      "employee_id": "EMP001",
      "apaar_faculty_id": "APAAR12345",
      "email": "john.smith@university.edu",
      "phone_number": "+1234567890",
      "date_of_birth": "1980-01-01",
      "gender": "M",
      "designation": "PROFESSOR",
      "department": "COMPUTER_SCIENCE",
      "area_of_specialization": "Machine Learning",
      "highest_degree": "PhD",
      "university": "MIT",
      "date_of_joining_institution": "2020-01-15",
      "experience_in_current_institute": 5,
      "total_experience": 15,
      "employment_type": "FULL_TIME",
      "nature_of_association": "REGULAR",
      "contractual_full_time_part_time": "FULL_TIME",
      "is_head_of_department": false,
      "is_mentor": true,
      "currently_associated": true,
      "status": "ACTIVE",
      "pan_no": "ABCDE1234F",
      "created_at": "2025-10-20T11:30:33.112283Z",
      "updated_at": "2025-10-20T11:30:33.112294Z"
    }
  ]
}
```

#### Create Faculty
```http
POST /api/v1/faculty/faculty/
Authorization: Bearer your_token
Content-Type: application/json

{
  "name": "Dr. John Smith",
  "first_name": "John",
  "last_name": "Smith",
  "employee_id": "EMP001",
  "apaar_faculty_id": "APAAR12345",
  "email": "john.smith@university.edu",
  "phone_number": "+1234567890",
  "date_of_birth": "1980-01-01",
  "gender": "M",
  "designation": "PROFESSOR",
  "department": "COMPUTER_SCIENCE",
  "area_of_specialization": "Machine Learning",
  "highest_degree": "PhD",
  "university": "MIT",
  "date_of_joining_institution": "2020-01-15",
  "employment_type": "FULL_TIME",
  "nature_of_association": "REGULAR",
  "pan_no": "ABCDE1234F"
}
```


#### Get Faculty Details
```http
GET /api/v1/faculty/faculty/{id}/
Authorization: Bearer your_token
```

#### Update Faculty
```http
PUT /api/v1/faculty/faculty/{id}/
Authorization: Bearer your_token
```

#### Delete Faculty
```http
DELETE /api/v1/faculty/faculty/{id}/
Authorization: Bearer your_token
```

### Faculty Subjects and Schedules

#### List Faculty Subjects
```http
GET /api/v1/faculty/subjects/
Authorization: Bearer your_token
```

#### List Faculty Schedules
```http
GET /api/v1/faculty/schedules/
Authorization: Bearer your_token
```

---

##  Placements Module (`/api/v1/placements/`)

### Company Management

#### List Companies
```http
GET /api/v1/placements/companies/
Authorization: Bearer your_token
```

**Response (200 OK)**:
```json
{
  "count": 10,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "Tech Mahindra",
      "industry": "Technology",
      "website": "https://techmahindra.com",
      "description": "Leading IT services company",
      "address": "123 Tech Street",
      "contact_person": "John Doe",
      "contact_email": "placements@techmahindra.com",
      "contact_phone": "+1234567890",
      "status": "ACTIVE",
      "created_at": "2025-10-20T11:30:33.112283Z",
      "updated_at": "2025-10-20T11:30:33.112294Z"
    }
  ]
}
```

#### Create Company
```http
POST /api/v1/placements/companies/
Authorization: Bearer your_token
Content-Type: application/json

{
  "name": "Google India",
  "industry": "Technology",
  "website": "https://google.co.in",
  "description": "Search and technology company",
  "address": "123 Google Street, Bangalore",
  "contact_person": "Jane Smith",
  "contact_email": "campus@google.com",
  "contact_phone": "+91804567890"
}
```

#### Get Company Details
```http
GET /api/v1/placements/companies/{id}/
Authorization: Bearer your_token
```

#### Update Company
```http
PUT /api/v1/placements/companies/{id}/
Authorization: Bearer your_token
```

#### Delete Company
```http
DELETE /api/v1/placements/companies/{id}/
Authorization: Bearer your_token
```

### Job Postings and Applications

#### List Job Postings
```http
GET /api/v1/placements/jobs/
Authorization: Bearer your_token
```

#### Create Job Posting
```http
POST /api/v1/placements/jobs/
Authorization: Bearer your_token
Content-Type: application/json

{
  "title": "Software Engineer",
  "company": "123e4567-e89b-12d3-a456-426614174000",
  "description": "Full stack development position",
  "requirements": "Python, Django, React",
  "salary_range": "8-12 LPA",
  "deadline": "2025-12-31",
  "eligibility_criteria": "CSE/IT students only"
}
```

#### List Applications
```http
GET /api/v1/placements/applications/
Authorization: Bearer your_token
```

---

##  Grads Module (`/api/v1/grads/`)

### Grade Scale Management

#### List Grade Scales
```http
GET /api/v1/grads/grade-scales/
Authorization: Bearer your_token
```

**Response (200 OK)**:
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "letter": "A",
      "grade_points": 4.0,
      "min_score": 90,
      "max_score": 100,
      "department": "Computer Science",
      "program": "B.Tech",
      "is_active": true,
      "created_at": "2025-10-20T11:30:33.112283Z",
      "updated_at": "2025-10-20T11:30:33.112294Z"
    }
  ]
}
```

#### Create Grade Scale
```http
POST /api/v1/grads/grade-scales/
Authorization: Bearer your_token
Content-Type: application/json

{
  "letter": "A+",
  "grade_points": 4.0,
  "min_score": 95,
  "max_score": 100,
  "department": "Computer Science",
  "program": "B.Tech"
}
```

#### Get Grade Scale Details
```http
GET /api/v1/grads/grade-scales/{id}/
Authorization: Bearer your_token
```

#### Update Grade Scale
```http
PUT /api/v1/grads/grade-scales/{id}/
Authorization: Bearer your_token
```

#### Delete Grade Scale
```http
DELETE /api/v1/grads/grade-scales/{id}/
Authorization: Bearer your_token
```

### Other Grade Resources

#### List Terms
```http
GET /api/v1/grads/terms/
Authorization: Bearer your_token
```

#### List Course Results
```http
GET /api/v1/grads/course-results/
Authorization: Bearer your_token
```

#### List Term GPAs
```http
GET /api/v1/grads/term-gpa/
Authorization: Bearer your_token
```

#### List Graduate Records
```http
GET /api/v1/grads/graduates/
Authorization: Bearer your_token
```

---

##  R&D Module (`/api/v1/rnd/`)

### Researcher Management

#### List Researchers
```http
GET /api/v1/rnd/researchers/
Authorization: Bearer your_token
```

**Response (200 OK)**:
```json
{
  "count": 15,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "user": {
        "id": "user-uuid",
        "username": "researcher1",
        "first_name": "Dr. Alice",
        "last_name": "Johnson",
        "email": "alice.johnson@university.edu"
      },
      "department": "COMPUTER_SCIENCE",
      "title": "Research Professor",
      "orcid": "0000-0002-1825-0097",
      "specialization": "Artificial Intelligence",
      "research_interests": ["Machine Learning", "Natural Language Processing"],
      "is_active": true,
      "created_at": "2025-10-20T11:30:33.112283Z",
      "updated_at": "2025-10-20T11:30:33.112294Z"
    }
  ]
}
```

#### Create Researcher
```http
POST /api/v1/rnd/researchers/
Authorization: Bearer your_token
Content-Type: application/json

{
  "user": "user-uuid",
  "department": "COMPUTER_SCIENCE",
  "title": "Research Professor",
  "orcid": "0000-0002-1825-0097",
  "specialization": "Artificial Intelligence",
  "research_interests": ["Machine Learning", "Natural Language Processing"]
}
```

#### Get Researcher Details
```http
GET /api/v1/rnd/researchers/{id}/
Authorization: Bearer your_token
```

### Research Projects and Grants

#### List Grants
```http
GET /api/v1/rnd/grants/
Authorization: Bearer your_token
```

#### List Projects
```http
GET /api/v1/rnd/projects/
Authorization: Bearer your_token
```

#### List Publications
```http
GET /api/v1/rnd/publications/
Authorization: Bearer your_token
```

#### List Patents
```http
GET /api/v1/rnd/patents/
Authorization: Bearer your_token
```

#### List Datasets
```http
GET /api/v1/rnd/datasets/
Authorization: Bearer your_token
```

#### List Collaborations
```http
GET /api/v1/rnd/collaborations/
Authorization: Bearer your_token
```

---


##  Error Handling

### Standard Error Response Format
```json
{
  "detail": "Error description message",
  "code": "ERROR_CODE",
  "field_errors": {
    "field_name": ["Error message for this field"]
  }
}
```

### HTTP Status Codes
- **200 OK**: Request successful
- **201 Created**: Resource created successfully
- **204 No Content**: Resource deleted successfully
- **400 Bad Request**: Invalid request data
- **401 Unauthorized**: Authentication required or invalid
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **500 Internal Server Error**: Server error 

### Authentication Errors
```json
{
  "detail": "Authentication credentials were not provided.",
  "code": "not_authenticated"
}
```

### Validation Errors
```json
{
  "roll_number": ["This field is required."],
  "email": ["Enter a valid email address."],
  "date_of_birth": ["Date of birth cannot be in the future."]
}
```

---

## Data Models and Schemas

### Student Schema
```json
{
  "type": "object",
  "properties": {
    "id": {"type": "string", "format": "uuid"},
    "roll_number": {"type": "string", "maxLength": 20},
    "first_name": {"type": "string", "maxLength": 100},
    "last_name": {"type": "string", "maxLength": 100},
    "middle_name": {"type": "string", "maxLength": 100, "nullable": true},
    "date_of_birth": {"type": "string", "format": "date"},
    "gender": {"type": "string", "enum": ["M", "F", "O"]},
    "year_of_study": {"type": "string", "enum": ["1", "2", "3", "4", "5"]},
    "semester": {"type": "string", "enum": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]},
    "section": {"type": "string", "enum": ["A", "B", "C", "D", "E"], "nullable": true},
    "academic_year": {"type": "string", "nullable": true},
    "email": {"type": "string", "format": "email", "nullable": true},
    "student_mobile": {"type": "string", "nullable": true},
    "father_name": {"type": "string", "nullable": true},
    "mother_name": {"type": "string", "nullable": true},
    "father_mobile": {"type": "string", "nullable": true},
    "mother_mobile": {"type": "string", "nullable": true},
    "full_address": {"type": "string", "nullable": true},
    "village": {"type": "string", "nullable": true},
    "aadhar_number": {"type": "string", "nullable": true},
    "religion": {"type": "string", "enum": ["HINDU", "MUSLIM", "CHRISTIAN", "SIKH", "BUDDHIST", "JAIN", "OTHER"], "nullable": true},
    "caste": {"type": "string", "nullable": true},
    "subcaste": {"type": "string", "nullable": true},
    "quota": {"type": "string", "enum": ["GENERAL", "SC", "ST", "OBC", "EWS", "PHYSICALLY_CHALLENGED", "SPORTS", "NRI"], "nullable": true},
    "rank": {"type": "integer", "nullable": true},
    "status": {"type": "string", "enum": ["ACTIVE", "INACTIVE", "GRADUATED", "SUSPENDED", "DROPPED"]},
    "created_at": {"type": "string", "format": "date-time"},
    "updated_at": {"type": "string", "format": "date-time"}
  },
  "required": ["roll_number", "first_name", "last_name", "date_of_birth", "gender"]
}
```

### Course Schema
```json
{
  "type": "object",
  "properties": {
    "id": {"type": "string", "format": "uuid"},
    "code": {"type": "string"},
    "title": {"type": "string"},
    "description": {"type": "string"},
    "credits": {"type": "integer"},
    "level": {"type": "string", "enum": ["UNDERGRADUATE", "POSTGRADUATE", "DOCTORATE"]},
    "status": {"type": "string", "enum": ["ACTIVE", "INACTIVE"]},
    "department": {"type": "string"},
    "prerequisites": {"type": "array", "items": {"type": "string"}},
    "programs": {"type": "array", "items": {"type": "string"}},
    "created_at": {"type": "string", "format": "date-time"},
    "updated_at": {"type": "string", "format": "date-time"}
  },
  "required": ["code", "title", "credits"]
}
```

### Faculty Schema
```json
{
  "type": "object",
  "properties": {
    "id": {"type": "string", "format": "uuid"},
    "name": {"type": "string"},
    "first_name": {"type": "string"},
    "last_name": {"type": "string"},
    "middle_name": {"type": "string", "nullable": true},
    "employee_id": {"type": "string"},
    "apaar_faculty_id": {"type": "string"},
    "email": {"type": "string", "format": "email"},
    "phone_number": {"type": "string"},
    "date_of_birth": {"type": "string", "format": "date"},
    "gender": {"type": "string", "enum": ["M", "F", "O"]},
    "designation": {"type": "string"},
    "department": {"type": "string"},
    "area_of_specialization": {"type": "string"},
    "highest_degree": {"type": "string"},
    "university": {"type": "string"},
    "date_of_joining_institution": {"type": "string", "format": "date"},
    "experience_in_current_institute": {"type": "integer"},
    "total_experience": {"type": "integer"},
    "employment_type": {"type": "string", "enum": ["FULL_TIME", "PART_TIME", "CONTRACT"]},
    "nature_of_association": {"type": "string"},
    "contractual_full_time_part_time": {"type": "string"},
    "is_head_of_department": {"type": "boolean"},
    "is_mentor": {"type": "boolean"},
    "currently_associated": {"type": "boolean"},
    "status": {"type": "string", "enum": ["ACTIVE", "INACTIVE", "RETIRED"]},
    "pan_no": {"type": "string"},
    "created_at": {"type": "string", "format": "date-time"},
    "updated_at": {"type": "string", "format": "date-time"}
  },
  "required": ["name", "email", "designation", "department"]
}
```
