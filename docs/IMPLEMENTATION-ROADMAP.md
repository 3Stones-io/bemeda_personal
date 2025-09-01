# 🚀 World-Class BDD + Actor Scenario System - Implementation Roadmap

**Target**: Transform our existing system into a world-class, GitHub-first, reusable BDD + Actor scenario framework

**Timeline**: 6 iterations, 2-3 weeks total
**Status**: Ready to execute

---

## 📋 Iteration Overview

| Phase | Duration | Focus | Deliverables |
|-------|----------|-------|--------------|
| **Iteration 1** | 2 days | GitHub Structure Enhancement | Enhanced issue templates, project views |
| **Iteration 2** | 3 days | BDD Gherkin Integration | Gherkin scenarios, validation workflows |
| **Iteration 3** | 3 days | Actor-Based Testing | Executable scenarios, automated testing |
| **Iteration 4** | 3 days | Cross-Reference Automation | Scenario dependencies, relationship validation |
| **Iteration 5** | 2 days | Documentation & Templates | Integration guides, reusable templates |
| **Iteration 6** | 2 days | UI Enhancement & Polish | Updated interface, dashboard improvements |

---

## 🎯 Iteration 1: GitHub Structure Enhancement
**Duration**: 2 days  
**Goal**: Enhance GitHub project structure with advanced features

### Actions to Execute:

#### Day 1: Enhanced Issue Templates with Executable Checklists
```bash
# 1. Create advanced BDD issue template with checkbox-driven Gherkin
# Location: .github/ISSUE_TEMPLATE/bdd-scenario.yml
```

**Template Structure**:
```yaml
name: 🎭 BDD Scenario (B_S/T_S/U_S)
description: Create a new BDD scenario with actors and Gherkin syntax
body:
  - type: dropdown
    id: scenario_type
    attributes:
      label: "Scenario Type"
      options:
        - "B_S (Business Scenario)"
        - "T_S (Technical Scenario)" 
        - "U_S (UX Scenario)"
  
  - type: input
    id: scenario_id
    attributes:
      label: "Scenario ID"
      placeholder: "B_S001, T_S001, or U_S001"
      
  - type: checkboxes
    id: parallel_scenarios
    attributes:
      label: "Parallel Scenarios"
      options:
        - label: "Has corresponding Technical Scenario (T_S)"
        - label: "Has corresponding UX Scenario (U_S)"
        - label: "Has corresponding Business Scenario (B_S)"
        
  - type: textarea
    id: actors
    attributes:
      label: "Primary Actors"
      placeholder: |
        🏥 Healthcare Organisation
        👩‍⚕️ Job Seeker  
        📞 Sales Team
        
  - type: textarea
    id: gherkin_scenario
    attributes:
      label: "BDD Scenario (Gherkin Format)"
      placeholder: |
        Feature: B_S001 Cold Call to Placement
          In order to connect healthcare talent with opportunities
          As a Healthcare Recruitment Platform
          We need to facilitate complete placement workflows

        Background:
          Given the following actors exist:
            | Actor           | Role              |
            | Healthcare Org  | Service Buyer     |
            | Job Seeker      | Service Provider  |
            | Sales Team      | Platform Facilitator |

        Scenario: B_S001_US001 Organisation Receives Cold Call
          Given the Sales Team has identified a Healthcare Organisation prospect
          And the prospect matches our target criteria
          When the Sales Team calls the Healthcare Organisation
          Then the Healthcare Organisation should understand our value proposition
          And they should show interest in our services
          And they should agree to discuss their specific staffing needs
          
          # Parallel execution
          And scenario T_S001_US001 should execute
          And scenario U_S001_US001 should execute
```

#### Day 2: Advanced Project Views
```bash
# 2. Create custom project views for actors
```

**Project Views to Create**:
1. **Business Actor Journey**: Filter by `B_S` scenarios, grouped by actor
2. **Technical Component Map**: Filter by `T_S` scenarios, grouped by component  
3. **UX Flow Tracker**: Filter by `U_S` scenarios, grouped by user type
4. **Cross-Scenario Dashboard**: Show parallel scenario relationships
5. **BDD Test Status**: Show scenario execution status

**Custom Fields to Add**:
- **Actor Type**: Single select (Human, System, Interface)
- **Scenario Status**: Single select (Draft, Review, Approved, Testing, Completed)
- **BDD Status**: Single select (Not Started, Gherkin Written, Tests Created, Passing, Failed)
- **Parallel Scenarios**: Multi-select references to related scenarios
- **Test Coverage**: Number field (0-100%)

