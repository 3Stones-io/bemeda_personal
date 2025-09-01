"""
BDD Step Definitions for Business Scenarios
This module contains step definitions that make Gherkin scenarios executable
"""

from behave import given, when, then, step
import requests
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any

# Import test helpers
from features.support.actor_factory import ActorFactory
from features.support.scenario_engine import ScenarioEngine
from features.support.test_data import TestDataManager
from features.support.api_client import APIClient

# Actor Factory and Engine instances
actor_factory = ActorFactory()
scenario_engine = ScenarioEngine()
test_data = TestDataManager()
api_client = APIClient()

# ========================================
# Background and Setup Steps
# ========================================

@given('the platform is operational')
def step_platform_operational(context):
    """Verify that the platform is running and accessible"""
    context.platform_status = api_client.health_check()
    assert context.platform_status['status'] == 'OK', f"Platform not operational: {context.platform_status}"
    
    # Initialize context for scenario execution
    context.actors = {}
    context.interactions = []
    context.scenario_results = {}

@given('the following actors are available')
def step_actors_available(context):
    """Create and register actors from the provided table"""
    for row in context.table:
        actor = actor_factory.create_actor(
            actor_type=row['Actor Type'],
            name=row['Actor Name'],
            status=row['Status'],
            capabilities=row.get('Capabilities', '').split(',')
        )
        context.actors[row['Actor Name']] = actor
        print(f"✅ Actor '{row['Actor Name']}' created with status '{row['Status']}'")

# ========================================
# Healthcare Organisation Actor Steps
# ========================================

@given('a Healthcare Organisation exists as a qualified prospect')
def step_healthcare_org_exists(context):
    """Create a healthcare organisation prospect"""
    context.healthcare_org = actor_factory.create_healthcare_organisation(
        name="Test Hospital",
        status="prospect",
        staffing_needs=["nurses", "doctors"]
    )
    
    # Store in database via API
    org_data = {
        "name": context.healthcare_org.name,
        "type": "General Hospital", 
        "status": "prospect",
        "contact_email": "hr@testhospital.test",
        "staffing_needs": context.healthcare_org.staffing_needs
    }
    
    response = api_client.create_organisation(org_data)
    assert response.status_code == 201, f"Failed to create organisation: {response.text}"
    
    context.healthcare_org.id = response.json()['id']
    print(f"✅ Healthcare Organisation created with ID: {context.healthcare_org.id}")

@given('the organisation has the following profile')
def step_org_profile(context):
    """Set detailed organisation profile from table"""
    for row in context.table:
        setattr(context.healthcare_org, row['Field'], row['Value'])
    
    # Update organisation via API
    update_data = {field: getattr(context.healthcare_org, field) 
                  for field in ['name', 'type', 'size', 'location', 'staffing_needs', 'status']}
    
    response = api_client.update_organisation(context.healthcare_org.id, update_data)
    assert response.status_code == 200, f"Failed to update organisation: {response.text}"
    
    print(f"✅ Organisation profile updated: {update_data}")

# ========================================
# Sales Team Actor Steps  
# ========================================

@given('the Sales Team has researched their staffing needs')
def step_sales_research(context):
    """Create sales team member and populate research data"""
    context.sales_team = actor_factory.create_sales_team_member(
        name="John Sales",
        employee_id="sales_001"
    )
    
    # Authenticate sales team member
    auth_response = api_client.authenticate_user(context.sales_team.credentials)
    assert auth_response.status_code == 200, "Sales team authentication failed"
    context.sales_team.auth_token = auth_response.json()['token']
    
    # Create research data
    context.research_data = test_data.create_research_data(
        organisation_id=context.healthcare_org.id,
        researcher=context.sales_team.name
    )
    
    print(f"✅ Sales team research completed for {context.healthcare_org.name}")

@given('the research includes')
def step_research_details(context):
    """Add specific research findings from table"""
    for row in context.table:
        context.research_data[row['Research Area']] = row['Finding']
    
    # Store research in CRM
    crm_data = {
        "prospect_id": context.healthcare_org.id,
        "research_data": context.research_data,
        "researcher_id": context.sales_team.employee_id,
        "research_date": datetime.now().isoformat()
    }
    
    response = api_client.store_research_data(crm_data, context.sales_team.auth_token)
    assert response.status_code == 201, f"Failed to store research: {response.text}"
    
    print(f"✅ Research details stored: {list(context.research_data.keys())}")

