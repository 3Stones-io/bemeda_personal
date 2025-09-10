# 🚀 USE + BDD Integration Proposal for BemedaPersonal Platform

## Executive Summary

This proposal outlines a step-by-step integration plan to transform BemedaPersonal platform features into executable BDD tests using your USE (Unified Scenario Engineering) methodology. The integration will create a GitHub Actions-powered workflow that automatically generates Cucumber tests from USE steps.

---

## 🎯 Integration Overview

### What We're Building
A **GitHub-first BDD test generation system** that:
- Maps BemedaPersonal features to USE actors and steps
- Automatically generates Cucumber feature files from USE components
- Creates executable test suites from GitHub issues
- Provides full traceability from business scenarios to technical tests

### Key Benefits
- **Business-Friendly**: USE steps remain readable and business-focused
- **Technical Power**: Automatic generation of executable BDD tests
- **GitHub Integration**: Leverages existing issue-based workflow
- **Full Traceability**: Links from scenarios → steps → tests → code

---

## 📊 BemedaPersonal Feature Analysis

### Platform Actors (USE Mapping)

| USE Actor | BemedaPersonal Role | Key Features |
|-----------|-------------------|--------------|
| **A1** - Organisation | Employer/Hiring Manager | Job posting, candidate management, offers |
| **A2** - JobSeeker | Healthcare Professional | Job search, applications, profile management |
| **A3** - Platform Admin | System Administrator | User management, platform configuration |
| **A4** - HR Manager | HR Department Staff | Contract management, onboarding |

### Feature Categories

1. **Job Discovery & Search**
   - Advanced filtering (location, specialty, salary)
   - 27 healthcare professions
   - Multi-language support (DE, EN, FR, IT)

2. **Application Management**
   - One-click applications
   - Video applications
   - Status tracking
   - Duplicate prevention

3. **Communication**
   - Real-time messaging
   - Email notifications
   - Multi-language communication

4. **Contract & Offers**
   - Digital signatures
   - Template management
   - Automated workflows

---

## 🔄 Step-by-Step Integration Plan

### Phase 1: USE Step Mapping (Week 1)

#### 1.1 Create Actor-Based Step Definitions

For each BemedaPersonal feature, create USE steps following this pattern:

```markdown
# Example: Job Search Feature

## Actor: A2 (JobSeeker)

### Step: S2_A2_1 - Search for Healthcare Positions
**Description**: JobSeeker searches for relevant healthcare positions
**Technical Components**:
- TC001: Search API endpoint
- TC002: Filter processing service
- TC003: Location-based search algorithm
**UX Components**:
- UX001: Search interface
- UX002: Filter sidebar
- UX003: Results listing
**BDD Mapping**:
- Feature: job_search.feature
- Scenarios: basic_search, filtered_search, location_search
```

#### 1.2 Create Component Templates

```yaml
# .github/ISSUE_TEMPLATE/use-step-definition.yml
name: USE Step Definition
description: Define a USE step with BDD mapping
labels: ["use-step", "bdd-ready"]
body:
  - type: input
    id: step_id
    label: Step ID
    description: "Format: S[scenario]_A[actor]_[number]"
    placeholder: "S1_A2_1"
    validations:
      required: true
      
  - type: input
    id: step_title
    label: Step Title
    placeholder: "Search for Healthcare Positions"
    validations:
      required: true
      
  - type: textarea
    id: gherkin_scenarios
    label: Gherkin Scenarios
    description: "Define Given-When-Then scenarios"
    placeholder: |
      Scenario: Basic job search
        Given I am a registered nurse
        When I search for "nurse" positions
        Then I should see relevant nursing jobs
      
  - type: textarea
    id: technical_components
    label: Technical Components
    placeholder: "TC001: Search API, TC002: Filter Service"
```

### Phase 2: BDD Test Generation System (Week 2)

#### 2.1 GitHub Actions Workflow

