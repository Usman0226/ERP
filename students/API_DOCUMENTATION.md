# Students API Documentation

## Overview

The Students API provides comprehensive endpoints for managing student data, enrollment history, documents, custom fields, and bulk operations. All endpoints require authentication using JWT tokens.

**Base URL**: `/api/v1/students/`

## Authentication

All API endpoints require authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## Endpoints

### 1. Students

#### List Students
```
GET /api/v1/students/students/
```

**Query Parameters:**
- `search` - Search across multiple fields
- `name` - Filter by student name
- `parent_name` - Filter by parent name
- `grade_level` - Filter by grade level (1-12)
- `section` - Filter by section (A, B, C, D, E)
- `gender` - Filter by gender (M, F, O)
- `status` - Filter by status (ACTIVE, INACTIVE, GRADUATED)
- `quota` - Filter by quota category
- `has_login` - Filter by login account status (true/false)
- `has_email` - Filter by email status (true/false)
- `has_mobile` - Filter by mobile status (true/false)
- `age_min` / `age_max` - Filter by age range
- `rank_min` / `rank_max` - Filter by rank range
- `date_of_birth_after` / `date_of_birth_before` - Filter by birth date range
- `created_after` / `created_before` - Filter by creation date range
- `ordering` - Sort by field (e.g., `-created_at`, `first_name`)
- `page` - Page number for pagination

**Response:**
```json
{
    "count": 100,
    "next": "http://localhost:8000/api/v1/students/students/?page=2",
    "previous": null,
    "results": [
        {
            "id": "uuid",
            "roll_number": "STU001",
            "first_name": "John",
            "last_name": "Doe",
            "full_name": "John Doe",
            "date_of_birth": "2010-01-15",
            "age": 15,
            "gender": "M",
            "grade_level": 10,
            "section": "A",
            "email": "john.doe@example.com",
            "student_mobile": "+1234567890",
            "status": "ACTIVE",
            "has_login": true,
            "created_at": "2023-09-01T10:00:00Z"
        }
    ]
}
```

#### Get Student Details
```
GET /api/v1/students/students/{id}/
```

**Response:**
```json
{
    "id": "uuid",
    "roll_number": "STU001",
    "first_name": "John",
    "last_name": "Doe",
    "full_name": "John Doe",
    "date_of_birth": "2010-01-15",
    "age": 15,
    "gender": "M",
    "grade_level": 10,
    "section": "A",
    "email": "john.doe@example.com",
    "student_mobile": "+1234567890",
    "father_name": "John Doe Sr",
    "mother_name": "Mary Doe",
    "father_mobile": "+1234567891",
    "mother_mobile": "+1234567892",
    "full_address": "123 Main St, New York, NY",
    "village": "Downtown",
    "aadhar_number": "123456789012",
    "religion": "Hindu",
    "caste": "General",
    "subcaste": "Brahmin",
    "status": "ACTIVE",
    "user_info": {
        "id": 1,
        "username": "STU001",
        "email": "john.doe@example.com",
        "is_active": true,
        "date_joined": "2023-09-01T10:00:00Z"
    },
    "recent_sessions": [
        {
            "id": 1,
            "ip": "192.168.1.1",
            "device_info": "Mozilla/5.0...",
            "created_at": "2023-09-01T10:00:00Z",
            "expires_at": "2023-09-01T10:05:00Z",
            "is_active": true
        }
    ],
    "created_at": "2023-09-01T10:00:00Z"
}
```

#### Create Student
```
POST /api/v1/students/students/
```

**Request Body:**
```json
{
    "roll_number": "STU002",
    "first_name": "Jane",
    "last_name": "Smith",
    "date_of_birth": "2010-03-20",
    "gender": "F",
    "grade_level": 11,
    "section": "B",
    "email": "jane.smith@example.com",
    "student_mobile": "+1234567893",
    "father_name": "James Smith",
    "mother_name": "Sarah Smith"
}
```

