# Facilities Management App

A comprehensive Django application for managing university classrooms, labs, and facilities with advanced booking and maintenance features.

## 🏢 Features

### Core Management
- **Buildings & Rooms**: Manage university buildings and individual rooms
- **Room Types**: Support for classrooms, labs, lecture halls, and meeting rooms
- **Equipment Tracking**: Track equipment inventory per room
- **Capacity Management**: Set and manage room capacities

### Advanced Booking System
- **Smart Scheduling**: Conflict detection and validation
- **Approval Workflow**: Booking approval system
- **Real-time Availability**: Check room availability instantly
- **Past Booking Prevention**: No bookings in the past allowed

### Maintenance Management
- **Scheduled Maintenance**: Plan and track maintenance activities
- **Status Tracking**: Monitor maintenance progress
- **Room Blocking**: Automatically block rooms during maintenance

### Modern Dashboard
- **Beautiful UI**: Modern, responsive design with glassmorphism effects
- **Real-time Stats**: Live statistics and metrics
- **Quick Actions**: Easy access to common tasks
- **Mobile Responsive**: Works perfectly on all devices

## 🚀 Quick Start

### 1. Access the Dashboard
Navigate to `/dashboard/facilities/` to access the main facilities dashboard.

### 2. Create Your First Building
1. Go to Django Admin (`/admin/`)
2. Navigate to Facilities → Buildings
3. Add a new building with code and name

### 3. Add Rooms
1. In Django Admin, go to Facilities → Rooms
2. Create rooms with building, type, and capacity
3. Set room status to active

### 4. Make Your First Booking
1. Go to the facilities dashboard
2. Click "➕ New Booking"
3. Select room, set time, and create booking

## 📱 Dashboard Features

### Main Dashboard (`/facilities/`)
- **Statistics Cards**: Buildings, rooms, bookings, maintenance counts
- **Recent Activity**: Latest bookings and maintenance updates
- **Quick Actions**: Direct access to all major functions

### Rooms Management (`/facilities/rooms/`)
- **Advanced Filtering**: Filter by building, type, capacity
- **Room Cards**: Beautiful room information display
- **Quick Actions**: View details or book directly

### Booking System (`/facilities/bookings/`)
- **Create Bookings**: Easy booking creation with validation
- **Conflict Detection**: Automatic overlap checking
- **Approval System**: Manage booking approvals

### Analytics (`/facilities/analytics/`)
- **Utilization Stats**: Room usage statistics
- **Trends**: Booking patterns and room preferences
- **Reports**: Comprehensive facility reports

## 🔧 API Endpoints

### REST API (`/api/v1/facilities/`)
- `GET /api/v1/facilities/buildings/` - List all buildings
- `GET /api/v1/facilities/rooms/` - List all rooms
- `GET /api/v1/facilities/rooms/{id}/availability/` - Check room availability
- `POST /api/v1/facilities/bookings/` - Create new booking
- `GET /api/v1/facilities/bookings/conflicts/` - Check for booking conflicts

### Authentication
All API endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## 🎨 UI Components

### Design System
- **Glassmorphism**: Modern translucent card design
- **Gradient Backgrounds**: Beautiful color schemes
- **Smooth Animations**: Hover effects and transitions
- **Responsive Grid**: Adaptive layouts for all screen sizes

### Interactive Elements
- **Hover Effects**: Cards lift and glow on hover
- **Ripple Effects**: Button click animations
- **Loading States**: Spinners and progress indicators
- **Form Validation**: Real-time error checking

## 📊 Data Models

### Building
- `name`: Building name
- `code`: Unique building code
- `address`: Building address

### Room
- `building`: Foreign key to Building
- `name`: Room name
- `code`: Room code (unique within building)
- `room_type`: Classroom, Lab, Lecture Hall, Meeting Room
- `capacity`: Maximum number of people
- `floor`: Floor number
- `is_active`: Room availability status

### Equipment
- `name`: Equipment name
- `description`: Equipment description

