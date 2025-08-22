# Current Repository + Prefix Implementation Guide

## 🎯 Strategy Overview

We'll use the existing `Bemeda Personal Page` repository with prefixed issues to manage platform components while maintaining the clean separation between personal page content and platform development.

## 📋 Issue Prefixing Convention

### **Prefix Format**: `[PLATFORM]` followed by component type

| Component Type | Issue Prefix | Example |
|---------------|--------------|---------|
| User Stories | `[PLATFORM] US###:` | `[PLATFORM] US001: Organisation Posts Job and Manages Applications` |
| Features | `[PLATFORM] F###:` | `[PLATFORM] F001: User Registration and Authentication` |
| Technical Specs | `[PLATFORM] TS###:` | `[PLATFORM] TS001: Authentication Service Architecture` |
| API Endpoints | `[PLATFORM] API###:` | `[PLATFORM] API001: User Registration Endpoint` |
| Database Schemas | `[PLATFORM] DB###:` | `[PLATFORM] DB001: User Profiles Table Schema` |
| UI Flows | `[PLATFORM] UX###:` | `[PLATFORM] UX001: Job Application Flow` |
| Test Cases | `[PLATFORM] T###:` | `[PLATFORM] T001: User Registration Tests` |
| Acceptance Criteria | `[PLATFORM] A###:` | `[PLATFORM] A001: Registration Validation Criteria` |

## 🏷️ Label System

### **Required Labels for Platform Issues**
- `platform` - Identifies all platform-related issues
- `user-story` / `feature` / `technical` / `testing` / `ux-ui` - Component type
- `priority:high` / `priority:medium` / `priority:low` - Priority level
- `status:planning` / `status:in-progress` / `status:review` / `status:completed` - Status
- `domain:scenarios` / `domain:technical` / `domain:ux-ui` / `domain:testing` - Domain assignment

### **Example Label Combinations**
```
[PLATFORM] US001: Organisation Posts Job and Manages Applications
Labels: platform, user-story, priority:high, status:completed, domain:scenarios
```

## 📝 Issue Templates

Let's create GitHub issue templates specifically for platform components.

### **1. User Story Template**
```markdown
---
name: Platform User Story
about: Create a new user story for the Bemeda platform
title: '[PLATFORM] US###: [User Story Title]'
labels: 'platform, user-story, priority:medium, status:planning, domain:scenarios'
assignees: ''
---

## User Story
As a **[user type]**, I want to **[goal]** so that **[benefit]**.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Definition of Done
- [ ] Business analysis completed
- [ ] UI/UX design approved
- [ ] Technical specification defined
- [ ] Implementation completed
- [ ] Tests written and passing
- [ ] Documentation updated

## Related Components
- Dependencies: 
- UI Flows: 
- Test Cases: 
- API Endpoints: 

## Metadata
```yaml
component_id: US###
component_type: user-story
domain: scenarios
scenario: S001
participant: [Organisation/JobSeeker]
priority: [high/medium/low]
```
```

