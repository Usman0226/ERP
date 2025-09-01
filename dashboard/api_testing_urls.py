from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .api_testing_views import (
    APICollectionViewSet, APIEnvironmentViewSet, APIRequestViewSet,
    APITestViewSet, APITestResultViewSet, APITestSuiteViewSet,
    APITestSuiteResultViewSet, APIAutomationViewSet
)

# Create router and register viewsets
router = DefaultRouter()
router.register(r'collections', APICollectionViewSet, basename='api-collection')
router.register(r'environments', APIEnvironmentViewSet, basename='api-environment')
router.register(r'requests', APIRequestViewSet, basename='api-request')
router.register(r'tests', APITestViewSet, basename='api-test')
router.register(r'test-results', APITestResultViewSet, basename='api-test-result')
router.register(r'test-suites', APITestSuiteViewSet, basename='api-test-suite')
router.register(r'test-suite-results', APITestSuiteResultViewSet, basename='api-test-suite-result')
router.register(r'automations', APIAutomationViewSet, basename='api-automation')

app_name = 'api_testing'

urlpatterns = [
    # Include router URLs
    path('', include(router.urls)),
]