### RoomEquipment
- `room`: Foreign key to Room
- `equipment`: Foreign key to Equipment
- `quantity`: Number of items

### Booking
- `room`: Foreign key to Room
- `title`: Booking title
- `purpose`: Booking purpose
- `starts_at`: Start date and time
- `ends_at`: End date and time
- `created_by`: User who created the booking
- `is_approved`: Approval status

### Maintenance
- `room`: Foreign key to Room
- `title`: Maintenance title
- `description`: Maintenance description
- `status`: Scheduled, In Progress, Completed
- `scheduled_for`: Scheduled maintenance time
- `resolved_at`: Completion time

## 🔒 Security Features

### Authentication & Authorization
- **Login Required**: All dashboard views require authentication
- **Admin Access**: Dashboard functions limited to admin users
- **JWT Tokens**: Secure API authentication

### Data Validation
- **Booking Conflicts**: Automatic overlap detection
- **Past Bookings**: Prevention of historical bookings
- **Time Validation**: Start time must be before end time
- **Minimum Duration**: 15-minute minimum booking duration

## 🧪 Testing

Run the test suite:
```bash
python manage.py test facilities
```

### Test Coverage
- **Booking Validation**: Conflict detection and time validation
- **Model Integrity**: Database constraints and relationships
- **API Endpoints**: Serializer and viewset functionality

## 🚀 Advanced Features

### Smart Scheduling
- **Conflict Detection**: Real-time overlap checking
- **Availability API**: Get room availability for any time period
- **Capacity Planning**: Room size recommendations

### Maintenance Integration
- **Automatic Blocking**: Rooms blocked during maintenance
- **Status Tracking**: Real-time maintenance progress
- **Scheduling**: Plan maintenance without conflicts

### Analytics & Reporting
- **Utilization Metrics**: Room usage statistics
- **Trend Analysis**: Booking patterns over time
- **Capacity Planning**: Optimize room allocation

## 🔧 Configuration

### Settings
The app is automatically configured when added to `INSTALLED_APPS`:
```python
INSTALLED_APPS = [
    # ... other apps
    'facilities',
]
```

### URLs
Include the facilities URLs in your main URL configuration:
```python
urlpatterns = [
    # ... other URLs
    path('api/v1/facilities/', include('facilities.urls', namespace='facilities')),
]
```

## 📱 Mobile Experience

### Responsive Design
- **Mobile First**: Optimized for mobile devices
- **Touch Friendly**: Large touch targets and gestures
- **Adaptive Layouts**: Grid systems that adapt to screen size
- **Fast Loading**: Optimized for mobile networks

### Progressive Web App Features
- **Offline Support**: Basic functionality without internet
- **App-like Experience**: Full-screen and home screen installation
- **Push Notifications**: Booking confirmations and updates

## 🎯 Future Enhancements

### Planned Features
- **Recurring Bookings**: Weekly/monthly recurring schedules
- **Calendar Integration**: Google Calendar and Outlook sync
- **QR Code Check-in**: Digital room access verification
- **Equipment Reservations**: Individual equipment booking
- **Advanced Analytics**: Machine learning insights
- **Mobile App**: Native iOS and Android applications

### Integration Possibilities
- **Student Portal**: Direct student booking access
- **Faculty Dashboard**: Department-specific views
- **Billing System**: Room usage billing integration
- **Cleaning Schedule**: Automatic cleaning coordination
- **Security System**: Access control integration

## 🤝 Contributing

### Development Setup
1. Clone the repository
2. Install dependencies: `pip install -r requirements.txt`
3. Run migrations: `python manage.py migrate`
4. Create superuser: `python manage.py createsuperuser`
5. Run development server: `python manage.py runserver`

### Code Standards
- Follow Django coding standards
- Add tests for new features
- Update documentation
- Ensure all tests pass

## 📄 License

This app is part of the CampsHub360 project and follows the same licensing terms.

## 🆘 Support

For support and questions:
- Check the documentation
- Review the test cases
- Contact the development team
- Submit issues through the project repository

---

**Built with ❤️ for modern university facility management**