# ========================================
# Interaction and Communication Steps
# ========================================

@when('the Sales Team calls the Healthcare Organisation')
def step_sales_calls_org(context):
    """Execute the cold call interaction"""
    context.call_start_time = datetime.now()
    
    # Simulate call interaction
    call_data = {
        "prospect_id": context.healthcare_org.id,
        "sales_rep_id": context.sales_team.employee_id,
        "interaction_type": "cold_call",
        "start_time": context.call_start_time.isoformat(),
        "research_applied": context.research_data
    }
    
    # Log call initiation
    response = api_client.initiate_call(call_data, context.sales_team.auth_token)
    assert response.status_code == 200, f"Call initiation failed: {response.text}"
    
    context.call_id = response.json()['call_id']
    context.call_in_progress = True
    
    print(f"✅ Cold call initiated with ID: {context.call_id}")

@when('presents our value proposition')
def step_present_value_prop(context):
    """Sales team presents value proposition"""
    value_prop_data = {
        "call_id": context.call_id,
        "presentation_elements": [
            "92% placement success rate",
            "no placement, no fee guarantee", 
            "90-day replacement guarantee",
            "pre-screened candidates",
            "24/7 support"
        ],
        "duration_minutes": 5
    }
    
    response = api_client.log_call_activity(value_prop_data, context.sales_team.auth_token)
    assert response.status_code == 200, f"Failed to log value proposition: {response.text}"
    
    context.value_prop_presented = True
    print("✅ Value proposition presented successfully")

@when('explains our placement success rate of "{success_rate}"')
def step_explain_success_rate(context, success_rate):
    """Present specific success rate statistics"""
    stats_data = {
        "call_id": context.call_id,
        "statistics_presented": {
            "success_rate": success_rate,
            "average_time_to_fill": "18 days",
            "candidate_retention": "94% after 1 year",
            "client_satisfaction": "4.8/5.0"
        }
    }
    
    response = api_client.log_call_activity(stats_data, context.sales_team.auth_token)
    assert response.status_code == 200, f"Failed to log statistics: {response.text}"
    
    context.success_rate_presented = success_rate
    print(f"✅ Success rate {success_rate} presented")

@when('offers a "{guarantee}" guarantee')
def step_offer_guarantee(context, guarantee):
    """Present service guarantee"""
    guarantee_data = {
        "call_id": context.call_id,
        "guarantee_offered": guarantee,
        "guarantee_terms": "Full refund if placement not successful within agreed timeframe"
    }
    
    response = api_client.log_call_activity(guarantee_data, context.sales_team.auth_token)
    assert response.status_code == 200, f"Failed to log guarantee: {response.text}"
    
    context.guarantee_offered = guarantee
    print(f"✅ {guarantee} guarantee offered")

# ========================================
# Outcome Validation Steps
# ========================================

@then('the Healthcare Organisation should understand our value proposition')
def step_org_understands_value(context):
    """Validate that organisation understood the value proposition"""
    # Simulate organisation response analysis
    call_outcome_data = {
        "call_id": context.call_id,
        "understanding_assessment": "high",
        "questions_asked": ["What is your candidate vetting process?", "How quickly can you fill positions?"],
        "concerns_raised": ["Budget approval process", "Timeline requirements"]
    }
    
    response = api_client.assess_call_outcome(call_outcome_data, context.sales_team.auth_token)
    assert response.status_code == 200, f"Failed to assess call outcome: {response.text}"
    
    context.call_outcome = response.json()
    context.understanding_confirmed = True
    
    print(f"✅ Organisation understanding confirmed: {context.call_outcome['understanding_level']}/10")

@then('their understanding level should be at least {min_level:d} out of 10')
def step_validate_understanding_level(context, min_level):
    """Validate minimum understanding level achieved"""
    actual_level = context.call_outcome.get('understanding_level', 0)
    assert actual_level >= min_level, f"Understanding level {actual_level} below minimum {min_level}"
    
    print(f"✅ Understanding level {actual_level}/10 meets minimum requirement of {min_level}/10")

