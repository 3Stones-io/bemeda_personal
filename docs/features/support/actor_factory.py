"""
Actor Factory for BDD Scenarios
Creates different types of actors (Human, System, Interface) for scenario execution
"""

import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field


@dataclass
class BaseActor:
    """Base actor class with common properties"""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    name: str = ""
    actor_type: str = ""
    status: str = "active"
    created_at: datetime = field(default_factory=datetime.now)
    capabilities: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass 
class HealthcareOrganisation(BaseActor):
    """Healthcare organisation actor for business scenarios"""
    organisation_type: str = "General Hospital"
    bed_count: int = 100
    location: str = ""
    contact_email: str = ""
    staffing_needs: List[str] = field(default_factory=list)
    budget_range: str = ""
    decision_makers: List[str] = field(default_factory=list)
    
    def __post_init__(self):
        self.actor_type = "Healthcare Organisation"
        if not self.capabilities:
            self.capabilities = ["evaluate", "decide", "hire", "negotiate"]


@dataclass
class SalesTeamMember(BaseActor):
    """Sales team member actor"""
    employee_id: str = ""
    territory: str = ""
    quota: float = 0.0
    credentials: Dict[str, str] = field(default_factory=dict)
    auth_token: Optional[str] = None
    
    def __post_init__(self):
        self.actor_type = "Sales Team Member"
        if not self.capabilities:
            self.capabilities = ["call", "present", "negotiate", "research"]
        if not self.credentials:
            self.credentials = {
                "username": f"{self.name.lower().replace(' ', '.')}",
                "password": "secure_password_123"
            }


@dataclass
class JobSeeker(BaseActor):
    """Job seeker/healthcare professional actor"""
    profession: str = ""
    experience_years: int = 0
    licenses: List[str] = field(default_factory=list)
    certifications: List[str] = field(default_factory=list)
    location_preference: str = ""
    salary_expectation: str = ""
    availability: str = ""
    motivation: str = ""
    platform_awareness: Dict[str, Any] = field(default_factory=dict)
    profile_id: Optional[str] = None
    
    def __post_init__(self):
        self.actor_type = "Job Seeker"
        if not self.capabilities:
            self.capabilities = ["apply", "interview", "accept", "negotiate"]


@dataclass
class SystemActor(BaseActor):
    """System/technical component actor"""
    version: str = "1.0"
    endpoint: str = ""
    health_status: str = "online"
    dependencies: List[str] = field(default_factory=list)
    configuration: Dict[str, Any] = field(default_factory=dict)
    
    def __post_init__(self):
        self.actor_type = "System Component"


