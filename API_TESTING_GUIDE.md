# API Testing Guide - CampsHub360

## Overview

CampsHub360 includes a comprehensive API testing system that works like Postman, allowing you to test your APIs directly from the web interface. The system supports collections, environments, test scripts, and automated testing.

## Features

- **Postman-like Interface**: Familiar UI similar to Postman
- **Collections**: Organize API requests into collections
- **Environments**: Manage different environments (dev, staging, prod)
- **Test Scripts**: Write JavaScript tests for API responses
- **Automated Testing**: Run test suites and automate API testing
- **Request History**: Track all API requests and responses
- **Authentication**: Support for various authentication methods

## Quick Start

### 1. Access the API Testing Interface

1. Log in to the CampsHub360 dashboard
2. Navigate to **Quick API Test** in the sidebar
3. You'll see a Postman-like interface with:
   - Left sidebar: Collections and requests
   - Main panel: Request configuration
   - Response panel: API responses

### 2. Make Your First API Call

1. **Select HTTP Method**: Choose GET, POST, PUT, or DELETE
2. **Enter URL**: Type your API endpoint (e.g., `http://localhost:8000/api/v1/students/students/`)
3. **Add Headers**: Click the "Headers" tab to add request headers
4. **Add Body** (for POST/PUT): Click the "Body" tab to add request data
5. **Click Send**: Press the "Send" button to make the request
6. **View Response**: See the response in the bottom panel

### 3. Using Pre-configured Collections

The system comes with sample collections:

- **Students API**: Endpoints for student management
- **Authentication API**: JWT token endpoints

Click on any request in the sidebar to load it into the main panel.

## Available API Endpoints

### Students API (`/api/v1/students/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/students/` | List all students with pagination |
| GET | `/students/{id}/` | Get student details |
| POST | `/students/` | Create a new student |
| PUT | `/students/{id}/` | Update a student |
| DELETE | `/students/{id}/` | Delete a student |
| GET | `/students/search/` | Search students |
| GET | `/students/stats/` | Get student statistics |

### Authentication API (`/api/auth/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/token/` | Get JWT access token |
| POST | `/token/refresh/` | Refresh JWT token |

## Sample Requests

### 1. Get All Students

```http
GET http://localhost:8000/api/v1/students/students/
Content-Type: application/json
```

### 2. Create a Student

```http
POST http://localhost:8000/api/v1/students/students/
Content-Type: application/json

{
    "first_name": "John",
    "last_name": "Doe",
    "date_of_birth": "2010-01-15",
    "gender": "M",
    "grade_level": 10,
    "section": "A",
    "email": "john.doe@example.com"
}
```

### 3. Get JWT Token

```http
POST http://localhost:8000/api/auth/token/
Content-Type: application/json

{
    "username": "admin",
    "password": "admin123"
}
```

## Advanced Features

### 1. Collections Management

Access the full API testing dashboard at `/dashboard/api-testing-dashboard/` to:

- Create new collections
- Organize requests
- Set up environments
- Write test scripts

### 2. Environment Variables

Create environments to manage different configurations:

- **Development**: `http://localhost:8000`
- **Staging**: `https://staging.campshub360.com`
- **Production**: `https://api.campshub360.com`

### 3. Test Scripts

Write JavaScript tests using Postman-like syntax:

```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has data", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData).to.be.an('object');
});

pm.test("Response time is less than 5 seconds", function () {
    pm.expect(pm.response.responseTime).to.be.below(5000);
});
```

### 4. Authentication

The system supports various authentication methods:

- **Bearer Token**: Add `Authorization: Bearer <token>` header
- **Basic Auth**: Username/password authentication
- **API Key**: Custom API key authentication

## Troubleshooting

### Common Issues

1. **CORS Errors**: Make sure your API allows requests from the dashboard domain
2. **Authentication Errors**: Verify your credentials and token validity
3. **Network Errors**: Check if the API server is running and accessible

### Getting Help

1. Check the browser console for JavaScript errors
2. Verify API endpoints are correct
3. Ensure proper authentication headers are set
4. Check server logs for backend errors

## API Documentation

For detailed API documentation, see:
- Students API: `/students/API_DOCUMENTATION.md`
- Faculty API: `/faculty/API_DOCUMENTATION.md`

## Development

### Adding New Collections

1. Go to Django Admin: `/admin/`
2. Navigate to **Dashboard > API Collections**
3. Create a new collection
4. Add requests to the collection
5. Configure test scripts and assertions

### Customizing the Interface

The API testing interface is built with:
- **Frontend**: HTML, CSS, JavaScript
- **Backend**: Django, Django REST Framework
- **Templates**: Django templates with Bootstrap

### Extending Functionality

To add new features:

1. **Models**: Extend `dashboard/models.py`
2. **Views**: Add views in `dashboard/views.py`
3. **Templates**: Create templates in `dashboard/templates/`
4. **JavaScript**: Add client-side functionality

## Security Considerations

- All API requests are logged for audit purposes
- Authentication tokens are stored securely
- CORS policies should be configured properly
- Rate limiting is recommended for production APIs

## Performance Tips

1. **Use Environments**: Set up different environments for dev/staging/prod
2. **Organize Collections**: Group related requests together
3. **Write Tests**: Automate API testing with test scripts
4. **Monitor Performance**: Track response times and success rates

---

For more information, contact the development team or check the project documentation.
