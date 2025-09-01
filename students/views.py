from django.shortcuts import render, get_object_or_404
from django.db.models import Q
from rest_framework import status, viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth import get_user_model

from .models import Student, StudentEnrollmentHistory, StudentDocument, CustomField, StudentCustomFieldValue
from .serializers import (
    StudentSerializer, StudentCreateSerializer, StudentUpdateSerializer,
    StudentListSerializer, StudentDetailSerializer, StudentEnrollmentHistorySerializer,
    StudentDocumentSerializer, CustomFieldSerializer, StudentCustomFieldValueSerializer,
    StudentWithCustomFieldsSerializer
)

User = get_user_model()


class StudentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing students
    Provides CRUD operations for students
    """
    queryset = Student.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.action == 'create':
            return StudentCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return StudentUpdateSerializer
        elif self.action == 'list':
            return StudentListSerializer
        elif self.action == 'retrieve':
            return StudentDetailSerializer
        return StudentSerializer
    
    def get_queryset(self):
        """Filter queryset based on query parameters"""
        queryset = Student.objects.all()
        
        # Search functionality
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(first_name__icontains=search) |
                Q(last_name__icontains=search) |
                Q(roll_number__icontains=search) |
                Q(email__icontains=search) |
                Q(father_name__icontains=search) |
                Q(mother_name__icontains=search)
            )
        
        # Filter by status
        status_filter = self.request.query_params.get('status', None)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by grade level
        grade_filter = self.request.query_params.get('grade_level', None)
        if grade_filter:
            queryset = queryset.filter(grade_level=grade_filter)
        
        # Filter by gender
        gender_filter = self.request.query_params.get('gender', None)
        if gender_filter:
            queryset = queryset.filter(gender=gender_filter)
        
        # Filter by section
        section_filter = self.request.query_params.get('section', None)
        if section_filter:
            queryset = queryset.filter(section=section_filter)
        
        # Filter by quota
        quota_filter = self.request.query_params.get('quota', None)
        if quota_filter:
            queryset = queryset.filter(quota=quota_filter)
        
        # Filter by religion
        religion_filter = self.request.query_params.get('religion', None)
        if religion_filter:
            queryset = queryset.filter(religion=religion_filter)
        
        return queryset.order_by('last_name', 'first_name')
    
    def perform_create(self, serializer):
        """Set created_by field when creating a student"""
        serializer.save(created_by=self.request.user)
    
    def perform_update(self, serializer):
        """Set updated_by field when updating a student"""
        serializer.save(updated_by=self.request.user)
    
    @action(detail=True, methods=['get'])
    def enrollment_history(self, request, pk=None):
        """Get enrollment history for a specific student"""
        student = self.get_object()
        history = student.enrollment_history.all()
        serializer = StudentEnrollmentHistorySerializer(history, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def add_enrollment(self, request, pk=None):
        """Add enrollment history entry for a student"""
        student = self.get_object()
        serializer = StudentEnrollmentHistorySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(student=student)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['get'])
    def documents(self, request, pk=None):
        """Get documents for a specific student"""
        student = self.get_object()
        documents = student.documents.all()
        serializer = StudentDocumentSerializer(documents, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def upload_document(self, request, pk=None):
        """Upload a document for a student"""
        student = self.get_object()
        serializer = StudentDocumentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(student=student, uploaded_by=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """Get student statistics"""
        total_students = Student.objects.count()
        active_students = Student.objects.filter(status='ACTIVE').count()
        inactive_students = Student.objects.filter(status='INACTIVE').count()
        graduated_students = Student.objects.filter(status='GRADUATED').count()
        
        # Students by grade level
        grade_stats = {}
        for grade, _ in Student.GRADE_CHOICES:
            grade_stats[f'grade_{grade}'] = Student.objects.filter(grade_level=grade).count()
        
        # Students by gender
        gender_stats = {}
        for gender, _ in Student.GENDER_CHOICES:
            gender_stats[gender] = Student.objects.filter(gender=gender).count()
        
        stats = {
            'total_students': total_students,
            'active_students': active_students,
            'inactive_students': inactive_students,
            'graduated_students': graduated_students,
            'grade_distribution': grade_stats,
            'gender_distribution': gender_stats
        }
        
        return Response(stats)
    
    @action(detail=True, methods=['patch'])
    def change_status(self, request, pk=None):
        """Change student status"""
        student = self.get_object()
        new_status = request.data.get('status')
        
        if new_status not in [choice[0] for choice in Student.STATUS_CHOICES]:
            return Response(
                {'error': 'Invalid status'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        student.status = new_status
        student.updated_by = request.user
        student.save()
        
        serializer = StudentSerializer(student)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def custom_fields(self, request, pk=None):
        """Get custom field values for a specific student"""
        student = self.get_object()
        custom_values = student.custom_field_values.all()
        serializer = StudentCustomFieldValueSerializer(custom_values, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def set_custom_field(self, request, pk=None):
        """Set a custom field value for a student"""
        student = self.get_object()
        custom_field_id = request.data.get('custom_field_id')
        value = request.data.get('value')
        file_value = request.FILES.get('file_value')
        
        if not custom_field_id:
            return Response(
                {'error': 'custom_field_id is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            custom_field = CustomField.objects.get(id=custom_field_id, is_active=True)
        except CustomField.DoesNotExist:
            return Response(
                {'error': 'Custom field not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Create or update the custom field value
        custom_value, created = StudentCustomFieldValue.objects.get_or_create(
            student=student,
            custom_field=custom_field,
            defaults={'value': value, 'file_value': file_value}
        )
        
        if not created:
            custom_value.value = value
            if file_value:
                custom_value.file_value = file_value
            custom_value.save()
        
        serializer = StudentCustomFieldValueSerializer(custom_value)
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def available_custom_fields(self, request):
        """Get all available custom fields"""
        custom_fields = CustomField.objects.filter(is_active=True)
        serializer = CustomFieldSerializer(custom_fields, many=True)
        return Response(serializer.data)


class StudentEnrollmentHistoryViewSet(viewsets.ModelViewSet):
    """ViewSet for managing student enrollment history"""
    queryset = StudentEnrollmentHistory.objects.all()
    serializer_class = StudentEnrollmentHistorySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Filter by student if provided"""
        queryset = StudentEnrollmentHistory.objects.all()
        student_id = self.request.query_params.get('student', None)
        if student_id:
            queryset = queryset.filter(student_id=student_id)
        return queryset.order_by('-enrollment_date')