```yaml
# .github/workflows/generate-bdd-tests.yml
name: Generate BDD Tests from USE Steps

on:
  issues:
    types: [labeled, unlabeled]
  workflow_dispatch:
    inputs:
      actor:
        description: 'Actor to generate tests for'
        required: false
        type: choice
        options:
          - A1-Organisation
          - A2-JobSeeker
          - A3-Admin
          - A4-HRManager
          - All

jobs:
  generate-tests:
    runs-on: ubuntu-latest
    if: contains(github.event.issue.labels.*.name, 'bdd-ready')
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Parse USE Step from Issue
        id: parse
        uses: actions/github-script@v7
        with:
          script: |
            const issue = context.payload.issue;
            const body = issue.body;
            
            // Parse step components
            const stepId = body.match(/Step ID:\s*(.+)/)?.[1];
            const scenarios = body.match(/Gherkin Scenarios:\s*```([\s\S]+?)```/)?.[1];
            
            return {
              stepId,
              scenarios,
              actor: stepId.match(/A(\d+)/)?.[1]
            };
      
      - name: Generate Feature File
        run: |
          python scripts/generate_bdd_feature.py \
            --step-id "${{ steps.parse.outputs.stepId }}" \
            --scenarios "${{ steps.parse.outputs.scenarios }}" \
            --output "test/features/generated/"
      
      - name: Generate Step Definitions
        run: |
          python scripts/generate_step_definitions.py \
            --feature "test/features/generated/${{ steps.parse.outputs.stepId }}.feature" \
            --lang "elixir" \
            --output "test/features/step_definitions/"
      
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          title: "BDD Tests for ${{ steps.parse.outputs.stepId }}"
          body: |
            Auto-generated BDD tests for USE step ${{ steps.parse.outputs.stepId }}
            
            - Feature file: `test/features/generated/${{ steps.parse.outputs.stepId }}.feature`
            - Step definitions: `test/features/step_definitions/${{ steps.parse.outputs.stepId }}_steps.exs`
          branch: bdd-tests/${{ steps.parse.outputs.stepId }}
```

#### 2.2 Test Generation Scripts

```python
# scripts/generate_bdd_feature.py
import argparse
import json
from pathlib import Path

def generate_feature(step_id, scenarios, bemeda_features):
    """Generate Cucumber feature file from USE step"""
    
    actor_map = {
        'A1': 'Employer',
        'A2': 'Healthcare Professional',
        'A3': 'Platform Administrator',
        'A4': 'HR Manager'
    }
    
    # Parse actor from step ID
    actor_code = step_id.split('_')[1]
    actor_name = actor_map.get(actor_code, 'User')
    
    feature_content = f"""Feature: {step_id} - {actor_name} Workflow
  As a {actor_name}
  I want to complete this workflow step
  So that I can achieve my goal in the platform

  Background:
    Given I am logged in as a {actor_name}
    And I have necessary permissions

"""
    
    # Add scenarios from issue
    feature_content += scenarios
    
    return feature_content
```

### Phase 3: BemedaPersonal Feature Mapping (Week 3)

#### 3.1 Core User Journeys to USE Steps

**Journey 1: Healthcare Professional Job Application**

```yaml
Scenario: S1 - Healthcare Job Application Process
Actors:
  - A2 (JobSeeker): Healthcare Professional
  - A1 (Organisation): Hospital HR

Steps:
  S1_A2_1: Create Professional Profile
    Technical: TC_ProfileService, TC_ValidationEngine
    BDD: profile_creation.feature
    
  S1_A2_2: Search for Positions
    Technical: TC_SearchAPI, TC_FilterEngine
    BDD: job_search.feature
    
  S1_A2_3: Submit Application
    Technical: TC_ApplicationService, TC_DocumentStorage
    BDD: application_submission.feature
    
  S1_A1_1: Review Applications
    Technical: TC_DashboardAPI, TC_FilteringService
    BDD: application_review.feature
    
  S1_A1_2: Schedule Interview
    Technical: TC_SchedulingService, TC_NotificationEngine
    BDD: interview_scheduling.feature
```

#### 3.2 Technical Component Definitions

```yaml
# TC001: Search API
component:
  id: TC001
  type: technical
  title: Job Search API
  use_steps: [S1_A2_2, S2_A2_1]
  endpoints:
    - GET /api/jobs/search
    - POST /api/jobs/filter
  bdd_tests:
    - job_search.feature
    - advanced_filtering.feature
```

### Phase 4: Implementation Workflow (Week 4)

#### 4.1 Developer Workflow

1. **Business Definition** (Product Owner)
   - Creates USE step in GitHub issue
   - Defines business scenarios in plain language

2. **Technical Mapping** (Developer)
   - Tags issue with `needs-tech-mapping`
   - Adds technical components
   - Converts to Gherkin scenarios

3. **Automated Generation** (GitHub Actions)
   - Detects `bdd-ready` label
   - Generates feature files
   - Creates step definitions
   - Opens PR for review

4. **Implementation** (Developer)
   - Implements step definitions
   - Links to actual code
   - Runs tests

