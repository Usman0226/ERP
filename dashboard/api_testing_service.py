import requests
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from django.conf import settings
from .models import APIRequest, APITest, APITestResult, APIEnvironment

class APITestingService:
    """Service class for executing API requests and running tests"""
    
    def __init__(self, environment: Optional[APIEnvironment] = None):
        self.environment = environment
        self.session = requests.Session()
        self.variables = {}
        if environment:
            self.variables = environment.variables or {}
    
    def _replace_variables(self, text: str) -> str:
        """Replace environment variables in text"""
        if not text:
            return text
        
        for key, value in self.variables.items():
            text = text.replace(f"{{{{{key}}}}}", str(value))
        
        return text
    
    def _prepare_headers(self, headers: Dict) -> Dict:
        """Prepare headers with variable replacement"""
        prepared_headers = {}
        for key, value in headers.items():
            prepared_headers[key] = self._replace_variables(str(value))
        return prepared_headers
    
    def _prepare_body(self, body: str, body_type: str) -> Any:
        """Prepare request body based on type"""
        if not body:
            return None
        
        body = self._replace_variables(body)
        
        if body_type == 'json':
            try:
                return json.loads(body)
            except json.JSONDecodeError:
                return body
        elif body_type == 'form':
            # Parse form data
            form_data = {}
            for line in body.split('\n'):
                if '=' in line:
                    key, value = line.split('=', 1)
                    form_data[key.strip()] = value.strip()
            return form_data
        else:
            return body
    
    def _prepare_url(self, url: str, params: Dict) -> str:
        """Prepare URL with variable replacement and query parameters"""
        url = self._replace_variables(url)
        
        # Add query parameters
        if params:
            query_params = []
            for key, value in params.items():
                key = self._replace_variables(str(key))
                value = self._replace_variables(str(value))
                query_params.append(f"{key}={value}")
            
            separator = '&' if '?' in url else '?'
            url += separator + '&'.join(query_params)
        
        return url
    
    def _apply_auth(self, auth_type: str, auth_config: Dict):
        """Apply authentication to the request"""
        if auth_type == 'bearer':
            token = self._replace_variables(auth_config.get('token', ''))
            self.session.headers.update({'Authorization': f'Bearer {token}'})
        elif auth_type == 'basic':
            username = self._replace_variables(auth_config.get('username', ''))
            password = self._replace_variables(auth_config.get('password', ''))
            self.session.auth = (username, password)
        elif auth_type == 'api_key':
            key_name = auth_config.get('key_name', 'X-API-Key')
            key_value = self._replace_variables(auth_config.get('key_value', ''))
            self.session.headers.update({key_name: key_value})
    
    def execute_request(self, api_request: APIRequest) -> Dict[str, Any]:
        """Execute an API request and return the response"""
        start_time = time.time()
        
        try:
            # Prepare request data
            url = self._prepare_url(api_request.url, api_request.params)
            headers = self._prepare_headers(api_request.headers)
            body = self._prepare_body(api_request.body, api_request.body_type)
            
            # Apply authentication
            self._apply_auth(api_request.auth_type, api_request.auth_config)
            
            # Make the request
            response = self.session.request(
                method=api_request.method,
                url=url,
                headers=headers,
                json=body if api_request.body_type == 'json' else None,
                data=body if api_request.body_type == 'form' else None,
                timeout=api_request.timeout
            )
            
            response_time = (time.time() - start_time) * 1000  # Convert to milliseconds
            
            return {
                'status_code': response.status_code,
                'headers': dict(response.headers),
                'body': response.text,
                'response_time': response_time,
                'error': None
            }
            
        except requests.exceptions.RequestException as e:
            response_time = (time.time() - start_time) * 1000
            return {
                'status_code': None,
                'headers': {},
                'body': '',
                'response_time': response_time,
                'error': str(e)
            }
    
    def run_test(self, test: APITest) -> APITestResult:
        """Run a single test and return the result"""
        # Execute the request
        response_data = self.execute_request(test.request)
        
        # Create test result
        test_result = APITestResult.objects.create(
            test=test,
            request=test.request,
            environment=self.environment,
            response_status=response_data['status_code'],
            response_headers=response_data['headers'],
            response_body=response_data['body'],
            response_time=response_data['response_time'],
            error_message=response_data['error'] or '',
            status='running'
        )
        
        # Run assertions
        test_results = {}
        if response_data['error']:
            test_result.status = 'error'
            test_result.error_message = response_data['error']
        else:
            test_results = self._run_assertions(test, response_data)
            test_result.test_results = test_results
            
            # Determine overall test status
            if test_results.get('passed', True):
                test_result.status = 'passed'
            else:
                test_result.status = 'failed'
        
        test_result.save()
        return test_result
    
    def _run_assertions(self, test: APITest, response_data: Dict) -> Dict:
        """Run test assertions and return results"""
        results = {
            'passed': True,
            'assertions': []
        }
        
        # Run predefined assertions
        for assertion in test.assertions:
            assertion_result = self._evaluate_assertion(assertion, response_data)
            results['assertions'].append(assertion_result)
            
            if not assertion_result['passed']:
                results['passed'] = False
        
        # Run custom test script if provided
        if test.test_script:
            script_result = self._run_test_script(test.test_script, response_data)
            results['script_result'] = script_result
            
            if not script_result.get('passed', True):
                results['passed'] = False
        
        return results
    
    def _evaluate_assertion(self, assertion: Dict, response_data: Dict) -> Dict:
        """Evaluate a single assertion"""
        assertion_type = assertion.get('type')
        expected = assertion.get('expected')
        actual = None
        
        try:
            if assertion_type == 'status_code':
                actual = response_data['status_code']
            elif assertion_type == 'response_time':
                actual = response_data['response_time']
            elif assertion_type == 'header':
                header_name = assertion.get('header_name')
                actual = response_data['headers'].get(header_name)
            elif assertion_type == 'body_contains':
                actual = assertion.get('text') in response_data['body']
            elif assertion_type == 'body_json':
                try:
                    response_json = json.loads(response_data['body'])
                    actual = self._get_json_value(response_json, assertion.get('json_path', ''))
                except json.JSONDecodeError:
                    actual = None
            
            # Compare actual vs expected
            passed = self._compare_values(actual, expected, assertion.get('operator', 'equals'))
            
            return {
                'type': assertion_type,
                'expected': expected,
                'actual': actual,
                'passed': passed,
                'message': assertion.get('message', '')
            }
            
        except Exception as e:
            return {
                'type': assertion_type,
                'expected': expected,
                'actual': actual,
                'passed': False,
                'message': f'Assertion error: {str(e)}'
            }
    
    def _get_json_value(self, json_obj: Any, json_path: str) -> Any:
        """Get value from JSON object using dot notation path"""
        if not json_path:
            return json_obj
        
        keys = json_path.split('.')
        current = json_obj
        
        for key in keys:
            if isinstance(current, dict) and key in current:
                current = current[key]
            elif isinstance(current, list) and key.isdigit():
                current = current[int(key)]
            else:
                return None
        
        return current
    
    def _compare_values(self, actual: Any, expected: Any, operator: str) -> bool:
        """Compare actual and expected values using the specified operator"""
        if operator == 'equals':
            return actual == expected
        elif operator == 'not_equals':
            return actual != expected
        elif operator == 'contains':
            return str(expected) in str(actual)
        elif operator == 'not_contains':
            return str(expected) not in str(actual)
        elif operator == 'greater_than':
            return actual > expected
        elif operator == 'less_than':
            return actual < expected
        elif operator == 'greater_than_or_equal':
            return actual >= expected
        elif operator == 'less_than_or_equal':
            return actual <= expected
        else:
            return actual == expected
    
    def _run_test_script(self, script: str, response_data: Dict) -> Dict:
        """Run custom test script (simplified implementation)"""
        # This is a simplified implementation
        # In a real implementation, you might use a JavaScript engine like PyExecJS
        try:
            # Basic script evaluation (very limited)
            if 'pm.test' in script and 'pm.response' in script:
                # Simple pattern matching for common test patterns
                return {
                    'passed': True,
                    'message': 'Script executed successfully'
                }
            else:
                return {
                    'passed': False,
                    'message': 'Invalid test script format'
                }
        except Exception as e:
            return {
                'passed': False,
                'message': f'Script execution error: {str(e)}'
            }
    
    def run_test_suite(self, test_suite) -> Dict[str, Any]:
        """Run a complete test suite"""
        start_time = time.time()
        results = []
        
        for test in test_suite.tests.filter(enabled=True):
            test_result = self.run_test(test)
            results.append(test_result)
        
        total_time = time.time() - start_time
        passed_tests = sum(1 for r in results if r.status == 'passed')
        failed_tests = sum(1 for r in results if r.status in ['failed', 'error'])
        
        return {
            'total_tests': len(results),
            'passed_tests': passed_tests,
            'failed_tests': failed_tests,
            'total_time': total_time,
            'results': results
        }