class StudentDocumentViewSet(viewsets.ModelViewSet):
    """ViewSet for managing student documents"""
    queryset = StudentDocument.objects.all()
    serializer_class = StudentDocumentSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_queryset(self):
        """Filter by student if provided"""
        queryset = StudentDocument.objects.all()
        student_id = self.request.query_params.get('student', None)
        if student_id:
            queryset = queryset.filter(student_id=student_id)
        
        document_type = self.request.query_params.get('document_type', None)
        if document_type:
            queryset = queryset.filter(document_type=document_type)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        """Set uploaded_by field when creating a document"""
        serializer.save(uploaded_by=self.request.user)


class CustomFieldViewSet(viewsets.ModelViewSet):
    """ViewSet for managing custom fields"""
    queryset = CustomField.objects.filter(is_active=True)
    serializer_class = CustomFieldSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Filter by field type if provided"""
        queryset = CustomField.objects.filter(is_active=True)
        field_type = self.request.query_params.get('field_type', None)
        if field_type:
            queryset = queryset.filter(field_type=field_type)
        return queryset.order_by('order', 'name')


class StudentCustomFieldValueViewSet(viewsets.ModelViewSet):
    """ViewSet for managing student custom field values"""
    queryset = StudentCustomFieldValue.objects.all()
    serializer_class = StudentCustomFieldValueSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_queryset(self):
        """Filter by student if provided"""
        queryset = StudentCustomFieldValue.objects.all()
        student_id = self.request.query_params.get('student', None)
        if student_id:
            queryset = queryset.filter(student_id=student_id)
        
        custom_field_id = self.request.query_params.get('custom_field', None)
        if custom_field_id:
            queryset = queryset.filter(custom_field_id=custom_field_id)
        
        return queryset.order_by('custom_field__order', 'custom_field__name')


# Additional utility views for frontend
def student_dashboard(request):
    """Dashboard view for student management"""
    if not request.user.is_authenticated:
        return render(request, 'registration/login.html')
    
    context = {
        'total_students': Student.objects.count(),
        'active_students': Student.objects.filter(status='ACTIVE').count(),
        'recent_students': Student.objects.order_by('-created_at')[:5]
    }
    return render(request, 'students/dashboard.html', context)


def student_list_view(request):
    """List view for students"""
    if not request.user.is_authenticated:
        return render(request, 'registration/login.html')
    
    students = Student.objects.all().order_by('last_name', 'first_name')
    
    # Handle search
    search_query = request.GET.get('search', '')
    if search_query:
        students = students.filter(
            Q(first_name__icontains=search_query) |
            Q(last_name__icontains=search_query) |
            Q(student_id__icontains=search_query) |
            Q(email__icontains=search_query)
        )
    
    context = {
        'students': students,
        'search_query': search_query
    }
    return render(request, 'students/student_list.html', context)


def student_detail_view(request, student_id):
    """Detail view for a specific student"""
    if not request.user.is_authenticated:
        return render(request, 'registration/login.html')
    
    student = get_object_or_404(Student, pk=student_id)
    context = {
        'student': student,
        'enrollment_history': student.enrollment_history.all(),
        'documents': student.documents.all()
    }
    return render(request, 'students/student_detail.html', context)
