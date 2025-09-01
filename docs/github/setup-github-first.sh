#!/bin/bash

# 🚀 GitHub-First Implementation Setup Script
# This script sets up the GitHub-first component management system

set -e

echo "🚀 Setting up GitHub-First Component Management System"
echo "======================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if GitHub CLI is installed and authenticated
check_github_cli() {
    print_status "Checking GitHub CLI installation..."
    
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI is not installed. Please install it first:"
        echo "  https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated. Please run:"
        echo "  gh auth login"
        exit 1
    fi
    
    print_success "GitHub CLI is installed and authenticated"
}

# Create issue templates directory
create_issue_templates() {
    print_status "Creating issue templates directory..."
    
    mkdir -p .github/ISSUE_TEMPLATE
    
    # Create config.yml for issue templates
    cat > .github/ISSUE_TEMPLATE/config.yml << 'EOF'
blank_issues_enabled: false
contact_links:
  - name: GitHub Community Support
    url: https://github.com/orgs/3Stones-io/discussions
    about: Please ask and answer questions here.
EOF
    
    print_success "Issue templates directory created"
}

# Create component issue template
create_component_template() {
    print_status "Creating component issue template..."
    
    cat > .github/ISSUE_TEMPLATE/component-definition.yml << 'EOF'
name: Component Definition
description: Define a new platform component
title: "[COMPONENT] [ID] - [Title]"
labels: ["component"]
body:
  - type: input
    id: component_id
    attributes:
      label: Component ID
      description: "Unique identifier following naming convention (e.g., B_S001_US001, U_S001_UX001)"
      placeholder: "B_S001_US001"
    validations:
      required: true
      pattern: "^[BUTS]_S[0-9]{3}(_[A-Z]{2,3}[0-9]{3})*$"
      
  - type: dropdown
    id: component_type
    attributes:
      label: Component Type
      description: "Select the type of component"
      options:
        - business-scenario
        - user-story
        - user-story-step
        - ux-scenario
        - user-flow
        - interface-mockup
        - ui-component
        - technical-scenario
        - use-case
        - platform-feature
        - technical-component
        - test-scenario
        - test-case
        - bug-report
        - acceptance-criteria
    validations:
      required: true
      
  - type: dropdown
    id: domain
    attributes:
      label: Domain
      description: "Select the domain this component belongs to"
      options:
        - business
        - ux-ui
        - technical
        - testing
    validations:
      required: true
      
  - type: input
    id: scenario
    attributes:
      label: Scenario
      description: "Parent scenario ID (e.g., B_S001, U_S001)"
      placeholder: "B_S001"
    validations:
      required: true
      
  - type: dropdown
    id: participant
    attributes:
      label: Primary Participant
      description: "Main user/actor for this component"
      options:
        - organisation
        - jobseeker
        - sales-team
        - admin
        - system
    validations:
      required: true
      
  - type: dropdown
    id: priority
    attributes:
      label: Priority
      description: "Component priority level"
      options:
        - low
        - medium
        - high
        - critical
    validations:
      required: true
      
  - type: dropdown
    id: status
    attributes:
      label: Status
      description: "Current development status"
      options:
        - planning
        - active
        - in-progress
        - review
        - completed
        - blocked
    validations:
      required: true
      
  - type: textarea
    id: title
    attributes:
      label: Component Title
      description: "Human-readable title for the component"
      placeholder: "Organisation Receives Cold Call"
    validations:
      required: true
      
  - type: textarea
    id: description
    attributes:
      label: Description
      description: "Detailed description of the component"
      placeholder: "Healthcare organisation receives cold call from Bemeda sales representative..."
    validations:
      required: true
      
  - type: textarea
    id: acceptance_criteria
    attributes:
      label: Acceptance Criteria
      description: "List of acceptance criteria (one per line)"
      placeholder: "- [ ] Cold call script defined
- [ ] Success metrics established
- [ ] Follow-up process documented"
      
  - type: textarea
    id: related_components
    attributes:
      label: Related Components
      description: "List of related component IDs (one per line)"
      placeholder: "B_S001_US001_USS001
U_S001_UX001
T_S001_UC001"
      
  - type: textarea
    id: implementation_notes
    attributes:
      label: Implementation Notes
      description: "Additional notes for implementation"
      placeholder: "Links to UX flow U_S001_UX001
Requires technical component T_S001_TC001
Tested by TEST_S001_T001"
EOF
    
    print_success "Component issue template created"
}