### Deliverables:
- ✅ Enhanced BDD scenario issue template  
- ✅ 5 custom project views for different actor perspectives
- ✅ Custom fields for BDD and scenario tracking
- ✅ Automated label and field assignment

---

## 🧪 Iteration 2: BDD Gherkin Integration  
**Duration**: 3 days
**Goal**: Transform existing scenarios into executable Gherkin format

### Actions to Execute:

#### Day 1: Convert Existing Scenarios
```bash
# 1. Convert B_S001 to full Gherkin format
```

**B_S001 Enhanced Structure**:
```gherkin
# File: features/business/B_S001_cold_call_to_placement.feature
Feature: B_S001 Cold Call to Candidate Placement
  In order to connect qualified healthcare professionals with healthcare organizations
  As a Healthcare Recruitment Platform  
  We need to facilitate complete placement workflows from initial contact to successful hiring

  Background:
    Given the platform is operational
    And the following actors are available:
      | Actor Type      | Actor Name         | Status    |
      | Human           | Sales Team         | Active    |
      | Human           | Healthcare Org     | Prospect  |  
      | Human           | Job Seeker         | Registered|
      | System          | CRM System         | Online    |
      | System          | Email Service      | Online    |
      | System          | Matching Engine    | Online    |

  Scenario: B_S001_US001 Organisation Receives Cold Call
    Given a Healthcare Organisation exists as a qualified prospect
    And the Sales Team has researched their staffing needs
    When the Sales Team calls the Healthcare Organisation
    Then the Healthcare Organisation should understand our value proposition
    And they should express interest in our services
    And they should agree to schedule a detailed discussion
    And the interaction should be logged in the CRM System
    
    # Parallel scenario triggers
    And the following parallel scenarios should execute:
      | Scenario    | Type      | Expected Result |
      | T_S001_US001| Technical | CRM logging successful |
      | U_S001_US001| UX        | Sales dashboard updated |

  Scenario: B_S001_US002 Discuss Staffing Needs  
    Given the Healthcare Organisation has agreed to a detailed discussion
    And the Sales Team has prepared relevant case studies
    When the Sales Team presents our staffing solutions
    Then the Healthcare Organisation should understand our process
    And they should share their specific staffing challenges
    And they should show willingness to proceed with job posting
    
  # Continue with remaining user stories...
```

#### Day 2: Create Step Definitions
```bash
# 2. Create executable step definitions
```

**Python Step Definitions** (`features/steps/business_steps.py`):
```python
from behave import given, when, then
from test_helpers.actor_factory import create_actor
from test_helpers.scenario_engine import ScenarioEngine

@given('a Healthcare Organisation exists as a qualified prospect')
def create_healthcare_org_prospect(context):
    context.healthcare_org = create_actor(
        type='healthcare_organisation',
        status='prospect',
        staffing_needs=['nurses', 'doctors']
    )

@given('the Sales Team has researched their staffing needs')  
def sales_team_preparation(context):
    context.sales_team = create_actor(type='sales_team')
    context.research_data = context.sales_team.research_prospect(
        context.healthcare_org
    )

@when('the Sales Team calls the Healthcare Organisation')
def sales_team_makes_call(context):
    context.call_result = context.sales_team.initiate_contact(
        context.healthcare_org,
        method='phone_call',
        research_data=context.research_data
    )

@then('the Healthcare Organisation should understand our value proposition')
def verify_value_prop_understood(context):
    assert context.call_result.understanding_level >= 8  # Scale 1-10
    assert 'value_proposition' in context.call_result.understood_concepts

@then('the following parallel scenarios should execute')
def execute_parallel_scenarios(context):
    scenario_engine = ScenarioEngine()
    for row in context.table:
        result = scenario_engine.execute_scenario(
            scenario_id=row['Scenario'],
            scenario_type=row['Type'],
            context=context
        )
        assert result.status == row['Expected Result']
```

#### Day 3: GitHub Actions Integration
```bash  
# 3. Create BDD validation workflow
```