### **2. Feature Template**
```markdown
---
name: Platform Feature
about: Create a new feature specification for the Bemeda platform
title: '[PLATFORM] F###: [Feature Title]'
labels: 'platform, feature, priority:medium, status:planning, domain:technical'
assignees: ''
---

## Feature Overview
Brief description of the feature and its purpose.

## Business Requirements
- Requirement 1
- Requirement 2
- Requirement 3

## Technical Requirements
- Technical requirement 1
- Technical requirement 2
- Technical requirement 3

## Dependencies
- Internal dependencies
- External dependencies
- API dependencies

## Implementation Notes
Technical implementation considerations and approach.

## Metadata
```yaml
component_id: F###
component_type: feature
domain: technical
related_user_stories: [US###, US###]
priority: [high/medium/low]
effort_estimate: [story_points]
```
```

### **3. Technical Specification Template**
```markdown
---
name: Platform Technical Spec
about: Create a technical specification for the Bemeda platform
title: '[PLATFORM] TS###: [Technical Spec Title]'
labels: 'platform, technical, priority:medium, status:planning, domain:technical'
assignees: ''
---

## Architecture Overview
High-level technical architecture and approach.

## Technical Stack
- Frontend: 
- Backend: 
- Database: 
- Infrastructure: 

## API Specifications
- Endpoints required
- Data models
- Authentication requirements

## Security Considerations
Security requirements and implementation approach.

## Performance Requirements
- Response time targets
- Scalability requirements
- Load expectations

## Implementation Plan
Step-by-step implementation approach.

## Metadata
```yaml
component_id: TS###
component_type: technical-spec
domain: technical
related_features: [F###]
related_apis: [API###]
related_databases: [DB###]
```
```

## 🤖 GitHub Automation Setup

### **1. Update Component Metadata Configuration**
```json
{
  "github": {
    "repository": "spitexbemeda/Bemeda-Personal-Page",
    "issue_prefix": "[PLATFORM]",
    "branch": "gh-pages",
    "labels": {
      "required": ["platform"],
      "component_types": {
        "user-story": "user-story",
        "feature": "feature", 
        "technical-spec": "technical",
        "api": "api",
        "database": "database",
        "ui-flow": "ux-ui",
        "test-case": "testing",
        "acceptance-criteria": "testing"
      },
      "domains": {
        "scenarios": "domain:scenarios",
        "technical": "domain:technical", 
        "ux-ui": "domain:ux-ui",
        "testing": "domain:testing"
      }
    }
  }
}
```

### **2. Enhanced Component Manager for Prefixed Issues**
```javascript
// Update the GitHubIntegration class in component-manager.js
class GitHubIntegration {
  constructor(token, owner, repo) {
    this.token = token;
    this.owner = owner;
    this.repo = repo;
    this.issuePrefix = '[PLATFORM]';
    this.baseUrl = 'https://api.github.com';
  }

  async createIssue(component) {
    const issue = {
      title: `${this.issuePrefix} ${component.id}: ${component.title}`,
      body: this.generateIssueBody(component),
      labels: this.mapComponentToLabels(component)
    };

    const response = await fetch(`${this.baseUrl}/repos/${this.owner}/${this.repo}/issues`, {
      method: 'POST',
      headers: {
        'Authorization': `token ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(issue)
    });

    return response.json();
  }

  mapComponentToLabels(component) {
    const labels = ['platform']; // Always include platform label
    
    // Add component type
    if (component.type) {
      labels.push(component.type);
    }
    
    // Add domain
    if (component.domain) {
      labels.push(`domain:${component.domain}`);
    }
    
    // Add priority
    if (component.priority) {
      labels.push(`priority:${component.priority}`);
    }
    
    // Add status
    if (component.status) {
      labels.push(`status:${component.status}`);
    }
    
    return labels;
  }

  async searchPlatformIssues(query = '') {
    const searchQuery = `repo:${this.owner}/${this.repo} label:platform ${query}`;
    
    const response = await fetch(`${this.baseUrl}/search/issues?q=${encodeURIComponent(searchQuery)}`, {
      headers: {
        'Authorization': `token ${this.token}`,
        'Accept': 'application/vnd.github.v3+json'
      }
    });

    return response.json();
  }
}
```

## 🔍 Issue Discovery & Management

### **Search Queries for Platform Issues**
```bash
# All platform issues
label:platform

# User stories only
label:platform label:user-story

# High priority items
label:platform label:priority:high

# In progress items
label:platform label:status:in-progress

# By domain
label:platform label:domain:scenarios
label:platform label:domain:technical

# By component type
label:platform label:feature
label:platform label:technical

# Combine filters
label:platform label:user-story label:priority:high label:status:in-progress
```

### **GitHub Project Board Setup**
Create a project board specifically for platform development:

1. **Board Name**: "Bemeda Platform Development"
2. **Columns**:
   - 📋 **Backlog** (status:planning)
   - 🔄 **In Progress** (status:in-progress) 
   - 👀 **Review** (status:review)
   - ✅ **Done** (status:completed)

3. **Automation Rules**:
   - Auto-move issues based on status labels
   - Auto-assign to project when `platform` label is added

## 🛠️ Implementation Steps

### **Phase 1: Setup (Today)**
1. Create issue templates in `.github/ISSUE_TEMPLATE/`
2. Create `platform` label and component-specific labels
3. Setup project board for platform development
4. Update component metadata with GitHub configuration

### **Phase 2: Migration (This Week)**
1. Create GitHub issues for existing components (US001-US018)
2. Test issue → component sync workflow
3. Update component manager with prefix support
4. Document team workflow guidelines

### **Phase 3: Team Adoption (Next 2 Weeks)**
1. Team training on prefixed issue workflow
2. Establish daily/weekly sync processes
3. Implement automated status updates
4. Create team dashboard for platform progress

## 📊 Benefits of This Approach

### ✅ **Advantages**
- **Keep Everything Together**: No need to migrate or duplicate content
- **Clear Separation**: Prefix makes platform issues easily identifiable
- **Existing Workflow**: Team already familiar with this repository
- **Simple Implementation**: Minimal setup required
- **Immediate Start**: Can begin creating issues today

### ⚠️ **Considerations**
- **Issue List Mixing**: Personal and platform issues in same list
- **Search Complexity**: Need to always include `label:platform` in searches
- **Team Clarity**: Must enforce consistent prefixing

### 🎯 **Mitigation Strategies**
- **Automated Labeling**: Use issue templates with pre-filled labels
- **Saved Searches**: Create bookmarked searches for common platform queries
- **Team Guidelines**: Clear documentation on issue creation process
- **Dashboard Views**: Custom views that filter to platform-only content

## 🚀 Ready to Implement

The current repository + prefix approach provides an **immediate path forward** with minimal setup while maintaining all the benefits of GitHub integration. The system is ready to go live today!

**Next immediate action**: Create the issue templates and start creating GitHub issues for the existing US001-US018 components.