class ActorFactory:
    """Factory for creating different types of actors"""
    
    def __init__(self):
        self.created_actors: Dict[str, BaseActor] = {}
    
    def create_actor(self, actor_type: str, name: str, status: str = "active", 
                    capabilities: List[str] = None) -> BaseActor:
        """Create a generic actor"""
        actor = BaseActor(
            name=name,
            actor_type=actor_type,
            status=status,
            capabilities=capabilities or []
        )
        
        self.created_actors[actor.id] = actor
        return actor
    
    def create_healthcare_organisation(self, name: str, status: str = "prospect",
                                     staffing_needs: List[str] = None,
                                     organisation_type: str = "General Hospital",
                                     location: str = "Berlin, Germany") -> HealthcareOrganisation:
        """Create a healthcare organisation actor"""
        org = HealthcareOrganisation(
            name=name,
            status=status,
            staffing_needs=staffing_needs or ["nurses", "doctors"],
            organisation_type=organisation_type,
            location=location,
            contact_email=f"hr@{name.lower().replace(' ', '')}.test"
        )
        
        self.created_actors[org.id] = org
        return org
    
    def create_sales_team_member(self, name: str, employee_id: str = None,
                               territory: str = "DACH") -> SalesTeamMember:
        """Create a sales team member actor"""
        sales_member = SalesTeamMember(
            name=name,
            employee_id=employee_id or f"sales_{uuid.uuid4().hex[:8]}",
            territory=territory,
            quota=500000.0  # €500k annual quota
        )
        
        self.created_actors[sales_member.id] = sales_member
        return sales_member
    
    def create_job_seeker(self, name: str, profession: str,
                         experience_years: int = 5) -> JobSeeker:
        """Create a job seeker actor"""
        job_seeker = JobSeeker(
            name=name,
            profession=profession,
            experience_years=experience_years,
            licenses=["RN License Germany"] if "nurse" in profession.lower() else [],
            certifications=["BLS", "ACLS"] if "nurse" in profession.lower() else []
        )
        
        self.created_actors[job_seeker.id] = job_seeker
        return job_seeker
    
    def create_system_actor(self, name: str, version: str = "1.0",
                           endpoint: str = "", capabilities: List[str] = None) -> SystemActor:
        """Create a system component actor"""
        system = SystemActor(
            name=name,
            version=version,
            endpoint=endpoint,
            capabilities=capabilities or []
        )
        
        self.created_actors[system.id] = system
        return system
    
    def get_actor(self, actor_id: str) -> Optional[BaseActor]:
        """Retrieve an actor by ID"""
        return self.created_actors.get(actor_id)
    
    def get_actors_by_type(self, actor_type: str) -> List[BaseActor]:
        """Get all actors of a specific type"""
        return [actor for actor in self.created_actors.values() 
                if actor.actor_type == actor_type]
    
    def list_all_actors(self) -> Dict[str, BaseActor]:
        """Get all created actors"""
        return self.created_actors.copy()
    
    def reset_factory(self):
        """Clear all created actors (useful for test isolation)"""
        self.created_actors.clear()
    
    # Predefined actor templates for common scenarios
    
    def create_standard_b_s001_actors(self) -> Dict[str, BaseActor]:
        """Create the standard actor set for B_S001 cold call scenario"""
        actors = {}
        
        # Healthcare Organisation
        actors['healthcare_org'] = self.create_healthcare_organisation(
            name="Berlin Medical Center",
            status="prospect",
            staffing_needs=["ICU Nurses", "Emergency Doctors"],
            location="Berlin, Germany"
        )
        
        # Sales Team Member
        actors['sales_rep'] = self.create_sales_team_member(
            name="John Sales",
            employee_id="sales_001",
            territory="Berlin/Brandenburg"
        )
        
        # Job Seeker (for later scenarios)
        actors['job_seeker'] = self.create_job_seeker(
            name="Maria Santos",
            profession="Registered Nurse",
            experience_years=5
        )
        
        # System Actors
        actors['crm_system'] = self.create_system_actor(
            name="CRM System",
            version="2.0",
            endpoint="http://localhost:4000/api/crm",
            capabilities=["log", "track", "notify", "report"]
        )
        
        actors['auth_system'] = self.create_system_actor(
            name="Auth System",
            version="2.0", 
            endpoint="http://localhost:4000/api/auth",
            capabilities=["authenticate", "authorize", "session_manage"]
        )
        
        actors['email_service'] = self.create_system_actor(
            name="Email Service",
            version="2.1",
            endpoint="http://localhost:4000/api/emails",
            capabilities=["send", "deliver", "track", "template"]
        )
        
        return actors
    
    def create_technical_actors(self) -> Dict[str, SystemActor]:
        """Create technical system actors for T_S scenarios"""
        technical_actors = {}
        
        # Core infrastructure
        technical_actors['database'] = self.create_system_actor(
            name="Database",
            version="1.5",
            endpoint="postgresql://localhost:5432",
            capabilities=["store", "retrieve", "update", "backup"]
        )
        
        technical_actors['api_router'] = self.create_system_actor(
            name="API Router", 
            version="1.0",
            endpoint="http://localhost:4000/api",
            capabilities=["route", "validate", "transform", "rate_limit"]
        )
        
        technical_actors['search_engine'] = self.create_system_actor(
            name="Search Engine",
            version="1.3", 
            endpoint="http://localhost:4000/api/search",
            capabilities=["index", "search", "rank", "filter"]
        )
        
        technical_actors['chat_system'] = self.create_system_actor(
            name="Chat System",
            version="1.2",
            endpoint="ws://localhost:4000/socket",
            capabilities=["message", "broadcast", "presence", "history"]
        )
        
        return technical_actors


# Singleton instance for global use
actor_factory = ActorFactory()