**GitHub Action** (`.github/workflows/bdd-scenarios.yml`):
```yaml
name: BDD Scenario Validation
on:
  issues:
    types: [opened, edited]
  pull_request:
    paths: ['features/**', 'lib/**', 'test/**']

jobs:
  extract-gherkin:
    if: contains(github.event.issue.labels.*.name, 'bdd-scenario')
    runs-on: ubuntu-latest
    steps:
      - name: Extract Gherkin from Issue
        run: |
          python scripts/extract_gherkin_from_issue.py \
            --issue-number ${{ github.event.issue.number }} \
            --output-dir features/extracted/
            
      - name: Validate Gherkin Syntax
        run: |
          behave --dry-run features/extracted/
          
      - name: Comment Validation Results
        run: |
          gh issue comment ${{ github.event.issue.number }} \
            --body "🧪 Gherkin validation: $(cat gherkin-validation-results.md)"

  run-bdd-tests:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.15'
          otp-version: '26'
          
      - name: Setup Python for BDD
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Install Dependencies
        run: |
          mix deps.get
          pip install behave pytest-bdd requests
          
      - name: Run BDD Tests
        run: |
          # Run Elixir tests for technical scenarios
          mix test test/bdd/
          
          # Run Python BDD tests for business scenarios  
          behave features/business/
          
          # Run UI tests for UX scenarios
          pytest tests/ux_bdd/
          
      - name: Generate BDD Report
        run: |
          python scripts/generate_bdd_report.py \
            --output reports/bdd-summary.json
            
      - name: Update GitHub Project
        run: |
          python scripts/update_project_bdd_status.py \
            --project-id ${{ vars.PROJECT_ID }} \
            --report reports/bdd-summary.json
```

### Deliverables:
- ✅ B_S001 converted to full Gherkin format
- ✅ Executable step definitions for Python/Elixir
- ✅ GitHub Actions workflow for BDD validation
- ✅ Automated scenario extraction from issues

---

## 🤖 Iteration 3: Actor-Based Testing
**Duration**: 3 days  
**Goal**: Create executable test suite based on actor interactions

### Actions to Execute:

#### Day 1: Actor Test Framework
```bash
# 1. Create actor testing framework
```

**Actor Factory** (`test_helpers/actor_factory.py`):
```python
from dataclasses import dataclass
from typing import Dict, List, Any
import requests

@dataclass
class Actor:
    name: str
    type: str  # 'human', 'system', 'interface'
    capabilities: List[str]
    state: Dict[str, Any]
    
    def can_perform(self, action: str) -> bool:
        return action in self.capabilities
        
    def update_state(self, **kwargs):
        self.state.update(kwargs)

class HumanActor(Actor):
    def __init__(self, name: str, role: str):
        super().__init__(
            name=name,
            type='human', 
            capabilities=['communicate', 'decide', 'approve'],
            state={'role': role, 'authenticated': False}
        )
        
    def authenticate(self, credentials: Dict) -> bool:
        # Simulate human authentication
        response = requests.post('/api/auth/login', json=credentials)
        authenticated = response.status_code == 200
        self.update_state(authenticated=authenticated)
        return authenticated

class SystemActor(Actor):
    def __init__(self, name: str, service_url: str):
        super().__init__(
            name=name,
            type='system',
            capabilities=['process', 'store', 'retrieve', 'notify'],
            state={'service_url': service_url, 'status': 'online'}
        )
        
    def process_request(self, request_data: Dict) -> Dict:
        response = requests.post(
            f"{self.state['service_url']}/process", 
            json=request_data
        )
        return response.json()

class InterfaceActor(Actor):  
    def __init__(self, name: str, device_type: str):
        super().__init__(
            name=name,
            type='interface',
            capabilities=['display', 'capture_input', 'navigate'],
            state={'device_type': device_type, 'screen_size': None}
        )

def create_actor(actor_type: str, **kwargs) -> Actor:
    """Factory function to create appropriate actor instances"""
    if actor_type == 'healthcare_organisation':
        return HumanActor(
            name=f"Healthcare Org {kwargs.get('id', '001')}",
            role='customer'
        )
    elif actor_type == 'sales_team':
        return HumanActor(name='Sales Representative', role='sales')
    elif actor_type == 'crm_system':
        return SystemActor(name='CRM', service_url='http://api.crm.local')
    elif actor_type == 'mobile_interface':
        return InterfaceActor(name='Mobile App', device_type='mobile')
    else:
        raise ValueError(f"Unknown actor type: {actor_type}")
```

#### Day 2: Cross-Scenario Testing
```bash
# 2. Create cross-scenario test execution
```