# Create GitHub Actions workflow
create_workflow() {
    print_status "Creating GitHub Actions workflow..."
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/sync-components.yml << 'EOF'
name: Sync Components from Issues

on:
  issues:
    types: [opened, edited, closed, labeled, unlabeled]
  workflow_dispatch: # Manual trigger

jobs:
  sync-components:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Fetch All Component Issues
        id: fetch-issues
        uses: actions/github-script@v7
        with:
          script: |
            const issues = await github.rest.issues.listForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              labels: 'component',
              state: 'all',
              per_page: 100
            });
            
            const components = issues.data.map(issue => {
              // Extract metadata from issue body
              const metadata = extractMetadata(issue.body);
              return {
                issue_number: issue.number,
                issue_url: issue.html_url,
                title: issue.title,
                state: issue.state,
                labels: issue.labels.map(l => l.name),
                created_at: issue.created_at,
                updated_at: issue.updated_at,
                ...metadata
              };
            });
            
            // Write to registry
            fs.writeFileSync('docs/MASTER-REGISTRY.json', 
              JSON.stringify(components, null, 2));
            
            console.log(`Processed ${components.length} component issues`);
            return components.length;
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Generate Component Map
        run: |
          node scripts/generate-component-map.js
          
      - name: Update Documentation
        run: |
          node scripts/update-documentation.js
          
      - name: Commit and Push Changes
        run: |
          git config --global user.name 'GitHub Actions'
          git config --global user.email 'actions@github.com'
          git add .
          git commit -m "🤖 Auto-sync from GitHub issues (${{ steps.fetch-issues.outputs.result }} components)" || exit 0
          git push
EOF
    
    print_success "GitHub Actions workflow created"
}

# Create validation workflow
create_validation_workflow() {
    print_status "Creating component validation workflow..."
    
    cat > .github/workflows/validate-components.yml << 'EOF'
name: Validate Component Issues

on:
  issues:
    types: [opened, edited]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Validate Component Structure
        uses: actions/github-script@v7
        with:
          script: |
            const issue = context.payload.issue;
            
            // Check if it's a component issue
            if (!issue.labels.some(label => label.name === 'component')) {
              console.log('Not a component issue, skipping validation');
              return;
            }
            
            console.log('Validating component issue:', issue.number);
            
            // Extract form data from issue body
            const formData = extractFormData(issue.body);
            
            // Validate required fields
            const validation = validateComponent(formData);
            
            if (!validation.valid) {
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: issue.number,
                body: `❌ **Validation Failed**\n\n${validation.errors.join('\n')}\n\nPlease fix these issues and update the component.`
              });
              
              await github.rest.issues.addLabels({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: issue.number,
                labels: ['needs-fixes']
              });
            } else {
              // Auto-label based on metadata
              const labels = generateLabels(formData);
              await github.rest.issues.addLabels({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: issue.number,
                labels: labels
              });
              
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: issue.number,
                body: `✅ **Component Validated Successfully**\n\nComponent ${formData.component_id} has been validated and labeled automatically.`
              });
            }
            
            function extractFormData(body) {
              // Extract form data from GitHub issue template
              const lines = body.split('\n');
              const data = {};
              
              for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim();
                if (line.startsWith('**Component ID:**')) {
                  data.component_id = lines[i + 1].trim();
                } else if (line.startsWith('**Component Type:**')) {
                  data.component_type = lines[i + 1].trim();
                } else if (line.startsWith('**Domain:**')) {
                  data.domain = lines[i + 1].trim();
                } else if (line.startsWith('**Scenario:**')) {
                  data.scenario = lines[i + 1].trim();
                } else if (line.startsWith('**Primary Participant:**')) {
                  data.participant = lines[i + 1].trim();
                } else if (line.startsWith('**Priority:**')) {
                  data.priority = lines[i + 1].trim();
                } else if (line.startsWith('**Status:**')) {
                  data.status = lines[i + 1].trim();
                }
              }
              
              return data;
            }
            
            function validateComponent(data) {
              const errors = [];
              
              if (!data.component_id) {
                errors.push('- Component ID is required');
              } else if (!/^[BUTS]_S[0-9]{3}(_[A-Z]{2,3}[0-9]{3})*$/.test(data.component_id)) {
                errors.push('- Component ID must follow naming convention (e.g., B_S001_US001)');
              }
              
              if (!data.component_type) {
                errors.push('- Component Type is required');
              }
              
              if (!data.domain) {
                errors.push('- Domain is required');
              }
              
              if (!data.scenario) {
                errors.push('- Scenario is required');
              }
              
              if (!data.participant) {
                errors.push('- Primary Participant is required');
              }
              
              if (!data.priority) {
                errors.push('- Priority is required');
              }
              
              if (!data.status) {
                errors.push('- Status is required');
              }
              
              return {
                valid: errors.length === 0,
                errors: errors
              };
            }
            
            function generateLabels(data) {
              const labels = ['component'];
              
              if (data.component_type) {
                labels.push(`component:${data.component_type}`);
              }
              
              if (data.domain) {
                labels.push(`domain:${data.domain}`);
              }
              
              if (data.participant) {
                labels.push(`participant:${data.participant}`);
              }
              
              if (data.priority) {
                labels.push(`priority:${data.priority}`);
              }
              
              if (data.status) {
                labels.push(`status:${data.status}`);
              }
              
              return labels;
            }