#### 4.2 Tracking Dashboard

```html
<!-- docs/bdd-dashboard.html -->
<div class="bdd-status">
  <h2>BDD Test Coverage</h2>
  <table>
    <tr>
      <th>USE Step</th>
      <th>Actor</th>
      <th>BDD Status</th>
      <th>Test Coverage</th>
    </tr>
    <tr>
      <td>S1_A2_1</td>
      <td>JobSeeker</td>
      <td>✅ Generated</td>
      <td>85%</td>
    </tr>
  </table>
</div>
```

---

## 🛠️ Technical Implementation Details

### Repository Structure

```
bemeda-bdd-playground/
├── .github/
│   ├── workflows/
│   │   ├── generate-bdd-tests.yml
│   │   └── run-bdd-tests.yml
│   └── ISSUE_TEMPLATE/
│       └── use-step-definition.yml
├── scripts/
│   ├── generate_bdd_feature.py
│   ├── generate_step_definitions.py
│   └── map_use_to_bdd.py
├── test/
│   └── features/
│       ├── generated/           # Auto-generated features
│       ├── step_definitions/    # Auto-generated + custom steps
│       └── support/             # Test helpers
├── docs/
│   ├── use-mapping/            # USE to BDD mapping docs
│   └── bdd-dashboard.html      # Coverage dashboard
└── config/
    └── bdd_mappings.json       # Configuration
```

### Tagging Strategy

```yaml
Labels for GitHub Issues:
  # Step Status
  - use-step              # Identifies USE step issues
  - needs-tech-mapping    # Awaiting technical components
  - bdd-ready            # Ready for test generation
  - tests-generated      # Tests have been generated
  - tests-implemented    # Step definitions implemented
  
  # Actor Labels
  - actor:organisation
  - actor:jobseeker
  - actor:admin
  - actor:hr-manager
  
  # Feature Areas
  - feature:job-search
  - feature:application
  - feature:messaging
  - feature:contracts
```

### Example Generated Output

**Input USE Step:**
```markdown
Step ID: S1_A2_2
Title: Search for Healthcare Positions
Actor: JobSeeker
Scenarios:
  - Search by specialty
  - Filter by location
  - Sort by salary
```

**Generated Feature File:**
```gherkin
Feature: S1_A2_2 - Healthcare Professional Job Search
  As a Healthcare Professional
  I want to search for relevant positions
  So that I can find suitable job opportunities

  Background:
    Given I am logged in as a Healthcare Professional
    And I am on the job search page

  @smoke @job-search
  Scenario: Search by medical specialty
    When I select "Registered Nurse" from specialty filter
    And I click "Search"
    Then I should see jobs for registered nurses
    And each job should match my specialty

  @job-search @filtering
  Scenario: Filter by location
    Given there are jobs in multiple locations
    When I set location to "Zurich"
    And I set distance to "25 km"
    Then I should only see jobs within 25km of Zurich
```

---

## 📈 Success Metrics

### Phase 1 Success Criteria
- ✅ All BemedaPersonal features mapped to USE steps
- ✅ Technical components identified for each step
- ✅ Gherkin scenarios defined for core workflows

### Phase 2 Success Criteria
- ✅ GitHub Actions workflow operational
- ✅ Automatic feature file generation working
- ✅ Step definition templates created

### Phase 3 Success Criteria
- ✅ Core user journeys fully mapped
- ✅ 80% of platform features have USE steps
- ✅ Test generation for all mapped features

### Phase 4 Success Criteria
- ✅ Developer workflow documented
- ✅ Dashboard showing test coverage
- ✅ First end-to-end test suite running

---

## 🚀 Next Steps

1. **Create Playground Repository**
   ```bash
   gh repo create bemeda-bdd-playground --public
   ```

2. **Set Up Initial Structure**
   - Copy workflow templates
   - Create first USE step issues
   - Test generation workflow

3. **Map First Feature**
   - Start with Job Search (most complex)
   - Create all related USE steps
   - Generate and implement tests

4. **Iterate and Improve**
   - Gather feedback
   - Refine generation scripts
   - Expand to all features

---

## 🎯 Summary

This integration creates a powerful bridge between your business-focused USE methodology and technical BDD testing. By leveraging GitHub as the single source of truth, you maintain simplicity while gaining the benefits of executable specifications and automated testing.

The key innovation is using GitHub Actions to automatically transform business-defined steps into technical tests, ensuring that your documentation stays in sync with your implementation.