**Scenario Engine** (`test_helpers/scenario_engine.py`):
```python
class ScenarioEngine:
    def __init__(self):
        self.active_scenarios = {}
        self.actor_registry = {}
        self.cross_references = {}
        
    def register_actor(self, actor: Actor):
        self.actor_registry[actor.name] = actor
        
    def execute_scenario(self, scenario_id: str, scenario_type: str, context) -> Dict:
        """Execute a scenario and return results"""
        
        # Determine scenario execution method
        if scenario_type == 'Technical':
            return self._execute_technical_scenario(scenario_id, context)
        elif scenario_type == 'UX':
            return self._execute_ux_scenario(scenario_id, context)
        else:
            return self._execute_business_scenario(scenario_id, context)
            
    def _execute_technical_scenario(self, scenario_id: str, context) -> Dict:
        """Execute technical scenario with system actors"""
        
        if scenario_id == 'T_S001_US001':
            # CRM logging scenario
            crm = self.actor_registry.get('CRM System')
            if not crm:
                crm = create_actor('crm_system')
                self.register_actor(crm)
                
            # Execute CRM logging
            log_data = {
                'prospect_id': context.healthcare_org.state.get('id'),
                'interaction_type': 'cold_call',
                'outcome': context.call_result.status,
                'timestamp': datetime.now().isoformat()
            }
            
            result = crm.process_request(log_data)
            return {
                'status': 'CRM logging successful' if result.get('success') else 'CRM logging failed',
                'details': result
            }
            
    def validate_cross_references(self, scenario_id: str) -> List[str]:
        """Validate all cross-referenced scenarios are properly linked"""
        errors = []
        
        if scenario_id in self.cross_references:
            for ref_scenario in self.cross_references[scenario_id]:
                if not self._scenario_exists(ref_scenario):
                    errors.append(f"Referenced scenario {ref_scenario} does not exist")
                    
        return errors
        
    def generate_scenario_graph(self) -> Dict:
        """Generate dependency graph of all scenarios"""
        # Implementation for visualizing scenario relationships
        pass
```

#### Day 3: Phoenix Integration Tests
```bash
# 3. Integrate with Phoenix test suite
```

**Phoenix BDD Test Module** (`test/bdd/scenario_test.exs`):
```elixir
defmodule BemedaPersonal.BDD.ScenarioTest do
  use BemedaPersonal.DataCase
  use ExUnit.Case
  
  alias BemedaPersonal.BDD.ScenarioRunner
  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Companies
  
  describe "Business Scenario B_S001" do
    setup do
      # Create test actors
      {:ok, sales_user} = create_sales_user()
      {:ok, healthcare_org} = create_healthcare_org() 
      
      %{
        sales_user: sales_user,
        healthcare_org: healthcare_org,
        scenario_context: %{}
      }
    end
    
    test "B_S001_US001: Organisation Receives Cold Call", %{sales_user: sales_user, healthcare_org: healthcare_org} do
      # Given: Prerequisites are met
      assert sales_user.role == "sales"
      assert healthcare_org.status == "prospect"
      
      # When: Sales team makes contact  
      {:ok, interaction} = ScenarioRunner.execute_step(
        "sales_team_calls_organisation",
        %{caller: sales_user, recipient: healthcare_org}
      )
      
      # Then: Expected outcomes
      assert interaction.status == "successful"
      assert interaction.understanding_level >= 8
      assert interaction.next_action == "schedule_discussion"
      
      # And: Parallel scenarios execute
      assert ScenarioRunner.execute_parallel_scenario("T_S001_US001", interaction) == :ok
      assert ScenarioRunner.execute_parallel_scenario("U_S001_US001", interaction) == :ok
    end
    
    test "Cross-scenario dependency validation" do
      dependencies = ScenarioRunner.get_dependencies("B_S001")
      
      assert "T_S001" in dependencies
      assert "U_S001" in dependencies
      
      # Ensure all dependencies are satisfied
      Enum.each(dependencies, fn dep_id ->
        assert ScenarioRunner.scenario_exists?(dep_id)
      end)
    end
  end
  
  defp create_sales_user do
    Accounts.create_user(%{
      email: "sales@bemeda.test",
      password: "test123",
      role: "sales",
      confirmed_at: DateTime.utc_now()
    })
  end
  
  defp create_healthcare_org do
    Companies.create_company(%{
      name: "Test Hospital",
      email: "hr@testhospital.test", 
      status: "prospect"
    })
  end
end
```

### Deliverables:
- ✅ Actor-based test framework (Python & Elixir)
- ✅ Cross-scenario execution engine
- ✅ Phoenix integration test suite
- ✅ Scenario dependency validation

---

## 🔗 Iteration 4: Cross-Reference Automation
**Duration**: 3 days
**Goal**: Automate scenario relationship management and validation

### Actions to Execute:

#### Day 1: Relationship Validation System
```bash
# 1. Create automated relationship validation
```

