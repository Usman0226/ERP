from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.utils import timezone
from datetime import datetime, timedelta
import json

from .models import (
    APICollection, APIEnvironment, APIRequest, APITest, APITestResult,
    APITestSuite, APITestSuiteResult, APIAutomation
)
from .serializers import (
    APICollectionSerializer, APIEnvironmentSerializer, APIRequestSerializer,
    APITestSerializer, APITestResultSerializer, APITestSuiteSerializer,
    APITestSuiteResultSerializer, APIAutomationSerializer,
    APICollectionDetailSerializer, APIRequestDetailSerializer,
    APITestDetailSerializer, APITestSuiteDetailSerializer
)
from .api_testing_service import APITestingService

class APICollectionViewSet(viewsets.ModelViewSet):
    queryset = APICollection.objects.all()
    serializer_class = APICollectionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return APICollection.objects.filter(
            created_by=self.request.user
        ).order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return APICollectionDetailSerializer
        return APICollectionSerializer
    
    @action(detail=True, methods=['post'])
    def duplicate(self, request, pk=None):
        """Duplicate a collection with all its requests and tests"""
        collection = self.get_object()
        
        with transaction.atomic():
            # Create new collection
            new_collection = APICollection.objects.create(
                name=f"{collection.name} (Copy)",
                description=collection.description,
                created_by=request.user,
                is_public=collection.is_public,
                base_url=collection.base_url
            )
            
            # Duplicate requests
            for request in collection.requests.all():
                new_request = APIRequest.objects.create(
                    name=request.name,
                    description=request.description,
                    collection=new_collection,
                    method=request.method,
                    url=request.url,
                    headers=request.headers,
                    body=request.body,
                    body_type=request.body_type,
                    params=request.params,
                    auth_type=request.auth_type,
                    auth_config=request.auth_config,
                    timeout=request.timeout,
                    order=request.order
                )
                
                # Duplicate tests
                for test in request.tests.all():
                    APITest.objects.create(
                        name=test.name,
                        description=test.description,
                        request=new_request,
                        test_script=test.test_script,
                        assertions=test.assertions,
                        pre_request_script=test.pre_request_script,
                        enabled=test.enabled
                    )
        
        return Response({
            'message': 'Collection duplicated successfully',
            'new_collection_id': new_collection.id
        })

class APIEnvironmentViewSet(viewsets.ModelViewSet):
    queryset = APIEnvironment.objects.all()
    serializer_class = APIEnvironmentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return APIEnvironment.objects.filter(
            created_by=self.request.user
        ).order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=True, methods=['post'])
    def set_default(self, request, pk=None):
        """Set this environment as the default"""
        environment = self.get_object()
        
        # Remove default from other environments
        APIEnvironment.objects.filter(
            created_by=request.user,
            is_default=True
        ).update(is_default=False)
        
        # Set this as default
        environment.is_default = True
        environment.save()
        
        return Response({'message': 'Default environment updated'})

class APIRequestViewSet(viewsets.ModelViewSet):
    queryset = APIRequest.objects.all()
    serializer_class = APIRequestSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return APIRequest.objects.filter(
            collection__created_by=self.request.user
        ).order_by('collection__name', 'order')
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return APIRequestDetailSerializer
        return APIRequestSerializer
    
    @action(detail=True, methods=['post'])
    def execute(self, request, pk=None):
        """Execute a single request"""
        api_request = self.get_object()
        environment_id = request.data.get('environment_id')
        
        environment = None
        if environment_id:
            environment = get_object_or_404(
                APIEnvironment,
                id=environment_id,
                created_by=request.user
            )
        
        service = APITestingService(environment)
        response_data = service.execute_request(api_request)
        
        return Response(response_data)
    
    @action(detail=True, methods=['post'])
    def duplicate(self, request, pk=None):
        """Duplicate a request with its tests"""
        api_request = self.get_object()
        
        with transaction.atomic():
            new_request = APIRequest.objects.create(
                name=f"{api_request.name} (Copy)",
                description=api_request.description,
                collection=api_request.collection,
                method=api_request.method,
                url=api_request.url,
                headers=api_request.headers,
                body=api_request.body,
                body_type=api_request.body_type,
                params=api_request.params,
                auth_type=api_request.auth_type,
                auth_config=api_request.auth_config,
                timeout=api_request.timeout,
                order=api_request.order + 1
            )
            
            # Duplicate tests
            for test in api_request.tests.all():
                APITest.objects.create(
                    name=test.name,
                    description=test.description,
                    request=new_request,
                    test_script=test.test_script,
                    assertions=test.assertions,
                    pre_request_script=test.pre_request_script,
                    enabled=test.enabled
                )
        
        return Response({
            'message': 'Request duplicated successfully',
            'new_request_id': new_request.id
        })

class APITestViewSet(viewsets.ModelViewSet):
    queryset = APITest.objects.all()
    serializer_class = APITestSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return APITest.objects.filter(
            request__collection__created_by=self.request.user
        ).order_by('request__collection__name', 'request__order', 'name')
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return APITestDetailSerializer
        return APITestSerializer
    
    @action(detail=True, methods=['post'])
    def run(self, request, pk=None):
        """Run a single test"""
        test = self.get_object()
        environment_id = request.data.get('environment_id')
        
        environment = None
        if environment_id:
            environment = get_object_or_404(
                APIEnvironment,
                id=environment_id,
                created_by=request.user
            )
        
        service = APITestingService(environment)
        test_result = service.run_test(test)
        
        serializer = APITestResultSerializer(test_result)
        return Response(serializer.data)

class APITestResultViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = APITestResult.objects.all()
    serializer_class = APITestResultSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return APITestResult.objects.filter(
            test__request__collection__created_by=self.request.user
        ).order_by('-executed_at')
    
    @action(detail=False, methods=['get'])
    def recent(self, request):
        """Get recent test results"""
        limit = int(request.query_params.get('limit', 50))
        results = self.get_queryset()[:limit]
        serializer = self.get_serializer(results, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """Get test result statistics"""
        queryset = self.get_queryset()
        
        total_results = queryset.count()
        passed_results = queryset.filter(status='passed').count()
        failed_results = queryset.filter(status='failed').count()
        error_results = queryset.filter(status='error').count()
        
        # Average response time
        from django.db.models import Avg
        avg_response_time = queryset.exclude(
            response_time__isnull=True
        ).aggregate(
            avg_time=Avg('response_time')
        )['avg_time'] or 0
        
        return Response({
            'total_results': total_results,
            'passed_results': passed_results,
            'failed_results': failed_results,
            'error_results': error_results,
            'success_rate': (passed_results / total_results * 100) if total_results > 0 else 0,
            'average_response_time': round(avg_response_time, 2)
        })

class APITestSuiteViewSet(viewsets.ModelViewSet):
    queryset = APITestSuite.objects.all()
    serializer_class = APITestSuiteSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return APITestSuite.objects.filter(
            collection__created_by=self.request.user
        ).order_by('-created_at')
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return APITestSuiteDetailSerializer
        return APITestSuiteSerializer
    
    @action(detail=True, methods=['post'])
    def run(self, request, pk=None):
        """Run a complete test suite"""
        test_suite = self.get_object()
        environment_id = request.data.get('environment_id')
        
        environment = None
        if environment_id:
            environment = get_object_or_404(
                APIEnvironment,
                id=environment_id,
                created_by=request.user
            )
        
        # Create suite result
        suite_result = APITestSuiteResult.objects.create(
            suite=test_suite,
            environment=environment,
            status='running'
        )
        
        try:
            service = APITestingService(environment)
            results = service.run_test_suite(test_suite)
            
            # Update suite result
            suite_result.total_tests = results['total_tests']
            suite_result.passed_tests = results['passed_tests']
            suite_result.failed_tests = results['failed_tests']
            suite_result.total_time = results['total_time']
            suite_result.completed_at = timezone.now()
            suite_result.status = 'completed' if results['failed_tests'] == 0 else 'failed'
            
            # Add individual results
            suite_result.results.set(results['results'])
            suite_result.save()
            
            serializer = APITestSuiteResultSerializer(suite_result)
            return Response(serializer.data)
            
        except Exception as e:
            suite_result.status = 'failed'
            suite_result.completed_at = timezone.now()
            suite_result.save()
            
            return Response({
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class APITestSuiteResultViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = APITestSuiteResult.objects.all()
    serializer_class = APITestSuiteResultSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return APITestSuiteResult.objects.filter(
            suite__collection__created_by=self.request.user
        ).order_by('-started_at')

class APIAutomationViewSet(viewsets.ModelViewSet):
    queryset = APIAutomation.objects.all()
    serializer_class = APIAutomationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return APIAutomation.objects.filter(
            test_suite__collection__created_by=self.request.user
        ).order_by('-created_at')
    
    @action(detail=True, methods=['post'])
    def toggle(self, request, pk=None):
        """Toggle automation on/off"""
        automation = self.get_object()
        automation.is_active = not automation.is_active
        automation.save()
        
        return Response({
            'message': f'Automation {"activated" if automation.is_active else "deactivated"}',
            'is_active': automation.is_active
        })
    
    @action(detail=True, methods=['post'])
    def run_now(self, request, pk=None):
        """Run automation immediately"""
        automation = self.get_object()
        
        # Create a temporary suite result
        suite_result = APITestSuiteResult.objects.create(
            suite=automation.test_suite,
            environment=automation.test_suite.environment,
            status='running'
        )
        
        try:
            service = APITestingService(automation.test_suite.environment)
            results = service.run_test_suite(automation.test_suite)
            
            # Update suite result
            suite_result.total_tests = results['total_tests']
            suite_result.passed_tests = results['passed_tests']
            suite_result.failed_tests = results['failed_tests']
            suite_result.total_time = results['total_time']
            suite_result.completed_at = timezone.now()
            suite_result.status = 'completed' if results['failed_tests'] == 0 else 'failed'
            suite_result.results.set(results['results'])
            suite_result.save()
            
            # Update automation last run
            automation.last_run = timezone.now()
            automation.save()
            
            return Response({
                'message': 'Automation executed successfully',
                'suite_result_id': suite_result.id,
                'results': {
                    'total_tests': results['total_tests'],
                    'passed_tests': results['passed_tests'],
                    'failed_tests': results['failed_tests'],
                    'total_time': results['total_time']
                }
            })
            
        except Exception as e:
            suite_result.status = 'failed'
            suite_result.completed_at = timezone.now()
            suite_result.save()
            
            return Response({
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
