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
    id: 'B_S001_US001_USS001',
    type: 'user-story-step',
    title: 'Organisation Receives Cold Call Step',
    description: 'Detailed step for organisation receiving cold call'
  },
  {
    id: 'U_S001',
    type: 'ux-scenario',
    title: 'UX Scenario for Cold Call to Placement',
    description: 'User experience flows and interface designs for the cold call scenario'
  },
  {
    id: 'U_S001_UX001',
    type: 'user-flow',
    title: 'Cold Call Reception Flow',
    description: 'UX flow for how healthcare organizations receive and respond to initial sales contacts'
  },
  {
    id: 'U_S001_M001',
    type: 'interface-mockup',
    title: 'Healthcare Organisation Dashboard',
    description: 'Interface mockup for the organization main dashboard after onboarding'
  },
  {
    id: 'U_S001_C001',
    type: 'ui-component',
    title: 'Navigation Bar Component',
    description: 'Reusable navigation bar component for the platform'
  },
  {
    id: 'T_S001',
    type: 'technical-scenario',
    title: 'Technical Implementation for Cold Call to Placement',
    description: 'Technical components and system architecture for the cold call scenario'
  },
  {
    id: 'T_S001_UC001',
    type: 'use-case',
    title: 'User Authentication and Registration',
    description: 'System use case for user authentication and registration processes'
  },
  {
    id: 'T_S001_F001',
    type: 'platform-feature',
    title: 'User Registration Feature',
    description: 'Feature for new user account creation and validation'
  },
  {
    id: 'T_S001_TC001',
    type: 'technical-component',
    title: 'Authentication Service',
    description: 'Backend service for user authentication and session management'
  },
  {
    id: 'TEST_S001',
    type: 'test-scenario',
    title: 'Testing Strategy for Cold Call to Placement',
    description: 'Test cases and validation criteria for the cold call scenario'
  },
  {
    id: 'TEST_S001_T001',
    type: 'test-case',
    title: 'User Registration Flow Test',
    description: 'Test case for validating the complete user registration flow'
  },
  {
    id: 'TEST_S001_B001',
    type: 'bug-report',
    title: 'Registration Validation Issues',
    description: 'Bug reports for registration form validation problems'
  },
  {
    id: 'TEST_S001_AC001',
    type: 'acceptance-criteria',
    title: 'Registration Success Criteria',
    description: 'Acceptance criteria for successful user registration flow'
  }
];

async function createInitialComponents() {
  console.log('Creating initial component issues...');
  
  for (const component of initialComponents) {
    try {
      const body = `## ${component.title}

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
- Will be expanded with detailed requirements
- Links to template: /integration/templates/${component.id.replace(/_/g, '-')}-template.html`;

      const command = `gh issue create --title "[COMPONENT] ${component.id} - ${component.title}" --body "${body.replace(/"/g, '\\"')}" --label "component,initial-setup"`;
      
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