**Relationship Validator** (`scripts/validate_scenario_relationships.py`):
```python
import json
import re
from typing import Dict, List, Set
from dataclasses import dataclass

@dataclass  
class ScenarioRelationship:
    parent_id: str
    child_id: str
    relationship_type: str  # 'parallel', 'dependency', 'inheritance'
    strength: float  # 0.0-1.0, how critical the relationship is

class RelationshipValidator:
    def __init__(self, github_token: str):
        self.github_token = github_token
        self.relationships: List[ScenarioRelationship] = []
        self.scenario_cache = {}
        
    def discover_relationships(self) -> List[ScenarioRelationship]:
        """Auto-discover relationships from GitHub issues"""
        scenarios = self._fetch_all_scenarios()
        relationships = []
        
        for scenario in scenarios:
            # Check for parallel scenarios
            parallel_refs = self._extract_parallel_references(scenario['body'])
            for ref in parallel_refs:
                relationships.append(ScenarioRelationship(
                    parent_id=scenario['number'],
                    child_id=ref,
                    relationship_type='parallel',
                    strength=0.9
                ))
                
            # Check for dependency references  
            dep_refs = self._extract_dependency_references(scenario['body'])
            for ref in dep_refs:
                relationships.append(ScenarioRelationship(
                    parent_id=scenario['number'], 
                    child_id=ref,
                    relationship_type='dependency',
                    strength=0.8
                ))
                
            # Check for inheritance patterns
            if 'inherits_from' in scenario.get('labels', []):
                parent_ref = self._extract_inheritance_reference(scenario['body'])
                if parent_ref:
                    relationships.append(ScenarioRelationship(
                        parent_id=parent_ref,
                        child_id=scenario['number'],
                        relationship_type='inheritance', 
                        strength=0.7
                    ))
        
        return relationships
        
    def validate_relationships(self, relationships: List[ScenarioRelationship]) -> List[str]:
        """Validate that all referenced scenarios exist and are properly configured"""
        errors = []
        
        for rel in relationships:
            # Check parent exists
            if not self._scenario_exists(rel.parent_id):
                errors.append(f"Parent scenario {rel.parent_id} does not exist")
                
            # Check child exists  
            if not self._scenario_exists(rel.child_id):
                errors.append(f"Child scenario {rel.child_id} does not exist")
                
            # Check relationship validity
            parent_type = self._get_scenario_type(rel.parent_id)
            child_type = self._get_scenario_type(rel.child_id)
            
            if rel.relationship_type == 'parallel':
                if not self._valid_parallel_relationship(parent_type, child_type):
                    errors.append(f"Invalid parallel relationship: {parent_type} -> {child_type}")
                    
        return errors
        
    def generate_relationship_graph(self) -> Dict:
        """Generate Mermaid graph of scenario relationships"""
        relationships = self.discover_relationships()
        
        graph_lines = ["graph TD"]
        
        # Add nodes
        scenarios = self._fetch_all_scenarios()
        for scenario in scenarios:
            scenario_type = self._get_scenario_type(scenario['number'])
            color = {
                'B_S': '#3b82f6',  # Blue for business
                'T_S': '#10b981',  # Green for technical  
                'U_S': '#ec4899'   # Pink for UX
            }.get(scenario_type, '#6b7280')
            
            graph_lines.append(f"    {scenario['number']}[{scenario['title']}]")
            graph_lines.append(f"    style {scenario['number']} fill:{color}")
            
        # Add relationships
        for rel in relationships:
            arrow_style = {
                'parallel': '-.->',
                'dependency': '-->',
                'inheritance': '==>',  
            }.get(rel.relationship_type, '-->')
            
            graph_lines.append(f"    {rel.parent_id} {arrow_style} {rel.child_id}")
            
        return {
            'mermaid': '\n'.join(graph_lines),
            'relationships': [rel.__dict__ for rel in relationships]
        }

    def _extract_parallel_references(self, body: str) -> List[str]:
        """Extract parallel scenario references from issue body"""
        pattern = r'scenario\s+([TBU]_S\d{3}(?:_[A-Z]{2}\d{3})?)\s+should execute'
        matches = re.findall(pattern, body, re.IGNORECASE)
        return matches
        
    def _valid_parallel_relationship(self, parent_type: str, child_type: str) -> bool:
        """Check if parallel relationship is valid"""
        valid_combinations = [
            ('B_S', 'T_S'),  # Business triggers technical
            ('B_S', 'U_S'),  # Business triggers UX
            ('T_S', 'U_S')   # Technical triggers UX updates
        ]
        return (parent_type, child_type) in valid_combinations
```

