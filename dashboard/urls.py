from django.urls import path, include
from django.contrib.auth import views as auth_views
from . import views

app_name = 'dashboard'

urlpatterns = [
    # Auth
    path('login/', auth_views.LoginView.as_view(template_name='dashboard/login.html'), name='login'),
    path('logout/', auth_views.LogoutView.as_view(next_page='dashboard:login'), name='logout'),

    # Dashboard pages
    path('', views.dashboard_home, name='home'),
    path('users/', views.users_list, name='users'),
    path('roles/', views.roles_list, name='roles'),
    path('sessions/', views.sessions_list, name='sessions'),
    path('audit/', views.audit_logs, name='audit'),
    path('schema/', views.database_schema, name='schema'),
    path('schema/excel/', views.download_schema_excel, name='schema_excel'),
    path('schema/excel-single/', views.download_schema_excel_single, name='schema_excel_single'),
    path('schema/csv/', views.download_schema_csv, name='schema_csv'),
    path('er/', views.er_diagram_page, name='er'),
    
    # Student Management
    path('students/', views.students_list, name='students'),
    path('students/<uuid:student_id>/', views.student_detail, name='student_detail'),
    path('custom-fields/', views.custom_fields_list, name='custom_fields'),
    path('student-login/', views.student_login_page, name='student_login'),
    path('student-sessions/', views.student_sessions, name='student_sessions'),
    path('student-import/', views.student_import_page, name='student_import'),
    path('student-import/process/', views.student_import_process, name='student_import_process'),
    path('download-template/', views.download_template, name='download_template'),
    
    # Faculty Management
    path('faculty/', views.faculty_list, name='faculty'),
    path('faculty/<uuid:faculty_id>/', views.faculty_detail, name='faculty_detail'),
    path('faculty/performance/', views.faculty_performance_stats, name='faculty_performance'),
    path('faculty/leaves/', views.faculty_leave_stats, name='faculty_leaves'),
    path('faculty/documents/', views.faculty_document_list, name='faculty_documents'),
    path('faculty/custom-fields/', views.faculty_custom_fields_list, name='faculty_custom_fields'),
    path('faculty/custom-fields/create/', views.faculty_custom_field_create, name='faculty_custom_field_create'),
    path('faculty/custom-fields/<uuid:field_id>/update/', views.faculty_custom_field_update, name='faculty_custom_field_update'),
    path('faculty/custom-fields/<uuid:field_id>/delete/', views.faculty_custom_field_delete, name='faculty_custom_field_delete'),
    
    # API endpoints
    path('api/schema/', views.api_database_schema, name='api_schema'),
    path('api/table/<str:table_name>/', views.api_table_data, name='api_table_data'),
    path('api/stats/', views.api_dashboard_stats, name='api_stats'),
    path('api/models/', views.api_models_info, name='api_models'),
    path('api/er/', views.api_er_diagram, name='api_er'),
    path('test-openpyxl/', views.test_openpyxl, name='test_openpyxl'),
    
    # API Testing
    path('api-testing/', include('dashboard.api_testing_urls', namespace='api_testing')),
    
    # API Testing Dashboard Pages
    path('api-testing-dashboard/', views.api_testing_dashboard, name='api_testing_dashboard'),
    path('api-testing/collections/', views.api_collections_list, name='api_collections_list'),
    path('api-testing/collections/<uuid:collection_id>/', views.api_collection_detail, name='api_collection_detail'),
    path('api-testing/collections/<uuid:collection_id>/detail/', views.api_collection_detail_view, name='api_collection_detail_view'),
    path('api-testing/collections/<uuid:collection_id>/update/', views.api_collection_update_view, name='api_collection_update_view'),
    path('api-testing/collections/<uuid:collection_id>/duplicate/', views.api_collection_duplicate_view, name='api_collection_duplicate_view'),
    path('api-testing/collections/<uuid:collection_id>/delete/', views.api_collection_delete_view, name='api_collection_delete_view'),
    path('api-testing/environments/', views.api_environments_list, name='api_environments_list'),
    path('api-testing/environments/<uuid:environment_id>/detail/', views.api_environment_detail_view, name='api_environment_detail_view'),
    path('api-testing/environments/<uuid:environment_id>/update/', views.api_environment_update_view, name='api_environment_update_view'),
    path('api-testing/environments/<uuid:environment_id>/duplicate/', views.api_environment_duplicate_view, name='api_environment_duplicate_view'),
    path('api-testing/environments/<uuid:environment_id>/set-default/', views.api_environment_set_default_view, name='api_environment_set_default_view'),
    path('api-testing/environments/<uuid:environment_id>/delete/', views.api_environment_delete_view, name='api_environment_delete_view'),
    path('api-testing/requests/', views.api_requests_list, name='api_requests_list'),
    path('api-testing/requests/<uuid:request_id>/', views.api_request_detail, name='api_request_detail'),
    path('api-testing/tests/', views.api_tests_list, name='api_tests_list'),
    path('api-testing/tests/<uuid:test_id>/', views.api_test_detail, name='api_test_detail'),
    path('api-testing/test-results/', views.api_test_results_list, name='api_test_results_list'),
    path('api-testing/test-suites/', views.api_test_suites_list, name='api_test_suites_list'),
    path('api-testing/test-suites/<uuid:suite_id>/', views.api_test_suite_detail, name='api_test_suite_detail'),
    path('api-testing/automations/', views.api_automations_list, name='api_automations_list'),
    path('api-testing/automations/<uuid:automation_id>/', views.api_automation_detail, name='api_automation_detail'),
    path('api-testing/workspace/', views.api_testing_workspace, name='api_testing_workspace'),
    path('api-testing/simple/', views.simple_api_workspace, name='simple_api_workspace'),
]
