from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from django.utils import timezone
from datetime import date, time
import uuid

from .models import (
    Faculty, FacultySubject, FacultySchedule, FacultyLeave, 
    FacultyPerformance, FacultyDocument, CustomField, CustomFieldValue
)

User = get_user_model()


class FacultyModelTest(TestCase):
    """Test cases for Faculty model"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='faculty@test.com',
            username='testfaculty',
            password='testpass123'
        )
        
        self.faculty = Faculty.objects.create(
            user=self.user,
            name='John Doe',
            apaar_faculty_id='APAAR001',
            employee_id='EMP001',
            first_name='John',
            last_name='Doe',
            date_of_birth=date(1980, 1, 1),
            gender='M',
            designation='PROFESSOR',
            department='COMPUTER_SCIENCE',
            employment_type='FULL_TIME',
            date_of_joining=date(2020, 1, 1),
            date_of_joining_institution=date(2020, 1, 1),
            designation_at_joining='Assistant Professor',
            present_designation='Professor',
            nature_of_association='REGULAR',
            currently_associated=True,
            experience_in_current_institute=3.0,
            email='john.doe@test.com',
            phone_number='+1234567890',
            address_line_1='123 Test Street',
            city='Test City',
            state='Test State',
            postal_code='12345',
            highest_qualification='PhD',
            experience_years=10.0,
            emergency_contact_name='Jane Doe',
            emergency_contact_phone='+1234567891',
            emergency_contact_relationship='Spouse'
        )
    
    def test_faculty_creation(self):
        """Test faculty creation"""
        self.assertEqual(self.faculty.name, 'John Doe')
        self.assertEqual(self.faculty.apaar_faculty_id, 'APAAR001')
        self.assertTrue(self.faculty.is_active_faculty)
    
    def test_faculty_str_representation(self):
        """Test faculty string representation"""
        expected = 'John Doe (APAAR001)'
        self.assertEqual(str(self.faculty), expected)
    
    def test_faculty_with_middle_name(self):
        """Test faculty with middle name"""
        self.faculty.middle_name = 'Michael'
        self.faculty.save()
        self.assertEqual(self.faculty.full_name, 'John Michael Doe')


class FacultySubjectModelTest(TestCase):
    """Test cases for FacultySubject model"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='faculty@test.com',
            username='testfaculty',
            password='testpass123'
        )
        
        self.faculty = Faculty.objects.create(
            user=self.user,
            name='John Doe',
            apaar_faculty_id='APAAR001',
            employee_id='EMP001',
            first_name='John',
            last_name='Doe',
            date_of_birth=date(1980, 1, 1),
            gender='M',
            designation='PROFESSOR',
            department='COMPUTER_SCIENCE',
            employment_type='FULL_TIME',
            date_of_joining=date(2020, 1, 1),
            date_of_joining_institution=date(2020, 1, 1),
            designation_at_joining='Assistant Professor',
            present_designation='Professor',
            nature_of_association='REGULAR',
            currently_associated=True,
            experience_in_current_institute=3.0,
            email='john.doe@test.com',
            phone_number='+1234567890',
            address_line_1='123 Test Street',
            city='Test City',
            state='Test State',
            postal_code='12345',
            highest_qualification='PhD',
            experience_years=10.0,
            emergency_contact_name='Jane Doe',
            emergency_contact_phone='+1234567891',
            emergency_contact_relationship='Spouse'
        )
        
        self.subject = FacultySubject.objects.create(
            faculty=self.faculty,
            subject_name='Python Programming',
            grade_level='Grade 10',
            academic_year='2023-2024',
            is_primary_subject=True
        )
    
    def test_subject_creation(self):
        """Test subject creation"""
        self.assertEqual(self.subject.subject_name, 'Python Programming')
        self.assertEqual(self.subject.faculty, self.faculty)
        self.assertTrue(self.subject.is_primary_subject)
    
    def test_subject_str_representation(self):
        """Test subject string representation"""
        expected = 'John Doe - Python Programming (Grade 10)'
        self.assertEqual(str(self.subject), expected)