#### Day 2: Automated Sync System
```bash
# 2. Create automated GitHub sync
```

**GitHub Sync Automation** (`.github/workflows/scenario-sync.yml`):
```yaml
name: Scenario Relationship Sync
on:
  issues:
    types: [opened, edited, closed]
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  sync-relationships:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Install Dependencies
        run: |
          pip install requests python-dotenv
          
      - name: Validate Scenario Relationships
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          python scripts/validate_scenario_relationships.py \
            --repo ${{ github.repository }} \
            --output validation-report.json
            
      - name: Update Relationship Graph
        run: |
          python scripts/generate_scenario_graph.py \
            --input validation-report.json \
            --output docs/scenario-relationships.md
            
      - name: Update Project Relationships
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          python scripts/update_project_relationships.py \
            --project-id ${{ vars.PROJECT_ID }} \
            --relationships validation-report.json
            
      - name: Comment on Issues with Validation Errors
        if: failure()
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          python scripts/comment_validation_errors.py \
            --validation-report validation-report.json
            
      - name: Commit Updated Documentation
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add docs/scenario-relationships.md
          git commit -m "Update scenario relationship graph" || exit 0
          git push
```

#### Day 3: Dashboard Integration  
```bash
# 3. Integrate with documentation dashboard
```

**Scenario Dashboard Update** (`scripts/update_dashboard.py`):
```python
def update_scenario_dashboard():
    """Update the main documentation dashboard with relationship data"""
    
    # Load relationship data
    with open('validation-report.json', 'r') as f:
        validation_data = json.load(f)
        
    # Generate dashboard metrics
    metrics = {
        'total_scenarios': len(validation_data['scenarios']),
        'business_scenarios': len([s for s in validation_data['scenarios'] if s['type'] == 'B_S']),
        'technical_scenarios': len([s for s in validation_data['scenarios'] if s['type'] == 'T_S']), 
        'ux_scenarios': len([s for s in validation_data['scenarios'] if s['type'] == 'U_S']),
        'relationship_health': validation_data['validation_score'],
        'broken_relationships': len(validation_data['errors'])
    }
    
    # Update dashboard HTML
    dashboard_template = """
    <div class="scenario-health-dashboard">
        <h3>Scenario System Health</h3>
        <div class="metrics-grid">
            <div class="metric-card">
                <span class="metric-value">{total_scenarios}</span>
                <span class="metric-label">Total Scenarios</span>
            </div>
            <div class="metric-card business">
                <span class="metric-value">{business_scenarios}</span>
                <span class="metric-label">Business (B_S)</span>
            </div>
            <div class="metric-card technical">
                <span class="metric-value">{technical_scenarios}</span>
                <span class="metric-label">Technical (T_S)</span>
            </div>
            <div class="metric-card ux">
                <span class="metric-value">{ux_scenarios}</span>
                <span class="metric-label">UX (U_S)</span>
            </div>
            <div class="metric-card health">
                <span class="metric-value">{relationship_health:.0%}</span>
                <span class="metric-label">Relationship Health</span>
            </div>
        </div>
    </div>
    """.format(**metrics)
    
    # Update main index.html
    with open('docs/index.html', 'r') as f:
        content = f.read()
        
    # Replace dashboard section
    updated_content = re.sub(
        r'<div class="dashboard-preview">.*?</div>',
        dashboard_template,
        content,
        flags=re.DOTALL
    )
    
    with open('docs/index.html', 'w') as f:
        f.write(updated_content)
```

### Deliverables:
- ✅ Automated relationship discovery and validation
- ✅ GitHub Actions workflow for continuous sync
- ✅ Visual relationship graph generation
- ✅ Dashboard integration with health metrics

---

## 📚 Iteration 5: Documentation & Templates
**Duration**: 2 days
**Goal**: Create comprehensive integration documentation and reusable templates

### Actions to Execute:

#### Day 1: Integration Guide Completion
```bash
# 1. Complete integration documentation
```

**Files to Create**:
- `integration/implementation-guide/github-setup.md`
- `integration/implementation-guide/project-structure.md`
- `integration/implementation-guide/automation-workflows.md`
- `integration/theoretical-framework/scenario-hierarchy.md`
- `integration/theoretical-framework/component-relationships.md`

#### Day 2: Reusable Templates
```bash
# 2. Create project templates
```