#### Update Student
```
PUT /api/v1/students/students/{id}/
PATCH /api/v1/students/students/{id}/
```

#### Delete Student
```
DELETE /api/v1/students/students/{id}/
```

#### Student Statistics
```
GET /api/v1/students/students/stats/
```

**Response:**
```json
{
    "total_students": 100,
    "active_students": 85,
    "students_with_login": 75,
    "recent_enrollments": 10,
    "grade_distribution": [
        {"grade_level": 10, "count": 25},
        {"grade_level": 11, "count": 30},
        {"grade_level": 12, "count": 45}
    ],
    "status_distribution": [
        {"status": "ACTIVE", "count": 85},
        {"status": "INACTIVE", "count": 10},
        {"status": "GRADUATED", "count": 5}
    ],
    "gender_distribution": [
        {"gender": "M", "count": 55},
        {"gender": "F", "count": 45}
    ]
}
```

#### Search Students
```
GET /api/v1/students/students/search/?q=john
```

#### Create Login Account
```
POST /api/v1/students/students/{id}/create-login/
```

#### Get Student Documents
```
GET /api/v1/students/students/{id}/documents/
```

#### Get Student Enrollment History
```
GET /api/v1/students/students/{id}/enrollment-history/
```

#### Get Student Custom Fields
```
GET /api/v1/students/students/{id}/custom-fields/
```

### 2. Bulk Operations

#### Bulk Create Students
```
POST /api/v1/students/students/bulk-create/
```

**Request Body:**
```json
{
    "students": [
        {
            "roll_number": "STU003",
            "first_name": "Mike",
            "last_name": "Johnson",
            "date_of_birth": "2010-06-10",
            "gender": "M",
            "grade_level": 12
        },
        {
            "roll_number": "STU004",
            "first_name": "Lisa",
            "last_name": "Brown",
            "date_of_birth": "2010-08-15",
            "gender": "F",
            "grade_level": 11
        }
    ]
}
```

#### Bulk Update Students
```
POST /api/v1/students/students/bulk-update/
```

**Request Body:**
```json
{
    "updates": [
        {
            "roll_number": "STU003",
            "grade_level": 12,
            "section": "A"
        },
        {
            "roll_number": "STU004",
            "status": "ACTIVE"
        }
    ]
}
```

#### Bulk Delete Students
```
DELETE /api/v1/students/students/bulk-delete/
```

**Request Body:**
```json
{
    "roll_numbers": ["STU003", "STU004"]
}
```

### 3. Enrollment History

#### List Enrollment History
```
GET /api/v1/students/enrollment-history/
```

**Query Parameters:**
- `student` - Filter by student ID
- `academic_year` - Filter by academic year
- `grade_level` - Filter by grade level
- `status` - Filter by status
- `enrollment_date_after` / `enrollment_date_before` - Filter by date range
- `search` - Search across fields

#### Create Enrollment Record
```
POST /api/v1/students/enrollment-history/
```

**Request Body:**
```json
{
    "student": "uuid",
    "academic_year": "2023-2024",
    "grade_level": 11,
    "section": "A",
    "enrollment_date": "2023-06-01",
    "status": "ENROLLED",
    "remarks": "New enrollment"
}
```

### 4. Documents

#### List Documents
```
GET /api/v1/students/documents/
```

**Query Parameters:**
- `student` - Filter by student ID
- `document_type` - Filter by document type
- `uploaded_by` - Filter by uploader
- `uploaded_after` / `uploaded_before` - Filter by upload date
- `search` - Search across fields

#### Upload Document
```
POST /api/v1/students/documents/
```

**Request Body (multipart/form-data):**
```
student: uuid
document_type: "ADMISSION_FORM"
title: "Admission Form"
description: "Student admission form"
document_file: [file]
```

### 5. Custom Fields

#### List Custom Fields
```
GET /api/v1/students/custom-fields/
```

