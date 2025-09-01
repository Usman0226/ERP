from rest_framework import serializers
from .models import Student, StudentEnrollmentHistory, StudentDocument, CustomField, StudentCustomFieldValue

# Import API serializers
from .api_serializers import (
    StudentSerializer as APIStudentSerializer,
    StudentDetailSerializer as APIStudentDetailSerializer,
    StudentEnrollmentHistorySerializer as APIStudentEnrollmentHistorySerializer,
    StudentDocumentSerializer as APIStudentDocumentSerializer,
    CustomFieldSerializer as APICustomFieldSerializer,
    StudentCustomFieldValueSerializer as APIStudentCustomFieldValueSerializer,
    StudentImportSerializer as APIStudentImportSerializer,
    StudentStatsSerializer as APIStudentStatsSerializer
)


class StudentSerializer(serializers.ModelSerializer):
    """Serializer for Student model"""
    full_name = serializers.ReadOnlyField()
    age = serializers.ReadOnlyField()
    full_address = serializers.ReadOnlyField()
    
    class Meta:
        model = Student
        fields = [
            'id', 'roll_number', 'first_name', 'last_name', 'middle_name',
            'full_name', 'date_of_birth', 'age', 'gender', 'email', 
            'student_mobile', 'address_line1', 'address_line2', 'city', 
            'state', 'postal_code', 'country', 'full_address', 'grade_level',
            'section', 'academic_year', 'quota', 'rank', 'village',
            'aadhar_number', 'religion', 'caste', 'subcaste',
            'father_name', 'mother_name', 'father_mobile', 'mother_mobile',
            'enrollment_date', 'expected_graduation_date', 'status',
            'guardian_name', 'guardian_phone', 'guardian_email', 
            'guardian_relationship', 'emergency_contact_name', 
            'emergency_contact_phone', 'emergency_contact_relationship',
            'medical_conditions', 'medications', 'notes', 'profile_picture',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def validate_roll_number(self, value):
        """Validate that roll_number is unique"""
        if Student.objects.filter(roll_number=value).exists():
            raise serializers.ValidationError("Roll number must be unique.")
        return value
    
    def validate_email(self, value):
        """Validate that email is unique if provided"""
        if value and Student.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email must be unique.")
        return value


class StudentCreateSerializer(StudentSerializer):
    """Serializer for creating new students with required fields"""
    
    class Meta(StudentSerializer.Meta):
        fields = StudentSerializer.Meta.fields
        read_only_fields = ['id', 'created_at', 'updated_at', 'full_name', 'age', 'full_address']
    
    def validate(self, data):
        """Validate required fields for student creation"""
        required_fields = ['roll_number', 'first_name', 'last_name', 'date_of_birth', 'gender', 'grade_level']
        for field in required_fields:
            if not data.get(field):
                raise serializers.ValidationError(f"{field.replace('_', ' ').title()} is required.")
        return data


class StudentUpdateSerializer(StudentSerializer):
    """Serializer for updating existing students"""
    
    class Meta(StudentSerializer.Meta):
        fields = StudentSerializer.Meta.fields
        read_only_fields = ['id', 'roll_number', 'created_at', 'updated_at', 'full_name', 'age', 'full_address']
    
    def validate_email(self, value):
        """Validate that email is unique if provided, excluding current instance"""
        if value:
            queryset = Student.objects.filter(email=value)
            if self.instance:
                queryset = queryset.exclude(pk=self.instance.pk)
            if queryset.exists():
                raise serializers.ValidationError("Email must be unique.")
        return value


class StudentListSerializer(serializers.ModelSerializer):
    """Simplified serializer for listing students"""
    full_name = serializers.ReadOnlyField()
    age = serializers.ReadOnlyField()
    
    class Meta:
        model = Student
        fields = [
            'id', 'roll_number', 'full_name', 'age', 'gender', 'email',
            'grade_level', 'section', 'status', 'enrollment_date', 'created_at'
        ]


class StudentEnrollmentHistorySerializer(serializers.ModelSerializer):
    """Serializer for Student Enrollment History"""
    student_name = serializers.CharField(source='student.full_name', read_only=True)
    
    class Meta:
        model = StudentEnrollmentHistory
        fields = [
            'id', 'student', 'student_name', 'grade_level', 'academic_year',
            'enrollment_date', 'completion_date', 'status', 'notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class StudentDocumentSerializer(serializers.ModelSerializer):
    """Serializer for Student Documents"""
    student_name = serializers.CharField(source='student.full_name', read_only=True)
    uploaded_by_name = serializers.CharField(source='uploaded_by.email', read_only=True)
    
    class Meta:
        model = StudentDocument
        fields = [
            'id', 'student', 'student_name', 'document_type', 'title',
            'description', 'document_file', 'uploaded_by', 'uploaded_by_name',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'uploaded_by', 'created_at', 'updated_at']


class StudentDetailSerializer(StudentSerializer):
    """Detailed serializer for student with related data"""
    enrollment_history = StudentEnrollmentHistorySerializer(many=True, read_only=True)
    documents = StudentDocumentSerializer(many=True, read_only=True)
    
    class Meta(StudentSerializer.Meta):
        fields = StudentSerializer.Meta.fields + ['enrollment_history', 'documents']


class CustomFieldSerializer(serializers.ModelSerializer):
    """Serializer for Custom Field model"""
    
    class Meta:
        model = CustomField
        fields = [
            'id', 'name', 'label', 'field_type', 'required', 'help_text',
            'default_value', 'choices', 'validation_regex', 'min_value',
            'max_value', 'is_active', 'order', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class StudentCustomFieldValueSerializer(serializers.ModelSerializer):
    """Serializer for Student Custom Field Values"""
    custom_field = CustomFieldSerializer(read_only=True)
    custom_field_id = serializers.UUIDField(write_only=True)
    
    class Meta:
        model = StudentCustomFieldValue
        fields = [
            'id', 'custom_field', 'custom_field_id', 'value', 'file_value',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class StudentWithCustomFieldsSerializer(StudentSerializer):
    """Serializer for Student with custom field values"""
    custom_field_values = StudentCustomFieldValueSerializer(many=True, read_only=True)
    
    class Meta(StudentSerializer.Meta):
        fields = StudentSerializer.Meta.fields + ['custom_field_values']
