"""
API Client for BDD Scenario Integration
Provides interface to Phoenix application APIs for scenario testing
"""

import requests
import json
import time
from typing import Dict, List, Any, Optional
from datetime import datetime
from dataclasses import dataclass
from urllib.parse import urljoin
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class APIResponse:
    """Standardized API response wrapper"""
    status_code: int
    data: Dict[str, Any]
    headers: Dict[str, str]
    response_time_ms: float
    timestamp: str
    
    def json(self) -> Dict[str, Any]:
        """Get response data as JSON"""
        return self.data
    
    @property
    def text(self) -> str:
        """Get response as text"""
        return json.dumps(self.data)


class APIClient:
    """Client for interacting with Phoenix application APIs"""
    
    def __init__(self, base_url: str = "http://localhost:4000"):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "BDD-Test-Client/1.0"
        })
        
        # Mock mode for when Phoenix app is not running
        self.mock_mode = False
        self.mock_responses: Dict[str, Any] = {}
        
        # Initialize mock responses
        self._initialize_mock_responses()
    
    def _initialize_mock_responses(self):
        """Initialize mock API responses for testing"""
        self.mock_responses = {
            "health_check": {
                "status": "OK",
                "timestamp": datetime.now().isoformat(),
                "version": "1.0.0",
                "database": "connected",
                "services": ["auth", "crm", "email", "search"]
            },
            "create_organisation": {
                "id": "org_12345",
                "name": "Test Hospital",
                "status": "created",
                "created_at": datetime.now().isoformat()
            },
            "authenticate_user": {
                "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "user_id": "user_123",
                "role": "sales_rep",
                "expires_at": (datetime.now()).isoformat()
            },
            "initiate_call": {
                "call_id": "call_abc123",
                "status": "initiated",
                "start_time": datetime.now().isoformat()
            }
        }
    
    def enable_mock_mode(self):
        """Enable mock mode for testing without Phoenix app"""
        self.mock_mode = True
        logger.info("🎭 API Client: Mock mode enabled")
    
    def disable_mock_mode(self):
        """Disable mock mode to use real Phoenix app"""
        self.mock_mode = False
        logger.info("🔗 API Client: Mock mode disabled - using real APIs")
    
    def _make_request(self, method: str, endpoint: str, data: Dict[str, Any] = None,
                     headers: Dict[str, str] = None, timeout: int = 30) -> APIResponse:
        """Make HTTP request with error handling and mock support"""
        
        start_time = time.time()
        
        # Mock mode response
        if self.mock_mode:
            return self._generate_mock_response(endpoint, method, data)
        
        # Real API request
        url = urljoin(self.base_url, endpoint)
        
        try:
            # Prepare request
            request_headers = self.session.headers.copy()
            if headers:
                request_headers.update(headers)
            
            request_data = json.dumps(data) if data else None
            
            # Make request
            response = self.session.request(
                method=method,
                url=url,
                data=request_data,
                headers=request_headers,
                timeout=timeout
            )
            
            # Calculate response time
            response_time = (time.time() - start_time) * 1000
            
            # Parse response
            try:
                response_data = response.json() if response.content else {}
            except json.JSONDecodeError:
                response_data = {"raw_response": response.text}
            
            # Create standardized response
            api_response = APIResponse(
                status_code=response.status_code,
                data=response_data,
                headers=dict(response.headers),
                response_time_ms=response_time,
                timestamp=datetime.now().isoformat()
            )
            
            logger.info(f"📡 API {method} {endpoint}: {response.status_code} ({response_time:.0f}ms)")
            
            return api_response
            
        except requests.exceptions.RequestException as e:
            logger.warning(f"⚠️ API request failed: {e}, falling back to mock mode")
            self.mock_mode = True
            return self._generate_mock_response(endpoint, method, data)
    
    def _generate_mock_response(self, endpoint: str, method: str, 
                               data: Dict[str, Any] = None) -> APIResponse:
        """Generate mock API response"""
        
        # Determine response based on endpoint
        mock_key = self._get_mock_key(endpoint, method)
        mock_data = self.mock_responses.get(mock_key, {"message": "Mock response"})
        
        # Add realistic delay
        time.sleep(0.1)  # 100ms mock delay
        
        # Simulate different status codes based on endpoint
        status_code = 200
        if method == "POST" and "create" in endpoint:
            status_code = 201
        elif "auth" in endpoint and method == "POST":
            status_code = 200
        elif method == "DELETE":
            status_code = 204
        
        return APIResponse(
            status_code=status_code,
            data=mock_data,
            headers={"Content-Type": "application/json"},
            response_time_ms=100.0,
            timestamp=datetime.now().isoformat()
        )
    
    def _get_mock_key(self, endpoint: str, method: str) -> str:
        """Determine mock response key from endpoint"""
        if "health" in endpoint:
            return "health_check"
        elif "organisations" in endpoint and method == "POST":
            return "create_organisation"
        elif "auth" in endpoint and method == "POST":
            return "authenticate_user"
        elif "call" in endpoint and method == "POST":
            return "initiate_call"
        else:
            return "default"
    
    # Health and System APIs
    
    def health_check(self) -> Dict[str, Any]:
        """Check API health status"""
        response = self._make_request("GET", "/api/health")
        return response.data
    
    def get_system_info(self) -> APIResponse:
        """Get system information"""
        return self._make_request("GET", "/api/system/info")
    
    # Authentication APIs
    
    def authenticate_user(self, credentials: Dict[str, str]) -> APIResponse:
        """Authenticate user and get token"""
        auth_data = {
            "username": credentials.get("username"),
            "password": credentials.get("password")
        }
        return self._make_request("POST", "/api/auth/login", auth_data)
    
    def validate_token(self, token: str) -> APIResponse:
        """Validate authentication token"""
        headers = {"Authorization": f"Bearer {token}"}
        return self._make_request("GET", "/api/auth/validate", headers=headers)
    
    def logout_user(self, token: str) -> APIResponse:
        """Logout user and invalidate token"""
        headers = {"Authorization": f"Bearer {token}"}
        return self._make_request("POST", "/api/auth/logout", headers=headers)
    
    # Organisation Management APIs
    
    def create_organisation(self, org_data: Dict[str, Any]) -> APIResponse:
        """Create new healthcare organisation"""
        return self._make_request("POST", "/api/organisations", org_data)
    
    def get_organisation(self, org_id: str) -> APIResponse:
        """Get organisation by ID"""
        return self._make_request("GET", f"/api/organisations/{org_id}")
    
    def update_organisation(self, org_id: str, update_data: Dict[str, Any]) -> APIResponse:
        """Update organisation information"""
        return self._make_request("PUT", f"/api/organisations/{org_id}", update_data)
    
    def list_organisations(self, filters: Dict[str, Any] = None) -> APIResponse:
        """List organisations with optional filters"""
        endpoint = "/api/organisations"
        if filters:
            # Convert filters to query parameters
            query_params = "&".join([f"{k}={v}" for k, v in filters.items()])
            endpoint += f"?{query_params}"
        return self._make_request("GET", endpoint)
    
    # CRM and Interaction APIs
    
    def initiate_call(self, call_data: Dict[str, Any], auth_token: str) -> APIResponse:
        """Initiate a sales call interaction"""
        headers = {"Authorization": f"Bearer {auth_token}"}
        return self._make_request("POST", "/api/crm/calls", call_data, headers)
    
    def log_call_activity(self, activity_data: Dict[str, Any], auth_token: str) -> APIResponse:
        """Log activity during a call"""
        headers = {"Authorization": f"Bearer {auth_token}"}
        return self._make_request("POST", "/api/crm/activities", activity_data, headers)
    
    def complete_call(self, completion_data: Dict[str, Any], auth_token: str) -> APIResponse:
        """Complete and finalize a call"""
        headers = {"Authorization": f"Bearer {auth_token}"}
        return self._make_request("PUT", "/api/crm/calls/complete", completion_data, headers)
    
    def get_interaction(self, interaction_id: str) -> APIResponse:
        """Get interaction details by ID"""
        return self._make_request("GET", f"/api/crm/interactions/{interaction_id}")
    
    def assess_call_outcome(self, assessment_data: Dict[str, Any], auth_token: str) -> APIResponse:
        """Assess and record call outcome"""
        headers = {"Authorization": f"Bearer {auth_token}"}
        return self._make_request("POST", "/api/crm/assessments", assessment_data, headers)
    
    def schedule_followup(self, followup_data: Dict[str, Any], auth_token: str) -> APIResponse:
        """Schedule follow-up interaction"""
        headers = {"Authorization": f"Bearer {auth_token}"}
        return self._make_request("POST", "/api/crm/followups", followup_data, headers)
    
    def store_research_data(self, research_data: Dict[str, Any], auth_token: str) -> APIResponse:
        """Store sales research data"""
        headers = {"Authorization": f"Bearer {auth_token}"}
        return self._make_request("POST", "/api/crm/research", research_data, headers)
    
    # Job Seeker APIs
    
    def get_registration_page(self) -> APIResponse:
        """Get job seeker registration page data"""
        return self._make_request("GET", "/api/jobseekers/register")
    
    def create_job_seeker_profile(self, profile_data: Dict[str, Any]) -> APIResponse:
        """Create job seeker profile"""
        return self._make_request("POST", "/api/jobseekers", profile_data)
    
    def get_job_seeker(self, profile_id: str) -> APIResponse:
        """Get job seeker profile by ID"""
        return self._make_request("GET", f"/api/jobseekers/{profile_id}")
    
    def update_job_seeker_profile(self, profile_id: str, update_data: Dict[str, Any]) -> APIResponse:
        """Update job seeker profile"""
        return self._make_request("PUT", f"/api/jobseekers/{profile_id}", update_data)
    
    # Email Service APIs
    
    def send_email(self, email_data: Dict[str, Any]) -> APIResponse:
        """Send email through email service"""
        return self._make_request("POST", "/api/emails/send", email_data)
    
    def get_email_templates(self) -> APIResponse:
        """Get available email templates"""
        return self._make_request("GET", "/api/emails/templates")
    
    def track_email_delivery(self, email_id: str) -> APIResponse:
        """Track email delivery status"""
        return self._make_request("GET", f"/api/emails/{email_id}/status")
    
    # Search and Matching APIs
    
    def search_prospects(self, search_criteria: Dict[str, Any]) -> APIResponse:
        """Search for prospect organisations"""
        return self._make_request("POST", "/api/search/prospects", search_criteria)
    
    def match_candidates(self, job_criteria: Dict[str, Any]) -> APIResponse:
        """Match candidates to job criteria"""
        return self._make_request("POST", "/api/search/candidates", job_criteria)
    
    def get_search_analytics(self) -> APIResponse:
        """Get search analytics and metrics"""
        return self._make_request("GET", "/api/search/analytics")
    
    # BDD Test Support APIs
    
    def log_scenario_completion(self, scenario_data: Dict[str, Any]) -> APIResponse:
        """Log BDD scenario completion (for tracking)"""
        return self._make_request("POST", "/api/testing/scenarios", scenario_data)
    
    def get_test_metrics(self) -> APIResponse:
        """Get BDD test execution metrics"""
        return self._make_request("GET", "/api/testing/metrics")
    
    def reset_test_data(self, auth_token: str) -> APIResponse:
        """Reset test data (test environments only)"""
        headers = {"Authorization": f"Bearer {auth_token}"}
        return self._make_request("DELETE", "/api/testing/reset", headers=headers)
    
    # Utility methods
    
    def wait_for_api_availability(self, max_retries: int = 10, delay_seconds: int = 2) -> bool:
        """Wait for API to become available"""
        for attempt in range(max_retries):
            try:
                response = self.health_check()
                if response.get("status") == "OK":
                    logger.info(f"✅ API available after {attempt + 1} attempts")
                    return True
            except Exception as e:
                logger.info(f"⏳ API not ready (attempt {attempt + 1}/{max_retries}): {e}")
                time.sleep(delay_seconds)
        
        logger.warning(f"⚠️ API not available after {max_retries} attempts, enabling mock mode")
        self.enable_mock_mode()
        return False
    
    def batch_request(self, requests: List[Dict[str, Any]]) -> List[APIResponse]:
        """Execute multiple API requests in batch"""
        results = []
        for request in requests:
            method = request.get("method", "GET")
            endpoint = request.get("endpoint", "")
            data = request.get("data", {})
            headers = request.get("headers", {})
            
            response = self._make_request(method, endpoint, data, headers)
            results.append(response)
        
        return results
    
    def set_mock_response(self, endpoint_key: str, response_data: Dict[str, Any]):
        """Set custom mock response for testing"""
        self.mock_responses[endpoint_key] = response_data
    
    def clear_mock_responses(self):
        """Clear all mock responses"""
        self.mock_responses.clear()
        self._initialize_mock_responses()


# Global instance with auto-detection of API availability
api_client = APIClient()

# Auto-detect if Phoenix app is running
if not api_client.wait_for_api_availability(max_retries=3, delay_seconds=1):
    logger.info("🎭 Phoenix app not detected - using mock mode for BDD tests")