**Repository Template Structure**:
```
.github/
├── ISSUE_TEMPLATE/
│   ├── bdd-business-scenario.yml
│   ├── bdd-technical-scenario.yml
│   └── bdd-ux-scenario.yml
├── workflows/
│   ├── bdd-validation.yml
│   ├── scenario-sync.yml  
│   └── dashboard-update.yml
└── PROJECT_TEMPLATE/
    ├── docs/
    │   ├── business/
    │   ├── technical/
    │   └── uxui/
    ├── features/
    │   ├── business/
    │   ├── technical/
    │   └── ux/
    ├── tests/
    │   └── bdd/
    └── scripts/
        ├── validate_scenario_relationships.py
        ├── generate_scenario_graph.py
        └── update_dashboard.py
```

### Deliverables:
- ✅ Complete integration guide with step-by-step instructions
- ✅ Reusable repository template for new projects
- ✅ Template scenarios for common patterns
- ✅ Migration guide for existing projects

---

## 🎨 Iteration 6: UI Enhancement & Polish
**Duration**: 2 days  
**Goal**: Enhance UI with cleaner design and better scenario visualization

### Actions to Execute:

#### Day 1: UI Component Enhancement
```bash  
# 1. Create enhanced scenario cards and navigation
```

**Enhanced Scenario Cards** (update existing CSS):
```css
/* Enhanced scenario cards with BDD status */
.scenario-card {
    position: relative;
    background: white;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    transition: all 0.3s ease;
    border-left: 4px solid var(--scenario-color);
}

.scenario-card.bdd-passing::before {
    content: "✅ BDD Passing";
    position: absolute;
    top: 8px;
    right: 8px;
    background: #10b981;
    color: white;
    font-size: 0.75rem;
    padding: 2px 8px;
    border-radius: 4px;
}

.scenario-card.bdd-failing::before {
    content: "❌ BDD Failing";
    position: absolute; 
    top: 8px;
    right: 8px;
    background: #ef4444;
    color: white;
    font-size: 0.75rem;
    padding: 2px 8px;
    border-radius: 4px;
}

.actor-badges {
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
    margin: 8px 0;
}

.actor-badge {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    background: var(--actor-color);
    color: white;
    padding: 2px 8px;
    border-radius: 12px;
    font-size: 0.75rem;
}

.actor-badge.human { --actor-color: #3b82f6; }
.actor-badge.system { --actor-color: #10b981; }  
.actor-badge.interface { --actor-color: #ec4899; }

.relationship-indicators {
    display: flex;
    gap: 8px;
    margin-top: 8px;
}

.parallel-indicator {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    font-size: 0.75rem;
    color: #6b7280;
    text-decoration: none;
}

.parallel-indicator:hover {
    color: var(--scenario-color);
}
```

#### Day 2: Scenario Visualization Dashboard
```bash
# 2. Create interactive scenario relationship dashboard
```

**Interactive Dashboard** (`docs/assets/js/scenario-dashboard.js`):
```javascript
class ScenarioDashboard {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.scenarios = [];
        this.relationships = [];
        this.filters = {
            type: 'all',
            status: 'all',
            actor: 'all'
        };
    }
    
    async loadData() {
        // Load scenario data from GitHub API
        const response = await fetch('/api/scenarios/summary');
        const data = await response.json();
        
        this.scenarios = data.scenarios;
        this.relationships = data.relationships;
        
        this.render();
    }
    
    render() {
        const filteredScenarios = this.applyFilters();
        
        this.container.innerHTML = `
            <div class="dashboard-header">
                <h2>Scenario Relationship Dashboard</h2>
                <div class="dashboard-filters">
                    ${this.renderFilters()}
                </div>
            </div>
            
            <div class="dashboard-metrics">
                ${this.renderMetrics()}
            </div>
            
            <div class="dashboard-content">
                <div class="scenario-graph">
                    ${this.renderScenarioGraph()}
                </div>
                <div class="scenario-list">
                    ${this.renderScenarioList(filteredScenarios)}
                </div>
            </div>
        `;
        
        this.attachEventListeners();
    }
    
    renderScenarioGraph() {
        // Generate Mermaid graph visualization
        const graphDefinition = this.generateMermaidGraph();
        
        return `
            <div class="graph-container">
                <div class="mermaid">
                    ${graphDefinition}
                </div>
            </div>
        `;
    }
    
    generateMermaidGraph() {
        let graph = 'graph TD\n';
        
        // Add scenario nodes
        this.scenarios.forEach(scenario => {
            const nodeId = scenario.id.replace(/[^A-Z0-9]/g, '');
            const color = this.getScenarioColor(scenario.type);
            
            graph += `    ${nodeId}["${scenario.title}"]\n`;
            graph += `    style ${nodeId} fill:${color}\n`;
        });
        
        // Add relationship edges
        this.relationships.forEach(rel => {
            const parentId = rel.parent_id.replace(/[^A-Z0-9]/g, '');
            const childId = rel.child_id.replace(/[^A-Z0-9]/g, '');
            const arrow = rel.type === 'parallel' ? '-..->' : '-->';
            
            graph += `    ${parentId} ${arrow} ${childId}\n`;
        });
        
        return graph;
    }
    
    renderScenarioList(scenarios) {
        return scenarios.map(scenario => `
            <div class="scenario-summary-card ${scenario.type.toLowerCase()}-card">
                <div class="card-header">
                    <span class="scenario-id">${scenario.id}</span>
                    <span class="bdd-status ${scenario.bdd_status}">${scenario.bdd_status}</span>
                </div>
                <h4>${scenario.title}</h4>
                <div class="actor-list">
                    ${scenario.actors.map(actor => 
                        `<span class="actor-tag ${actor.type}">${actor.name}</span>`
                    ).join('')}
                </div>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${scenario.completion}%"></div>
                </div>
            </div>
        `).join('');
    }
    
    applyFilters() {
        return this.scenarios.filter(scenario => {
            if (this.filters.type !== 'all' && !scenario.type.includes(this.filters.type)) {
                return false;
            }
            if (this.filters.status !== 'all' && scenario.status !== this.filters.status) {
                return false;
            }
            if (this.filters.actor !== 'all' && !scenario.actors.some(a => a.type === this.filters.actor)) {
                return false;
            }
            return true;
        });
    }
}

// Initialize dashboard on page load
document.addEventListener('DOMContentLoaded', () => {
    const dashboard = new ScenarioDashboard('scenario-dashboard');
    dashboard.loadData();
});
```