**Query Parameters:**
- `field_type` - Filter by field type
- `required` - Filter by required status
- `is_active` - Filter by active status
- `search` - Search across fields

#### Create Custom Field
```
POST /api/v1/students/custom-fields/
```

**Request Body:**
```json
{
    "name": "blood_group",
    "label": "Blood Group",
    "field_type": "SELECT",
    "required": true,
    "choices": "A+,A-,B+,B-,AB+,AB-,O+,O-",
    "help_text": "Student's blood group"
}
```

#### Get Field Types
```
GET /api/v1/students/custom-fields/types/
```

**Response:**
```json
[
    {"value": "TEXT", "label": "Text"},
    {"value": "NUMBER", "label": "Number"},
    {"value": "SELECT", "label": "Select"},
    {"value": "DATE", "label": "Date"},
    {"value": "FILE", "label": "File"}
]
```

#### Custom Field Statistics
```
GET /api/v1/students/custom-fields/stats/
```

### 6. Custom Field Values

#### List Custom Field Values
```
GET /api/v1/students/custom-field-values/
```

**Query Parameters:**
- `student` - Filter by student ID
- `custom_field` - Filter by custom field ID
- `search` - Search across fields

#### Get Values by Student
```
GET /api/v1/students/custom-field-values/by-student/?student_id=uuid
```

#### Get Values by Field
```
GET /api/v1/students/custom-field-values/by-field/?field_id=uuid
```

### 7. Import History

#### List Import Records
```
GET /api/v1/students/imports/
```

**Query Parameters:**
- `status` - Filter by status
- `created_by` - Filter by creator
- `search` - Search by filename

#### Import Statistics
```
GET /api/v1/students/imports/stats/
```

**Response:**
```json
{
    "total_imports": 15,
    "successful_imports": 12,
    "failed_imports": 3,
    "recent_imports": 5,
    "total_students_imported": 250
}
```

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
    "detail": "Authentication credentials were not provided."
}
```

## Pagination

All list endpoints support pagination with the following query parameters:
- `page` - Page number (default: 1)
- `page_size` - Items per page (default: 20, max: 100)

## Filtering

Most endpoints support filtering using query parameters. Use the following syntax:
- Exact match: `field=value`
- Contains: `field__icontains=value`
- Greater than: `field__gte=value`
- Less than: `field__lte=value`
- In list: `field__in=value1,value2`

## Ordering

Use the `ordering` parameter to sort results:
- Ascending: `ordering=field_name`
- Descending: `ordering=-field_name`
- Multiple fields: `ordering=field1,-field2`

## Rate Limiting

API requests are rate-limited to prevent abuse. Limits are applied per user and endpoint.

## Examples

### Create a Student with Custom Fields
```bash
# 1. Create student
curl -X POST "http://localhost:8000/api/v1/students/students/" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "roll_number": "STU005",
    "first_name": "Alice",
    "last_name": "Wilson",
    "date_of_birth": "2010-04-12",
    "gender": "F",
    "grade_level": 10
  }'

# 2. Add custom field value
curl -X POST "http://localhost:8000/api/v1/students/custom-field-values/" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "student": "student_uuid",
    "custom_field": "field_uuid",
    "value": "A+"
  }'
```

### Search and Filter Students
```bash
# Search for students with specific criteria
curl -X GET "http://localhost:8000/api/v1/students/students/?search=john&grade_level=10&status=ACTIVE&ordering=-created_at" \
  -H "Authorization: Bearer <token>"
```

### Bulk Operations
```bash
# Bulk create students
curl -X POST "http://localhost:8000/api/v1/students/students/bulk-create/" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "students": [
      {"roll_number": "STU006", "first_name": "Bob", "last_name": "Davis", "date_of_birth": "2010-07-20", "gender": "M"},
      {"roll_number": "STU007", "first_name": "Carol", "last_name": "Miller", "date_of_birth": "2010-09-15", "gender": "F"}
    ]
  }'
```

