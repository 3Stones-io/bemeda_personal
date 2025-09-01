"""
BDD Support Module
Provides all necessary infrastructure for BDD scenario execution
"""

# Import all support modules for easy access
from .actor_factory import (
    ActorFactory, 
    BaseActor, 
    HealthcareOrganisation, 
    SalesTeamMember, 
    JobSeeker, 
    SystemActor,
    actor_factory  # singleton instance
)

from .scenario_engine import (
    ScenarioEngine,
    ScenarioResult,
    ScenarioStatus,
    ScenarioType,
    ParallelScenarioGroup,
    scenario_engine  # singleton instance
)

from .test_data import (
    TestDataManager,
    TestDataTemplate,
    test_data_manager  # singleton instance
)

from .api_client import (
    APIClient,
    APIResponse,
    api_client  # singleton instance
)

# Version info
__version__ = "1.0.0"
__author__ = "BDD Framework Team"
__description__ = "Support infrastructure for BDD scenario execution"

# Export key components
__all__ = [
    # Classes
    "ActorFactory", "BaseActor", "HealthcareOrganisation", "SalesTeamMember", 
    "JobSeeker", "SystemActor",
    "ScenarioEngine", "ScenarioResult", "ScenarioStatus", "ScenarioType", 
    "ParallelScenarioGroup",
    "TestDataManager", "TestDataTemplate",
    "APIClient", "APIResponse",
    
    # Singleton instances
    "actor_factory", "scenario_engine", "test_data_manager", "api_client"
]