### Deliverables:
- ✅ Enhanced UI components with BDD status indicators
- ✅ Interactive scenario relationship dashboard
- ✅ Improved navigation and filtering
- ✅ Mobile-responsive design enhancements

---

## 🎯 Final Deliverables Summary

### **GitHub-First System**
- ✅ Advanced issue templates with BDD support
- ✅ Custom project views for actor-based filtering  
- ✅ Automated workflows for scenario validation
- ✅ Cross-reference management and health monitoring

### **BDD Integration**
- ✅ Gherkin scenario format with executable step definitions
- ✅ Multi-language test support (Python, Elixir, JavaScript)
- ✅ Automated BDD test execution via GitHub Actions
- ✅ Living documentation that stays in sync with code

### **Actor-Based Architecture**
- ✅ Three scenario types (B_S, T_S, U_S) with clear actor definitions
- ✅ Parallel scenario execution and validation
- ✅ Cross-scenario relationship management
- ✅ Actor interaction testing framework

### **Reusable Templates**
- ✅ Complete project template for new implementations
- ✅ Step-by-step integration guide
- ✅ Migration templates for existing projects  
- ✅ Repository templates with pre-configured workflows

### **Enhanced UI**
- ✅ Clean, modern interface with scenario status indicators
- ✅ Interactive relationship dashboard
- ✅ Real-time BDD test status display
- ✅ Mobile-responsive design

---

## 🚀 Getting Started

**To execute this roadmap**:

1. **Choose starting iteration** (recommended: Iteration 1)
2. **Set up development environment** with GitHub CLI and appropriate permissions
3. **Follow day-by-day action items** in sequence
4. **Test each iteration** before proceeding to the next
5. **Customize templates** for your specific project needs

**Estimated effort**: 2-3 weeks for complete implementation
**Team size**: 1-2 developers + 1 product owner for testing
**Prerequisites**: GitHub Pro/Enterprise account, development environment access

This roadmap transforms your existing system into a world-class, GitHub-first, BDD + Actor scenario framework that will be reusable across any future project! 🌟

<function_calls>
<invoke name="TodoWrite">
<parameter name="todos">[{"id": "1", "content": "Analyze GitHub features for our BDD + Actor scenario system", "status": "completed", "priority": "high"}, {"id": "2", "content": "Map GitHub sub-issues and project views to B_S/T_S/U_S structure", "status": "completed", "priority": "high"}, {"id": "3", "content": "Analyze existing Phoenix project elements", "status": "completed", "priority": "high"}, {"id": "4", "content": "Create integration documentation framework", "status": "completed", "priority": "medium"}, {"id": "5", "content": "Design reusable project template", "status": "completed", "priority": "high"}, {"id": "6", "content": "Plan iterative implementation actions", "status": "completed", "priority": "high"}]