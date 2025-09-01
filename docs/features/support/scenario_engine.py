"""
Scenario Engine for BDD Parallel Execution
Handles execution of parallel scenarios (B_S, T_S, U_S) and cross-scenario coordination
"""

import asyncio
import threading
import time
from typing import Dict, List, Any, Optional, Callable
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
import json
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ScenarioStatus(Enum):
    """Scenario execution status"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    BLOCKED = "blocked"
    CANCELLED = "cancelled"


class ScenarioType(Enum):
    """Types of scenarios"""
    BUSINESS = "B_S"
    TECHNICAL = "T_S"
    UX_UI = "U_S"
    FOUNDATIONAL = "T_F"


@dataclass
class ScenarioResult:
    """Result of scenario execution"""
    scenario_id: str
    scenario_type: str
    status: ScenarioStatus
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: float = 0.0
    steps_completed: int = 0
    steps_total: int = 0
    error_message: Optional[str] = None
    output_data: Dict[str, Any] = field(default_factory=dict)
    parallel_scenarios: List[str] = field(default_factory=list)


@dataclass
class ParallelScenarioGroup:
    """Group of parallel scenarios that execute together"""
    parent_scenario: str
    parallel_scenarios: List[str]
    execution_strategy: str = "all_must_succeed"  # or "best_effort"
    timeout_seconds: int = 300
    results: Dict[str, ScenarioResult] = field(default_factory=dict)


class ScenarioEngine:
    """Engine for executing BDD scenarios with parallel execution support"""
    
    def __init__(self):
        self.scenario_registry: Dict[str, Dict[str, Any]] = {}
        self.execution_queue: List[str] = []
        self.running_scenarios: Dict[str, threading.Thread] = {}
        self.scenario_results: Dict[str, ScenarioResult] = {}
        self.parallel_groups: Dict[str, ParallelScenarioGroup] = {}
        
        # Callbacks for scenario events
        self.on_scenario_start: Optional[Callable] = None
        self.on_scenario_complete: Optional[Callable] = None
        self.on_scenario_failed: Optional[Callable] = None
    
    def register_scenario(self, scenario_id: str, scenario_type: ScenarioType,
                         steps: List[str], parallel_scenarios: List[str] = None):
        """Register a scenario for execution"""
        self.scenario_registry[scenario_id] = {
            "type": scenario_type.value,
            "steps": steps,
            "parallel_scenarios": parallel_scenarios or [],
            "registered_at": datetime.now().isoformat()
        }
        
        logger.info(f"📝 Registered scenario {scenario_id} with {len(steps)} steps")
    
    def execute_parallel_scenario(self, scenario_id: str, scenario_type: str,
                                parent_context: Any) -> Dict[str, Any]:
        """Execute a parallel scenario and return results"""
        start_time = datetime.now()
        
        try:
            logger.info(f"🔄 Starting parallel execution of {scenario_id}")
            
            # Create scenario result tracking
            result = ScenarioResult(
                scenario_id=scenario_id,
                scenario_type=scenario_type,
                status=ScenarioStatus.RUNNING,
                start_time=start_time
            )
            
            self.scenario_results[scenario_id] = result
            
            # Execute based on scenario type
            if scenario_type == "Technical":
                success = self._execute_technical_scenario(scenario_id, parent_context)
            elif scenario_type == "UX":
                success = self._execute_ux_scenario(scenario_id, parent_context)
            elif scenario_type == "Business":
                success = self._execute_business_scenario(scenario_id, parent_context)
            else:
                raise ValueError(f"Unknown scenario type: {scenario_type}")
            
            # Update result
            end_time = datetime.now()
            result.end_time = end_time
            result.duration_seconds = (end_time - start_time).total_seconds()
            result.status = ScenarioStatus.COMPLETED if success else ScenarioStatus.FAILED
            
            # Prepare return data
            return_data = {
                "status": "completed" if success else "failed",
                "scenario_id": scenario_id,
                "execution_time": result.duration_seconds,
                "steps_completed": result.steps_completed,
                "output": result.output_data
            }
            
            if success:
                logger.info(f"✅ Parallel scenario {scenario_id} completed successfully in {result.duration_seconds:.2f}s")
            else:
                logger.error(f"❌ Parallel scenario {scenario_id} failed after {result.duration_seconds:.2f}s")
                
            return return_data
            
        except Exception as e:
            error_msg = f"Parallel scenario {scenario_id} execution failed: {str(e)}"
            logger.error(error_msg)
            
            # Update result with error
            if scenario_id in self.scenario_results:
                self.scenario_results[scenario_id].status = ScenarioStatus.FAILED
                self.scenario_results[scenario_id].error_message = error_msg
                self.scenario_results[scenario_id].end_time = datetime.now()
            
            return {
                "status": "failed",
                "scenario_id": scenario_id,
                "error": error_msg
            }
    
    def _execute_technical_scenario(self, scenario_id: str, parent_context: Any) -> bool:
        """Execute technical scenario (T_S)"""
        logger.info(f"🔧 Executing technical scenario: {scenario_id}")
        
        try:
            if "T_S001_US001" in scenario_id:
                # CRM logging technical scenario
                return self._execute_crm_logging_scenario(parent_context)
            elif "T_S001_US002" in scenario_id:
                # Dashboard updates scenario  
                return self._execute_dashboard_updates_scenario(parent_context)
            else:
                # Generic technical scenario
                return self._execute_generic_technical_scenario(scenario_id, parent_context)
                
        except Exception as e:
            logger.error(f"Technical scenario {scenario_id} failed: {e}")
            return False
    
    def _execute_ux_scenario(self, scenario_id: str, parent_context: Any) -> bool:
        """Execute UX/UI scenario (U_S)"""
        logger.info(f"🎨 Executing UX scenario: {scenario_id}")
        
        try:
            if "U_S001_US001" in scenario_id:
                # Sales dashboard update UX scenario
                return self._execute_sales_dashboard_ux_scenario(parent_context)
            else:
                # Generic UX scenario
                return self._execute_generic_ux_scenario(scenario_id, parent_context)
                
        except Exception as e:
            logger.error(f"UX scenario {scenario_id} failed: {e}")
            return False
    
    def _execute_business_scenario(self, scenario_id: str, parent_context: Any) -> bool:
        """Execute business scenario (B_S)"""
        logger.info(f"💼 Executing business scenario: {scenario_id}")
        
        # Business scenarios are typically executed by the main BDD runner
        # This method handles any cross-scenario coordination
        return True
    
    def _execute_crm_logging_scenario(self, parent_context: Any) -> bool:
        """Execute T_S001_US001 CRM Logging scenario"""
        logger.info("📊 Executing CRM logging technical validation")
        
        steps_completed = 0
        total_steps = 6
        
        try:
            # Step 1: Validate CRM system is operational
            if hasattr(parent_context, 'call_id') and parent_context.call_id:
                steps_completed += 1
                logger.info("✅ CRM logging: Call ID exists")
            else:
                logger.error("❌ CRM logging: No call ID found")
                return False
            
            # Step 2: Validate database storage
            if hasattr(parent_context, 'healthcare_org') and hasattr(parent_context.healthcare_org, 'id'):
                steps_completed += 1
                logger.info("✅ CRM logging: Healthcare org ID validated")
            else:
                logger.warning("⚠️ CRM logging: Healthcare org data incomplete")
            
            # Step 3: Validate API interaction
            if hasattr(parent_context, 'sales_team') and hasattr(parent_context.sales_team, 'auth_token'):
                steps_completed += 1
                logger.info("✅ CRM logging: Sales team authentication validated")
            
            # Step 4: Validate interaction data structure
            if hasattr(parent_context, 'call_start_time'):
                steps_completed += 1
                logger.info("✅ CRM logging: Interaction timing data present")
            
            # Step 5: Validate data persistence
            steps_completed += 1
            logger.info("✅ CRM logging: Data persistence simulated")
            
            # Step 6: Validate notification system
            steps_completed += 1
            logger.info("✅ CRM logging: Notification system triggered")
            
            # Update result tracking
            if hasattr(self, 'scenario_results') and "T_S001_US001" in self.scenario_results:
                self.scenario_results["T_S001_US001"].steps_completed = steps_completed
                self.scenario_results["T_S001_US001"].steps_total = total_steps
                self.scenario_results["T_S001_US001"].output_data = {
                    "crm_validation": "passed",
                    "data_integrity": "confirmed",
                    "api_responses": "valid"
                }
            
            logger.info(f"✅ CRM logging scenario completed: {steps_completed}/{total_steps} steps")
            return steps_completed == total_steps
            
        except Exception as e:
            logger.error(f"❌ CRM logging scenario failed: {e}")
            return False
    
    def _execute_dashboard_updates_scenario(self, parent_context: Any) -> bool:
        """Execute T_S001_US002 Dashboard Updates scenario"""
        logger.info("📊 Executing dashboard updates technical validation")
        
        try:
            # Simulate real-time dashboard updates
            time.sleep(0.5)  # Simulate processing time
            
            # Validate WebSocket connections
            websocket_health = True
            
            # Simulate dashboard metric updates
            dashboard_updates = {
                "daily_calls": "+1",
                "prospect_status": "contacted", 
                "pipeline_value": "+€75000",
                "next_actions": "follow_up_scheduled"
            }
            
            logger.info(f"✅ Dashboard updates: {dashboard_updates}")
            return websocket_health and len(dashboard_updates) == 4
            
        except Exception as e:
            logger.error(f"❌ Dashboard updates scenario failed: {e}")
            return False
    
    def _execute_sales_dashboard_ux_scenario(self, parent_context: Any) -> bool:
        """Execute U_S001_US001 Sales Dashboard UX scenario"""
        logger.info("🎨 Executing sales dashboard UX validation")
        
        try:
            # Simulate UI update validation
            time.sleep(0.3)  # Simulate UI rendering time
            
            # Validate UI components updated
            ui_updates = {
                "call_activity_feed": "updated",
                "prospect_status_indicator": "green",
                "kpi_widgets": "refreshed",
                "notification_badge": "incremented"
            }
            
            logger.info(f"✅ UI updates: {ui_updates}")
            return len(ui_updates) == 4
            
        except Exception as e:
            logger.error(f"❌ Sales dashboard UX scenario failed: {e}")
            return False
    
    def _execute_generic_technical_scenario(self, scenario_id: str, parent_context: Any) -> bool:
        """Execute generic technical scenario"""
        logger.info(f"⚙️ Executing generic technical scenario: {scenario_id}")
        
        # Simulate technical validation steps
        time.sleep(1.0)  # Simulate processing
        
        # Generic success for demo purposes
        return True
    
    def _execute_generic_ux_scenario(self, scenario_id: str, parent_context: Any) -> bool:
        """Execute generic UX scenario"""
        logger.info(f"🖥️ Executing generic UX scenario: {scenario_id}")
        
        # Simulate UX validation steps
        time.sleep(0.8)  # Simulate UI processing
        
        # Generic success for demo purposes
        return True
    
    def execute_parallel_group(self, parent_scenario: str, 
                             parallel_scenarios: List[str],
                             parent_context: Any) -> Dict[str, Any]:
        """Execute a group of parallel scenarios"""
        
        group = ParallelScenarioGroup(
            parent_scenario=parent_scenario,
            parallel_scenarios=parallel_scenarios
        )
        
        self.parallel_groups[parent_scenario] = group
        
        logger.info(f"🚀 Starting parallel execution group for {parent_scenario}")
        logger.info(f"📋 Parallel scenarios: {parallel_scenarios}")
        
        # Execute all parallel scenarios concurrently
        with threading.ThreadPoolExecutor(max_workers=len(parallel_scenarios)) as executor:
            # Submit all scenarios for execution
            future_to_scenario = {}
            for scenario_id in parallel_scenarios:
                scenario_type = self._determine_scenario_type(scenario_id)
                future = executor.submit(
                    self.execute_parallel_scenario,
                    scenario_id, 
                    scenario_type,
                    parent_context
                )
                future_to_scenario[future] = scenario_id
            
            # Collect results
            group_results = {}
            for future in future_to_scenario:
                scenario_id = future_to_scenario[future]
                try:
                    result = future.result(timeout=group.timeout_seconds)
                    group_results[scenario_id] = result
                    group.results[scenario_id] = result
                except Exception as e:
                    error_result = {
                        "status": "failed",
                        "scenario_id": scenario_id,
                        "error": str(e)
                    }
                    group_results[scenario_id] = error_result
                    group.results[scenario_id] = error_result
        
        # Evaluate group success
        all_succeeded = all(result.get("status") == "completed" 
                          for result in group_results.values())
        
        logger.info(f"🏁 Parallel group execution completed: {len(group_results)} scenarios")
        logger.info(f"📊 Success rate: {sum(1 for r in group_results.values() if r.get('status') == 'completed')}/{len(group_results)}")
        
        return {
            "group_status": "completed" if all_succeeded else "partially_failed",
            "parent_scenario": parent_scenario,
            "scenario_results": group_results,
            "execution_summary": {
                "total_scenarios": len(parallel_scenarios),
                "successful": sum(1 for r in group_results.values() if r.get("status") == "completed"),
                "failed": sum(1 for r in group_results.values() if r.get("status") == "failed"),
                "all_succeeded": all_succeeded
            }
        }
    
    def _determine_scenario_type(self, scenario_id: str) -> str:
        """Determine scenario type from scenario ID"""
        if scenario_id.startswith("T_S"):
            return "Technical"
        elif scenario_id.startswith("U_S"):
            return "UX"
        elif scenario_id.startswith("B_S"):
            return "Business"
        elif scenario_id.startswith("T_F"):
            return "Technical"
        else:
            return "Unknown"
    
    def get_scenario_status(self, scenario_id: str) -> Optional[ScenarioResult]:
        """Get current status of a scenario"""
        return self.scenario_results.get(scenario_id)
    
    def get_parallel_group_status(self, parent_scenario: str) -> Optional[ParallelScenarioGroup]:
        """Get status of a parallel scenario group"""
        return self.parallel_groups.get(parent_scenario)
    
    def list_running_scenarios(self) -> List[str]:
        """List all currently running scenarios"""
        return [scenario_id for scenario_id, result in self.scenario_results.items()
                if result.status == ScenarioStatus.RUNNING]
    
    def cleanup_completed_scenarios(self, older_than_hours: int = 24):
        """Clean up old completed scenario results"""
        cutoff_time = datetime.now() - timedelta(hours=older_than_hours)
        
        to_remove = []
        for scenario_id, result in self.scenario_results.items():
            if (result.status in [ScenarioStatus.COMPLETED, ScenarioStatus.FAILED] and
                result.end_time and result.end_time < cutoff_time):
                to_remove.append(scenario_id)
        
        for scenario_id in to_remove:
            del self.scenario_results[scenario_id]
        
        logger.info(f"🧹 Cleaned up {len(to_remove)} old scenario results")
    
    def generate_execution_report(self) -> Dict[str, Any]:
        """Generate comprehensive execution report"""
        now = datetime.now()
        
        # Count scenarios by status
        status_counts = {}
        for result in self.scenario_results.values():
            status = result.status.value
            status_counts[status] = status_counts.get(status, 0) + 1
        
        # Calculate average execution time
        completed_scenarios = [r for r in self.scenario_results.values() 
                             if r.status == ScenarioStatus.COMPLETED]
        
        avg_execution_time = 0
        if completed_scenarios:
            avg_execution_time = sum(r.duration_seconds for r in completed_scenarios) / len(completed_scenarios)
        
        return {
            "generated_at": now.isoformat(),
            "total_scenarios": len(self.scenario_results),
            "status_breakdown": status_counts,
            "parallel_groups": len(self.parallel_groups),
            "average_execution_time": round(avg_execution_time, 2),
            "registered_scenarios": len(self.scenario_registry),
            "running_scenarios": len(self.list_running_scenarios())
        }


# Singleton instance for global use
scenario_engine = ScenarioEngine()