@then('they should express interest in our services')
def step_org_expresses_interest(context):
    """Validate that organisation expressed interest"""
    interest_indicators = context.call_outcome.get('interest_indicators', [])
    
    expected_indicators = [
        "asked follow-up questions",
        "requested additional information", 
        "discussed specific needs",
        "showed engagement in conversation"
    ]
    
    # At least 2 interest indicators should be present
    matching_indicators = [indicator for indicator in expected_indicators 
                          if any(expected in indicator for expected in interest_indicators)]
    
    assert len(matching_indicators) >= 2, f"Insufficient interest indicators: {interest_indicators}"
    
    context.interest_confirmed = True
    print(f"✅ Interest confirmed with indicators: {interest_indicators}")

@then('they should agree to schedule a detailed discussion')
def step_agree_to_followup(context):
    """Validate that follow-up discussion was scheduled"""
    followup_data = {
        "call_id": context.call_id,
        "follow_up_agreed": True,
        "proposed_timeframe": "within 48 hours",
        "discussion_type": "detailed needs analysis"
    }
    
    response = api_client.schedule_followup(followup_data, context.sales_team.auth_token)
    assert response.status_code == 201, f"Failed to schedule follow-up: {response.text}"
    
    context.followup_scheduled = response.json()
    context.followup_id = context.followup_scheduled['followup_id']
    
    print(f"✅ Follow-up discussion scheduled: {context.followup_id}")

@then('the interaction should be logged in the CRM System')
def step_interaction_logged_crm(context):
    """Validate that complete interaction was logged in CRM"""
    # Complete the call logging
    call_completion_data = {
        "call_id": context.call_id,
        "end_time": datetime.now().isoformat(),
        "duration_minutes": (datetime.now() - context.call_start_time).seconds // 60,
        "outcome": "interested",
        "next_action": "schedule_detailed_discussion",
        "follow_up_id": getattr(context, 'followup_id', None)
    }
    
    response = api_client.complete_call(call_completion_data, context.sales_team.auth_token)
    assert response.status_code == 200, f"Failed to complete call logging: {response.text}"
    
    # Verify CRM entry exists
    crm_response = api_client.get_interaction(context.call_id)
    assert crm_response.status_code == 200, "Interaction not found in CRM"
    
    crm_data = crm_response.json()
    assert crm_data['prospect_id'] == context.healthcare_org.id, "CRM data mismatch"
    assert crm_data['outcome'] == "interested", "CRM outcome incorrect"
    
    context.crm_logged = True
    print(f"✅ Interaction logged in CRM with outcome: {crm_data['outcome']}")

# ========================================
# Parallel Scenario Execution Steps
# ========================================

@then('the following parallel scenarios should execute successfully')
def step_parallel_scenarios_execute(context):
    """Execute and validate parallel scenarios"""
    context.parallel_results = {}
    
    for row in context.table:
        scenario_id = row['Scenario']
        scenario_type = row['Type']
        expected_result = row['Expected Result']
        
        print(f"🔄 Executing parallel scenario: {scenario_id}")
        
        # Execute parallel scenario using scenario engine
        result = scenario_engine.execute_parallel_scenario(
            scenario_id=scenario_id,
            scenario_type=scenario_type,
            parent_context=context
        )
        
        # Validate result matches expectation
        assert result['status'] == expected_result, f"Parallel scenario {scenario_id} failed: {result}"
        
        context.parallel_results[scenario_id] = result
        print(f"✅ Parallel scenario {scenario_id} completed: {expected_result}")
    
    # Verify all parallel scenarios completed successfully
    failed_scenarios = [sid for sid, result in context.parallel_results.items() 
                       if result['status'] != context.table[0]['Expected Result']]
    
    assert len(failed_scenarios) == 0, f"Failed parallel scenarios: {failed_scenarios}"
    print(f"✅ All {len(context.parallel_results)} parallel scenarios completed successfully")

# ========================================
# Job Seeker Scenario Steps
# ========================================

@given('a healthcare professional is looking for new opportunities')
def step_job_seeker_looking(context):
    """Create a job seeker actor"""
    context.job_seeker = actor_factory.create_job_seeker(
        name="Maria Santos",
        profession="Registered Nurse",
        experience_years=5
    )
    
    context.job_seeker.motivation = "seeking better work-life balance"
    context.job_seeker.location_preference = "Berlin, Germany"
    
    print(f"✅ Job seeker created: {context.job_seeker.name} ({context.job_seeker.profession})")