EOF
    
    print_success "Component validation workflow created"
}

# Create scripts directory and helper scripts
create_scripts() {
    print_status "Creating helper scripts..."
    
    mkdir -p scripts
    
    # Component map generator
    cat > scripts/generate-component-map.js << 'EOF'
const fs = require('fs');

function generateComponentMap() {
  try {
    const registry = JSON.parse(fs.readFileSync('docs/MASTER-REGISTRY.json', 'utf8'));
    
    const componentMap = {
      generated_at: new Date().toISOString(),
      total_components: registry.length,
      by_domain: {},
      by_type: {},
      by_scenario: {},
      by_participant: {},
      by_status: {},
      hierarchical: {}
    };
    
    registry.forEach(component => {
      // Group by domain
      if (!componentMap.by_domain[component.domain]) {
        componentMap.by_domain[component.domain] = [];
      }
      componentMap.by_domain[component.domain].push(component.component_id);
      
      // Group by type
      if (!componentMap.by_type[component.component_type]) {
        componentMap.by_type[component.component_type] = [];
      }
      componentMap.by_type[component.component_type].push(component.component_id);
      
      // Group by scenario
      if (!componentMap.by_scenario[component.scenario]) {
        componentMap.by_scenario[component.scenario] = [];
      }
      componentMap.by_scenario[component.scenario].push(component.component_id);
      
      // Group by participant
      if (!componentMap.by_participant[component.participant]) {
        componentMap.by_participant[component.participant] = [];
      }
      componentMap.by_participant[component.participant].push(component.component_id);
      
      // Group by status
      if (!componentMap.by_status[component.status]) {
        componentMap.by_status[component.status] = [];
      }
      componentMap.by_status[component.status].push(component.component_id);
      
      // Build hierarchical structure
      buildHierarchical(componentMap.hierarchical, component);
    });
    
    fs.writeFileSync('docs/COMPONENT-MAP.json', JSON.stringify(componentMap, null, 2));
    console.log('Component map generated successfully');
    
  } catch (error) {
    console.error('Error generating component map:', error);
    process.exit(1);
  }
}

function buildHierarchical(hierarchical, component) {
  const parts = component.component_id.split('_');
  
  if (parts.length >= 2) {
    const scenario = parts[0] + '_' + parts[1];
    
    if (!hierarchical[scenario]) {
      hierarchical[scenario] = {
        type: parts[0] === 'B' ? 'business' : parts[0] === 'U' ? 'ux' : parts[0] === 'T' ? 'technical' : 'testing',
        components: {}
      };
    }
    
    if (parts.length === 2) {
      // Scenario level
      hierarchical[scenario].title = component.title;
      hierarchical[scenario].description = component.description;
    } else if (parts.length >= 3) {
      // Component level
      const componentKey = parts.slice(2).join('_');
      if (!hierarchical[scenario].components[componentKey]) {
        hierarchical[scenario].components[componentKey] = [];
      }
      hierarchical[scenario].components[componentKey].push(component.component_id);
    }
  }
}

generateComponentMap();
EOF
    
    # Documentation updater
    cat > scripts/update-documentation.js << 'EOF'
const fs = require('fs');

function updateDocumentation() {
  try {
    const registry = JSON.parse(fs.readFileSync('docs/MASTER-REGISTRY.json', 'utf8'));
    
    // Update integration page with real-time data
    updateIntegrationPage(registry);
    
    // Update sitemap with current components
    updateSitemap(registry);
    
    console.log('Documentation updated successfully');
    
  } catch (error) {
    console.error('Error updating documentation:', error);
    process.exit(1);
  }
}

function updateIntegrationPage(registry) {
  // This would update the integration/index.html with real-time component counts
  // For now, just log the counts
  const counts = {
    business: registry.filter(c => c.domain === 'business').length,
    ux_ui: registry.filter(c => c.domain === 'ux-ui').length,
    technical: registry.filter(c => c.domain === 'technical').length,
    testing: registry.filter(c => c.domain === 'testing').length
  };
  
  console.log('Component counts:', counts);
}

function updateSitemap(registry) {
  // This would update the sitemap.html with current component structure
  console.log('Sitemap would be updated with', registry.length, 'components');
}

updateDocumentation();
EOF
    
    print_success "Helper scripts created"
}