class FacultyScheduleModelTest(TestCase):
    """Test cases for FacultySchedule model"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='faculty@test.com',
            username='testfaculty',
            password='testpass123'
        )
        
        self.faculty = Faculty.objects.create(
            user=self.user,
            name='John Doe',
            apaar_faculty_id='APAAR001',
            employee_id='EMP001',
            first_name='John',
            last_name='Doe',
            date_of_birth=date(1980, 1, 1),
            gender='M',
            designation='PROFESSOR',
            department='COMPUTER_SCIENCE',
            employment_type='FULL_TIME',
            date_of_joining=date(2020, 1, 1),
            date_of_joining_institution=date(2020, 1, 1),
            designation_at_joining='Assistant Professor',
            present_designation='Professor',
            nature_of_association='REGULAR',
            currently_associated=True,
            experience_in_current_institute=3.0,
            email='john.doe@test.com',
            phone_number='+1234567890',
            address_line_1='123 Test Street',
            city='Test City',
            state='Test State',
            postal_code='12345',
            highest_qualification='PhD',
            experience_years=10.0,
            emergency_contact_name='Jane Doe',
            emergency_contact_phone='+1234567891',
            emergency_contact_relationship='Spouse'
        )
        
        self.schedule = FacultySchedule.objects.create(
            faculty=self.faculty,
            day_of_week='MONDAY',
            start_time=time(9, 0),
            end_time=time(10, 0),
            subject='Python Programming',
            grade_level='Grade 10',
            room_number='A101'
        )
    
    def test_schedule_creation(self):
        """Test schedule creation"""
        self.assertEqual(self.schedule.day_of_week, 'MONDAY')
        self.assertEqual(self.schedule.subject, 'Python Programming')
        self.assertEqual(self.schedule.room_number, 'A101')
    
    def test_schedule_str_representation(self):
        """Test schedule string representation"""
        expected = 'John Doe - Python Programming (MONDAY)'
        self.assertEqual(str(self.schedule), expected)


class FacultyLeaveModelTest(TestCase):
    """Test cases for FacultyLeave model"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='faculty@test.com',
            username='testfaculty',
            password='testpass123'
        )
        
        self.faculty = Faculty.objects.create(
            user=self.user,
            name='John Doe',
            apaar_faculty_id='APAAR001',
            employee_id='EMP001',
            first_name='John',
            last_name='Doe',
            date_of_birth=date(1980, 1, 1),
            gender='M',
            designation='PROFESSOR',
            department='COMPUTER_SCIENCE',
            employment_type='FULL_TIME',
            date_of_joining=date(2020, 1, 1),
            date_of_joining_institution=date(2020, 1, 1),
            designation_at_joining='Assistant Professor',
            present_designation='Professor',
            nature_of_association='REGULAR',
            currently_associated=True,
            experience_in_current_institute=3.0,
            email='john.doe@test.com',
            phone_number='+1234567890',
            address_line_1='123 Test Street',
            city='Test City',
            state='Test State',
            postal_code='12345',
            highest_qualification='PhD',
            experience_years=10.0,
            emergency_contact_name='Jane Doe',
            emergency_contact_phone='+1234567891',
            emergency_contact_relationship='Spouse'
        )
        
        self.leave = FacultyLeave.objects.create(
            faculty=self.faculty,
            leave_type='SICK',
            start_date=date(2023, 12, 1),
            end_date=date(2023, 12, 3),
            reason='Not feeling well'
        )
    
    def test_leave_creation(self):
        """Test leave creation"""
        self.assertEqual(self.leave.leave_type, 'SICK')
        self.assertEqual(self.leave.status, 'PENDING')
        self.assertEqual(self.leave.leave_days, 3)
    
    def test_leave_str_representation(self):
        """Test leave string representation"""
        expected = 'John Doe - SICK (2023-12-01 to 2023-12-03)'
        self.assertEqual(str(self.leave), expected)