@given('they have heard about our platform')
def step_heard_about_platform(context):
    """Job seeker has awareness of the platform"""
    context.job_seeker.platform_awareness = {
        "source": "colleague referral",
        "awareness_level": "basic",
        "expectations": ["quality jobs", "professional support"]
    }
    
    print(f"✅ Platform awareness established via {context.job_seeker.platform_awareness['source']}")

@when('they visit our platform registration page')
def step_visit_registration_page(context):
    """Job seeker accesses registration"""
    response = api_client.get_registration_page()
    assert response.status_code == 200, "Registration page not accessible"
    
    context.registration_page = response.json()
    context.registration_started = True
    
    print("✅ Registration page accessed successfully")

@when('complete their professional profile including')
def step_complete_profile(context):
    """Job seeker completes detailed profile"""
    profile_data = {}
    
    for row in context.table:
        section = row['Profile Section']
        info = row['Required Information']
        
        if section == "personal_info":
            profile_data.update({
                "name": context.job_seeker.name,
                "email": f"{context.job_seeker.name.lower().replace(' ', '.')}@email.com",
                "phone": "+49 30 12345678"
            })
        elif section == "qualifications":
            profile_data['qualifications'] = {
                "licenses": ["RN License Germany"],
                "certifications": ["BLS", "ACLS", "ICU Certified"]
            }
        elif section == "experience":
            profile_data['experience'] = {
                "years_total": context.job_seeker.experience_years,
                "specialties": ["ICU", "Emergency"],
                "previous_roles": ["Staff Nurse", "Charge Nurse"]
            }
        elif section == "preferences":
            profile_data['preferences'] = {
                "location": context.job_seeker.location_preference,
                "salary_range": "€45000-€60000",
                "schedule": "Full-time"
            }
        elif section == "availability":
            profile_data['availability'] = {
                "start_date": "2 weeks notice",
                "schedule_preference": "day shifts"
            }
    
    # Submit profile via API
    response = api_client.create_job_seeker_profile(profile_data)
    assert response.status_code == 201, f"Profile creation failed: {response.text}"
    
    context.job_seeker.profile_id = response.json()['profile_id']
    context.profile_created = True
    
    print(f"✅ Job seeker profile created with ID: {context.job_seeker.profile_id}")

# ========================================
# Utility and Helper Steps
# ========================================

@step('wait for {seconds:d} seconds')
def step_wait_seconds(context, seconds):
    """Wait for specified number of seconds"""
    time.sleep(seconds)
    print(f"⏳ Waited {seconds} seconds")

@step('debug print context')
def step_debug_context(context):
    """Debug helper to print current context state"""
    print("🔍 DEBUG CONTEXT:")
    for attr_name in dir(context):
        if not attr_name.startswith('_'):
            attr_value = getattr(context, attr_name)
            if not callable(attr_value):
                print(f"  {attr_name}: {attr_value}")

@then('the scenario should be marked as completed')
def step_scenario_completed(context):
    """Mark the current scenario as successfully completed"""
    scenario_completion_data = {
        "scenario_name": context.scenario.name if hasattr(context, 'scenario') else "unknown",
        "completion_time": datetime.now().isoformat(),
        "status": "completed",
        "all_steps_passed": True,
        "parallel_scenarios_completed": len(getattr(context, 'parallel_results', {}))
    }
    
    # Log scenario completion (could integrate with project management tools)
    response = api_client.log_scenario_completion(scenario_completion_data)
    
    if response.status_code == 201:
        print(f"✅ Scenario completion logged successfully")
    else:
        print(f"⚠️ Scenario completion logging failed: {response.text}")
    
    # Verify all expected context attributes are present
    required_attrs = ['healthcare_org', 'sales_team', 'call_outcome', 'crm_logged']
    missing_attrs = [attr for attr in required_attrs if not hasattr(context, attr)]
    
    assert len(missing_attrs) == 0, f"Missing required context attributes: {missing_attrs}"
    print("✅ Scenario completed with all required context attributes present")