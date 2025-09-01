"""
Test Data Manager for BDD Scenarios
Provides realistic test data for different scenarios and actors
"""

import json
import random
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field
import uuid


@dataclass
class TestDataTemplate:
    """Template for generating consistent test data"""
    template_id: str
    name: str
    description: str
    data_structure: Dict[str, Any]
    variations: List[Dict[str, Any]] = field(default_factory=list)


class TestDataManager:
    """Manages test data for BDD scenarios"""
    
    def __init__(self):
        self.data_templates: Dict[str, TestDataTemplate] = {}
        self.generated_data: Dict[str, Any] = {}
        self.sequence_counters: Dict[str, int] = {}
        
        # Initialize default templates
        self._initialize_default_templates()
    
    def _initialize_default_templates(self):
        """Set up default test data templates"""
        
        # Healthcare Organisation Template
        healthcare_org_template = TestDataTemplate(
            template_id="healthcare_org",
            name="Healthcare Organisation",
            description="Template for healthcare organisation test data",
            data_structure={
                "name": "{{org_name}}",
                "type": "{{org_type}}",
                "bed_count": "{{bed_count}}",
                "location": "{{location}}",
                "contact_email": "{{contact_email}}",
                "staffing_needs": "{{staffing_needs}}",
                "budget_range": "{{budget_range}}",
                "decision_makers": "{{decision_makers}}",
                "annual_revenue": "{{annual_revenue}}",
                "employee_count": "{{employee_count}}"
            },
            variations=[
                {
                    "org_name": "Berlin Medical Center",
                    "org_type": "General Hospital",
                    "bed_count": 200,
                    "location": "Berlin, Germany",
                    "staffing_needs": ["ICU Nurses", "Emergency Doctors", "Radiologists"],
                    "budget_range": "€500k-€1M annually",
                    "decision_makers": ["Chief Medical Officer", "HR Director"],
                    "annual_revenue": "€45M",
                    "employee_count": 1200
                },
                {
                    "org_name": "Munich Specialty Clinic",
                    "org_type": "Specialty Clinic", 
                    "bed_count": 50,
                    "location": "Munich, Germany",
                    "staffing_needs": ["Specialized Nurses", "Anesthesiologists"],
                    "budget_range": "€200k-€500k annually",
                    "decision_makers": ["Medical Director"],
                    "annual_revenue": "€8M",
                    "employee_count": 150
                },
                {
                    "org_name": "Hamburg Regional Hospital",
                    "org_type": "Regional Hospital",
                    "bed_count": 150,
                    "location": "Hamburg, Germany", 
                    "staffing_needs": ["General Nurses", "Surgeons", "Lab Technicians"],
                    "budget_range": "€300k-€800k annually",
                    "decision_makers": ["CEO", "Chief Nursing Officer"],
                    "annual_revenue": "€25M",
                    "employee_count": 800
                }
            ]
        )
        
        # Job Seeker Template
        job_seeker_template = TestDataTemplate(
            template_id="job_seeker",
            name="Job Seeker",
            description="Template for healthcare professional job seeker data",
            data_structure={
                "name": "{{full_name}}",
                "profession": "{{profession}}",
                "experience_years": "{{experience_years}}",
                "licenses": "{{licenses}}",
                "certifications": "{{certifications}}",
                "specialties": "{{specialties}}",
                "education": "{{education}}",
                "location_preference": "{{location_preference}}",
                "salary_expectation": "{{salary_expectation}}",
                "availability": "{{availability}}"
            },
            variations=[
                {
                    "full_name": "Maria Santos",
                    "profession": "Registered Nurse",
                    "experience_years": 5,
                    "licenses": ["RN License Germany", "EU Nursing Directive"],
                    "certifications": ["BLS", "ACLS", "ICU Certified"],
                    "specialties": ["Critical Care", "Emergency Medicine"],
                    "education": "Bachelor of Nursing, University of Berlin",
                    "location_preference": "Berlin metro area",
                    "salary_expectation": "€52,000-€65,000",
                    "availability": "2 weeks notice"
                },
                {
                    "full_name": "Dr. Andreas Mueller",
                    "profession": "Emergency Medicine Physician",
                    "experience_years": 8,
                    "licenses": ["Medical License Germany", "Emergency Medicine Specialty"],
                    "certifications": ["ATLS", "ACLS", "PALS"],
                    "specialties": ["Emergency Medicine", "Trauma"],
                    "education": "Medical Degree, University of Munich",
                    "location_preference": "Munich or surrounding areas",
                    "salary_expectation": "€95,000-€120,000",
                    "availability": "1 month notice"
                },
                {
                    "full_name": "Sophie Weber",
                    "profession": "Nurse Practitioner",
                    "experience_years": 12,
                    "licenses": ["Advanced Practice Nursing License"],
                    "certifications": ["FNP-C", "BLS", "ACLS"],
                    "specialties": ["Family Medicine", "Pediatrics"],
                    "education": "Master of Science in Nursing, Hamburg University",
                    "location_preference": "Hamburg or remote",
                    "salary_expectation": "€68,000-€85,000",
                    "availability": "3 weeks notice"
                }
            ]
        )
        
        # Sales Research Template
        research_template = TestDataTemplate(
            template_id="sales_research",
            name="Sales Research Data",
            description="Template for sales team research data",
            data_structure={
                "target_organisation": "{{organisation_id}}",
                "researcher": "{{researcher_name}}",
                "research_date": "{{research_date}}",
                "findings": "{{findings}}",
                "pain_points": "{{pain_points}}",
                "decision_makers": "{{decision_makers}}",
                "competitive_landscape": "{{competitive_landscape}}",
                "approach_strategy": "{{approach_strategy}}"
            }
        )
        
        # Call Interaction Template
        call_template = TestDataTemplate(
            template_id="call_interaction",
            name="Call Interaction",
            description="Template for sales call interaction data",
            data_structure={
                "call_id": "{{call_id}}",
                "prospect_id": "{{prospect_id}}",
                "sales_rep_id": "{{sales_rep_id}}",
                "call_date": "{{call_date}}",
                "duration_minutes": "{{duration}}",
                "outcome": "{{outcome}}",
                "interest_level": "{{interest_level}}",
                "next_steps": "{{next_steps}}",
                "notes": "{{notes}}"
            }
        )
        
        # Store templates
        self.data_templates["healthcare_org"] = healthcare_org_template
        self.data_templates["job_seeker"] = job_seeker_template
        self.data_templates["sales_research"] = research_template
        self.data_templates["call_interaction"] = call_template
    
    def create_research_data(self, organisation_id: str, researcher: str) -> Dict[str, Any]:
        """Create research data for sales team"""
        research_data = {
            "organisation_id": organisation_id,
            "researcher": researcher,
            "research_date": datetime.now().isoformat(),
            "current_staff": f"{random.randint(40, 200)} nurses, {random.randint(15, 80)} doctors",
            "turnover_rate": f"{random.randint(10, 25)}% annually",
            "urgent_needs": random.choice(["ICU nurses", "Emergency doctors", "Surgical nurses", "Lab technicians"]),
            "budget_range": random.choice(["€50k-80k per placement", "€80k-120k per placement", "€40k-60k per placement"]),
            "recent_challenges": random.choice([
                "High turnover in ICU department",
                "Difficulty recruiting specialized nurses",
                "Need for bilingual staff",
                "Expanding emergency department"
            ]),
            "decision_timeline": random.choice(["2-4 weeks", "1-2 months", "urgent (1 week)", "flexible"]),
            "previous_agencies": random.choice(["None used before", "Used competitor X", "Bad experience with Agency Y", "Multiple agencies tried"]),
            "key_contacts": [
                {"role": "HR Director", "name": "Contact Person 1", "decision_power": "high"},
                {"role": "Department Head", "name": "Contact Person 2", "decision_power": "medium"}
            ]
        }
        
        # Store generated data
        research_key = f"research_{organisation_id}_{researcher}"
        self.generated_data[research_key] = research_data
        
        return research_data
    
    def create_healthcare_organisation_data(self, variation_index: int = None) -> Dict[str, Any]:
        """Create healthcare organisation test data"""
        template = self.data_templates["healthcare_org"]
        
        if variation_index is None:
            variation_index = random.randint(0, len(template.variations) - 1)
        
        if variation_index < len(template.variations):
            base_data = template.variations[variation_index].copy()
        else:
            # Generate random data if variation doesn't exist
            base_data = self._generate_random_healthcare_org()
        
        # Add unique identifiers and timestamps
        base_data.update({
            "id": str(uuid.uuid4()),
            "created_at": datetime.now().isoformat(),
            "last_updated": datetime.now().isoformat(),
            "status": "prospect",
            "source": "sales_research",
            "priority_score": random.randint(1, 10)
        })
        
        return base_data
    
    def create_job_seeker_data(self, variation_index: int = None) -> Dict[str, Any]:
        """Create job seeker test data"""
        template = self.data_templates["job_seeker"]
        
        if variation_index is None:
            variation_index = random.randint(0, len(template.variations) - 1)
        
        if variation_index < len(template.variations):
            base_data = template.variations[variation_index].copy()
        else:
            base_data = self._generate_random_job_seeker()
        
        # Add unique identifiers
        base_data.update({
            "id": str(uuid.uuid4()),
            "profile_created": datetime.now().isoformat(),
            "status": "active",
            "match_score": random.randint(65, 95),
            "references": self._generate_references()
        })
        
        return base_data
    
    def create_call_interaction_data(self, prospect_id: str, sales_rep_id: str) -> Dict[str, Any]:
        """Create call interaction test data"""
        call_data = {
            "call_id": f"call_{uuid.uuid4().hex[:8]}",
            "prospect_id": prospect_id,
            "sales_rep_id": sales_rep_id,
            "call_date": datetime.now().isoformat(),
            "call_type": "cold_call",
            "duration_minutes": random.randint(8, 25),
            "outcome": random.choice(["interested", "not_interested", "follow_up_required", "callback_requested"]),
            "interest_level": random.randint(1, 10),
            "questions_asked": random.randint(2, 8),
            "objections_raised": random.randint(0, 4),
            "value_proposition_presented": True,
            "guarantee_explained": True,
            "success_rate_mentioned": "92%",
            "next_steps": random.choice([
                "Schedule detailed discussion",
                "Send information packet", 
                "Follow up in 1 week",
                "No follow up needed"
            ]),
            "notes": self._generate_call_notes(),
            "follow_up_date": (datetime.now() + timedelta(days=random.randint(1, 7))).isoformat()
        }
        
        return call_data
    
    def _generate_random_healthcare_org(self) -> Dict[str, Any]:
        """Generate random healthcare organisation data"""
        org_types = ["General Hospital", "Specialty Clinic", "Regional Hospital", "University Medical Center"]
        locations = ["Berlin, Germany", "Munich, Germany", "Hamburg, Germany", "Frankfurt, Germany", "Cologne, Germany"]
        
        org_name = f"{random.choice(['Berlin', 'Munich', 'Hamburg', 'Regional', 'City'])} {random.choice(['Medical Center', 'Hospital', 'Clinic', 'Healthcare'])}"
        
        return {
            "name": org_name,
            "type": random.choice(org_types),
            "bed_count": random.randint(50, 400),
            "location": random.choice(locations),
            "staffing_needs": random.sample(["Nurses", "Doctors", "Specialists", "Technicians"], random.randint(1, 3)),
            "budget_range": f"€{random.randint(100, 800)}k-€{random.randint(500, 1500)}k annually",
            "employee_count": random.randint(100, 2000)
        }
    
    def _generate_random_job_seeker(self) -> Dict[str, Any]:
        """Generate random job seeker data"""
        first_names = ["Maria", "Andreas", "Sophie", "Thomas", "Anna", "Michael", "Lisa", "Christian"]
        last_names = ["Mueller", "Schmidt", "Weber", "Fischer", "Wagner", "Becker", "Schulz", "Hoffmann"]
        professions = ["Registered Nurse", "Emergency Physician", "Nurse Practitioner", "Radiologic Technologist"]
        
        return {
            "name": f"{random.choice(first_names)} {random.choice(last_names)}",
            "profession": random.choice(professions),
            "experience_years": random.randint(2, 15),
            "licenses": ["Professional License Germany"],
            "certifications": random.sample(["BLS", "ACLS", "PALS", "ATLS"], random.randint(1, 3)),
            "salary_expectation": f"€{random.randint(40, 100)},000-€{random.randint(60, 130)},000"
        }
    
    def _generate_references(self) -> List[Dict[str, str]]:
        """Generate professional references"""
        return [
            {
                "name": f"Dr. {random.choice(['Schmidt', 'Mueller', 'Weber'])}",
                "title": "Medical Director",
                "relationship": "Former Supervisor",
                "phone": "+49 30 12345678",
                "email": "reference1@hospital.de"
            },
            {
                "name": f"{random.choice(['Anna', 'Maria', 'Sophie'])} {random.choice(['Fischer', 'Wagner', 'Becker'])}",
                "title": "Charge Nurse",
                "relationship": "Colleague",
                "phone": "+49 30 87654321", 
                "email": "reference2@clinic.de"
            }
        ]
    
    def _generate_call_notes(self) -> str:
        """Generate realistic call notes"""
        note_templates = [
            "Spoke with HR Director about staffing challenges in ICU department. Showed strong interest in our 92% success rate. Concerns about budget approval process - connected with CFO next week.",
            "Initial call with Chief Medical Officer. Currently working with another agency but not satisfied with candidate quality. Interested in our pre-screening process and 90-day guarantee.",
            "Productive conversation with Department Head. Urgent need for 3 ICU nurses starting next month. Requested case studies from similar hospitals. Follow-up scheduled for Wednesday.",
            "Cold call to new contact. Explained our value proposition and placement process. Asked good questions about timeline and candidate vetting. Positive reception overall."
        ]
        
        return random.choice(note_templates)
    
    def get_sequence_number(self, sequence_name: str) -> int:
        """Get next number in a sequence for unique identifiers"""
        if sequence_name not in self.sequence_counters:
            self.sequence_counters[sequence_name] = 1000  # Start at 1000
        else:
            self.sequence_counters[sequence_name] += 1
        
        return self.sequence_counters[sequence_name]
    
    def create_api_response_mock(self, status_code: int = 200, data: Dict[str, Any] = None) -> Dict[str, Any]:
        """Create mock API response for testing"""
        return {
            "status_code": status_code,
            "response_data": data or {},
            "timestamp": datetime.now().isoformat(),
            "request_id": str(uuid.uuid4()),
            "processing_time_ms": random.randint(50, 300)
        }
    
    def get_template(self, template_id: str) -> Optional[TestDataTemplate]:
        """Get a test data template by ID"""
        return self.data_templates.get(template_id)
    
    def store_generated_data(self, key: str, data: Any):
        """Store generated data for reuse"""
        self.generated_data[key] = data
    
    def get_generated_data(self, key: str) -> Optional[Any]:
        """Retrieve previously generated data"""
        return self.generated_data.get(key)
    
    def clear_generated_data(self):
        """Clear all generated data (useful for test isolation)"""
        self.generated_data.clear()
        self.sequence_counters.clear()
    
    def export_test_data_set(self, scenario_id: str) -> Dict[str, Any]:
        """Export complete test data set for a scenario"""
        return {
            "scenario_id": scenario_id,
            "generated_at": datetime.now().isoformat(),
            "healthcare_org": self.create_healthcare_organisation_data(),
            "job_seeker": self.create_job_seeker_data(),
            "sales_research": self.create_research_data("org_123", "John Sales"),
            "call_interaction": self.create_call_interaction_data("org_123", "sales_456")
        }


# Singleton instance for global use
test_data_manager = TestDataManager()