class FacultyPerformanceModelTest(TestCase):
    """Test cases for FacultyPerformance model"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='faculty@test.com',
            username='testfaculty',
            password='testpass123'
        )
        
        self.faculty = Faculty.objects.create(
            user=self.user,
            name='John Doe',
            apaar_faculty_id='APAAR001',
            employee_id='EMP001',
            first_name='John',
            last_name='Doe',
            date_of_birth=date(1980, 1, 1),
            gender='M',
            designation='PROFESSOR',
            department='COMPUTER_SCIENCE',
            employment_type='FULL_TIME',
            date_of_joining=date(2020, 1, 1),
            date_of_joining_institution=date(2020, 1, 1),
            designation_at_joining='Assistant Professor',
            present_designation='Professor',
            nature_of_association='REGULAR',
            currently_associated=True,
            experience_in_current_institute=3.0,
            email='john.doe@test.com',
            phone_number='+1234567890',
            address_line_1='123 Test Street',
            city='Test City',
            state='Test State',
            postal_code='12345',
            highest_qualification='PhD',
            experience_years=10.0,
            emergency_contact_name='Jane Doe',
            emergency_contact_phone='+1234567891',
            emergency_contact_relationship='Spouse'
        )
        
        self.performance = FacultyPerformance.objects.create(
            faculty=self.faculty,
            academic_year='2023-2024',
            evaluation_period='Q1',
            teaching_effectiveness=8.5,
            student_satisfaction=8.0,
            research_contribution=7.5,
            administrative_work=8.0,
            professional_development=8.5,
            evaluation_date=date(2023, 10, 1),
            evaluated_by=self.user
        )
    
    def test_performance_creation(self):
        """Test performance creation"""
        self.assertEqual(self.performance.academic_year, '2023-2024')
        self.assertEqual(self.performance.evaluation_period, 'Q1')
        self.assertEqual(self.performance.overall_score, 8.1)  # Average of all scores
    
    def test_performance_str_representation(self):
        """Test performance string representation"""
        expected = 'John Doe - 2023-2024 Q1'
        self.assertEqual(str(self.performance), expected)


class FacultyAPITest(APITestCase):
    """Test cases for Faculty API endpoints"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='admin@test.com',
            username='admin',
            password='adminpass123',
            is_staff=True,
            is_superuser=True
        )
        self.client.force_authenticate(user=self.user)
        
        self.faculty_data = {
            'name': 'John Doe',
            'apaar_faculty_id': 'APAAR001',
            'employee_id': 'EMP001',
            'first_name': 'John',
            'last_name': 'Doe',
            'date_of_birth': '1980-01-01',
            'gender': 'M',
            'designation': 'PROFESSOR',
            'department': 'COMPUTER_SCIENCE',
            'employment_type': 'FULL_TIME',
            'date_of_joining': '2020-01-01',
            'date_of_joining_institution': '2020-01-01',
            'designation_at_joining': 'Assistant Professor',
            'present_designation': 'Professor',
            'nature_of_association': 'REGULAR',
            'currently_associated': True,
            'experience_in_current_institute': 3.0,
            'phone_number': '+1234567890',
            'address_line_1': '123 Test Street',
            'city': 'Test City',
            'state': 'Test State',
            'postal_code': '12345',
            'highest_qualification': 'PhD',
            'experience_years': 10.0,
            'emergency_contact_name': 'Jane Doe',
            'emergency_contact_phone': '+1234567891',
            'emergency_contact_relationship': 'Spouse',
            'email': 'john.doe@test.com'
        }
    
    def test_create_faculty(self):
        """Test creating a new faculty member"""
        url = reverse('faculty:faculty-list')
        response = self.client.post(url, self.faculty_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Faculty.objects.count(), 1)
    
    def test_list_faculty(self):
        """Test listing faculty members"""
        # Create a faculty member first
        Faculty.objects.create(
            user=self.user,
            name='John Doe',
            apaar_faculty_id='APAAR001',
            employee_id='EMP001',
            first_name='John',
            last_name='Doe',
            date_of_birth=date(1980, 1, 1),
            gender='M',
            designation='PROFESSOR',
            department='COMPUTER_SCIENCE',
            employment_type='FULL_TIME',
            date_of_joining=date(2020, 1, 1),
            date_of_joining_institution=date(2020, 1, 1),
            designation_at_joining='Assistant Professor',
            present_designation='Professor',
            nature_of_association='REGULAR',
            currently_associated=True,
            experience_in_current_institute=3.0,
            email='john.doe@test.com',
            phone_number='+1234567890',
            address_line_1='123 Test Street',
            city='Test City',
            state='Test State',
            postal_code='12345',
            highest_qualification='PhD',
            experience_years=10.0,
            emergency_contact_name='Jane Doe',
            emergency_contact_phone='+1234567891',
            emergency_contact_relationship='Spouse'
        )
        
        url = reverse('faculty:faculty-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
    
    def test_get_faculty_statistics(self):
        """Test getting faculty statistics"""
        url = reverse('faculty:faculty-statistics')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_faculty', response.data)
        self.assertIn('active_faculty', response.data)