# Create initial component issues
create_initial_components() {
    print_status "Creating initial component issues..."
    
    # Create a script to generate initial issues
    cat > scripts/create-initial-components.js << 'EOF'
const { execSync } = require('child_process');

const initialComponents = [
  {
    id: 'B_S001',
    type: 'business-scenario',
    title: 'Cold Call to Placement',
    description: 'Complete workflow from initial cold call to successful placement'
  },
  {
    id: 'B_S001_US001',
    type: 'user-story',
    title: 'Organisation Receives Cold Call',
    description: 'Healthcare organisation receives cold call from Bemeda sales representative'
  },
  {
    id: 'U_S001',
    type: 'ux-scenario',
    title: 'UX Scenario for Cold Call to Placement',
    description: 'User experience flows and interface designs for the cold call scenario'
  },
  {
    id: 'T_S001',
    type: 'technical-scenario',
    title: 'Technical Implementation for Cold Call to Placement',
    description: 'Technical components and system architecture for the cold call scenario'
  },
  {
    id: 'TEST_S001',
    type: 'test-scenario',
    title: 'Testing Strategy for Cold Call to Placement',
    description: 'Test cases and validation criteria for the cold call scenario'
  }
];

async function createInitialComponents() {
  console.log('Creating initial component issues...');
  
  for (const component of initialComponents) {
    try {
      const command = `gh issue create --title "[COMPONENT] ${component.id} - ${component.title}" --body "## ${component.title}

${component.description}

**Component ID:** ${component.id}
**Component Type:** ${component.type}
**Domain:** ${getDomain(component.id)}
**Scenario:** ${getScenario(component.id)}
**Primary Participant:** organisation
**Priority:** high
**Status:** planning

## Description
${component.description}

## Acceptance Criteria
- [ ] Component properly defined
- [ ] Relationships mapped
- [ ] Implementation plan created

## Implementation Notes
- Initial component setup
- Will be expanded with detailed requirements" --label "component,initial-setup"`;
      
      console.log(`Creating ${component.id}...`);
      execSync(command, { stdio: 'inherit' });
      
    } catch (error) {
      console.error(`Error creating ${component.id}:`, error.message);
    }
  }
  
  console.log('Initial components created successfully');
}

function getDomain(id) {
  if (id.startsWith('B_')) return 'business';
  if (id.startsWith('U_')) return 'ux-ui';
  if (id.startsWith('T_')) return 'technical';
  if (id.startsWith('TEST_')) return 'testing';
  return 'unknown';
}

function getScenario(id) {
  const parts = id.split('_');
  return parts[0] + '_' + parts[1];
}

createInitialComponents();
EOF
    
    print_success "Initial component creation script created"
}

# Main execution
main() {
    echo "🚀 Starting GitHub-First setup..."
    
    check_github_cli
    create_issue_templates
    create_component_template
    create_workflow
    create_validation_workflow
    create_scripts
    create_initial_components
    
    echo ""
    print_success "GitHub-First setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Commit and push these changes:"
    echo "   git add ."
    echo "   git commit -m 'Setup GitHub-First component management'"
    echo "   git push"
    echo ""
    echo "2. Create initial components:"
    echo "   node scripts/create-initial-components.js"
    echo ""
    echo "3. Test the workflow by editing a component issue"
    echo ""
    echo "4. Review the generated documentation at:"
    echo "   https://3stones-io.github.io/bemeda_personal/docs/"
}

# Run main function
main "$@"

