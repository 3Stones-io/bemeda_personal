# 🚀 GitHub-First Implementation Strategy

## 🎯 **Core Concept: GitHub Issues = Component Database**

**Every component exists as a GitHub Issue with structured metadata, automatically syncing to the documentation site.**

## 🏗️ **Architecture Overview**

```
GitHub Issues (Source of Truth)
    ↓ (GitHub Actions)
Component Registry (Generated)
    ↓ (Auto-sync)
Documentation Site (GitHub Pages)
    ↓ (Edit Buttons)
Back to GitHub Issues
```

## 📋 **Implementation Plan**

### **Phase 1: Setup GitHub Infrastructure (Week 1)**

#### **1.1 Issue Templates for Each Component Type**

Create specialized templates for each of our 15 component types:

```yaml
# .github/ISSUE_TEMPLATE/
├── business-scenario.yml          # B_S###
├── user-story.yml                 # B_S###_US###
├── user-story-step.yml            # B_S###_US###_USS###
├── ux-scenario.yml                # U_S###
├── user-flow.yml                  # U_S###_UX###
├── interface-mockup.yml           # U_S###_M###
├── ui-component.yml               # U_S###_C###
├── technical-scenario.yml         # T_S###
├── use-case.yml                   # T_S###_UC###
├── platform-feature.yml           # T_S###_F###
├── technical-component.yml        # T_S###_TC###
├── test-scenario.yml              # TEST_S###
├── test-case.yml                  # TEST_S###_T###
├── bug-report.yml                 # TEST_S###_B###
└── acceptance-criteria.yml        # TEST_S###_AC###
```

#### **1.2 Component Metadata Schema**

Each issue will contain structured metadata in the body:

```yaml
---
component_id: "B_S001_US001"
component_type: "user-story"
domain: "business"
scenario: "B_S001"
participant: "organisation"
status: "active"
priority: "high"
related_components:
  - "B_S001_US001_USS001"
  - "U_S001_UX001"
  - "T_S001_UC001"
urls:
  template: "/integration/templates/B_S001_US001-template.html"
  spec: "/scenarios/S001/US001.html"
  figma: "https://figma.com/..."
---

# B_S001_US001: Organisation Receives Cold Call

## Description
Healthcare organisation receives cold call from Bemeda sales representative...

## Acceptance Criteria
- [ ] Cold call script defined
- [ ] Success metrics established
- [ ] Follow-up process documented

## Implementation Notes
- Links to UX flow U_S001_UX001
- Requires technical component T_S001_TC001
- Tested by TEST_S001_T001
```

#### **1.3 GitHub Project Board Setup**

Create a comprehensive project board with custom fields:

```yaml
Project: "Bemeda Platform Components"
Custom Fields:
  - Component ID (Text)
  - Component Type (Single Select)
  - Domain (Single Select)
  - Scenario (Text)
  - Participant (Single Select)
  - Priority (Single Select)
  - Status (Single Select)

Views:
  - By Domain (Board)
  - By Type (Board)
  - Registry (Table)
  - Timeline (Roadmap)
```

### **Phase 2: Automation Setup (Week 2)**

#### **2.1 GitHub Actions Workflow**

```yaml
# .github/workflows/sync-components.yml
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
              const metadata = extractMetadata(issue.body);
              return {
                issue_number: issue.number,
                issue_url: issue.html_url,
                ...metadata
              };
            });
            
            // Write to registry
            fs.writeFileSync('docs/MASTER-REGISTRY.json', 
              JSON.stringify(components, null, 2));
            
            // Generate component map for Claude
            const componentMap = generateComponentMap(components);
            fs.writeFileSync('docs/COMPONENT-MAP.json', 
              JSON.stringify(componentMap, null, 2));
            
            return components.length;
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Generate Documentation
        run: |
          node scripts/generate-docs-from-registry.js
          
      - name: Update Site Navigation
        run: |
          node scripts/update-navigation.js
          
      - name: Commit and Push Changes
        run: |
          git config --global user.name 'GitHub Actions'
          git config --global user.email 'actions@github.com'
          git add .
          git commit -m "🤖 Auto-sync from GitHub issues (${{ steps.fetch-issues.outputs.result }} components)"
          git push
```

#### **2.2 Component Validation System**

```yaml
# .github/workflows/validate-components.yml
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
              return;
            }
            
            // Validate metadata structure
            const metadata = extractMetadata(issue.body);
            const validation = validateComponent(metadata);
            
            if (!validation.valid) {
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: issue.number,
                body: `❌ **Validation Failed**\n\n${validation.errors.join('\n')}`
              });
              
              await github.rest.issues.addLabels({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: issue.number,
                labels: ['needs-fixes']
              });
            } else {
              // Auto-label based on metadata
              const labels = generateLabels(metadata);
              await github.rest.issues.addLabels({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: issue.number,
                labels: labels
              });
            }
```

### **Phase 3: Documentation Integration (Week 3)**

#### **3.1 Dynamic Edit Buttons**

Update the edit buttons to link directly to GitHub issues:

```javascript
// assets/js/github-edit-buttons.js
class GitHubEditButtons {
  constructor() {
    this.registry = null;
    this.init();
  }
  
  async init() {
    await this.loadRegistry();
    this.addEditButtons();
  }
  
  async loadRegistry() {
    const response = await fetch('/docs/MASTER-REGISTRY.json');
    this.registry = await response.json();
  }
  
  addEditButtons() {
    // Find all component IDs on the page
    const componentElements = document.querySelectorAll('[data-component-id]');
    
    componentElements.forEach(element => {
      const componentId = element.dataset.componentId;
      const component = this.registry.find(c => c.component_id === componentId);
      
      if (component) {
        const editButton = this.createEditButton(component);
        element.appendChild(editButton);
      }
    });
  }
  
  createEditButton(component) {
    const button = document.createElement('a');
    button.href = component.issue_url;
    button.className = 'github-edit-btn';
    button.innerHTML = `✏️ Edit on GitHub (#${component.issue_number})`;
    button.target = '_blank';
    return button;
  }
}
```

#### **3.2 Real-time Status Display**

```javascript
// assets/js/component-status.js
class ComponentStatus {
  constructor() {
    this.updateStatuses();
  }
  
  async updateStatuses() {
    const registry = await this.loadRegistry();
    
    registry.forEach(component => {
      const element = document.querySelector(`[data-component-id="${component.component_id}"]`);
      if (element) {
        this.updateStatusBadge(element, component.status);
      }
    });
  }
  
  updateStatusBadge(element, status) {
    const badge = element.querySelector('.status-badge') || this.createStatusBadge();
    badge.className = `status-badge status-${status}`;
    badge.textContent = status;
  }
}
```

### **Phase 4: Manual Scenario Creation Process**

#### **4.1 Collaborative Scenario Creation**

For new scenarios, we'll work together manually:

1. **Planning Session**: Define scenario scope and components
2. **Issue Creation**: Create all component issues using templates
3. **Validation**: Ensure proper labeling and relationships
4. **Documentation**: Generate initial documentation
5. **Review**: Team review and approval

#### **4.2 Scenario Creation Checklist**

```markdown
## New Scenario Creation Checklist

### Pre-Creation
- [ ] Define scenario scope and objectives
- [ ] Identify all participants and their journeys
- [ ] Map component relationships and dependencies
- [ ] Determine acceptance criteria

### Issue Creation
- [ ] Create scenario issue (B_S###)
- [ ] Create all user story issues (B_S###_US###)
- [ ] Create all user story step issues (B_S###_US###_USS###)
- [ ] Create UX scenario issue (U_S###)
- [ ] Create UX flow issues (U_S###_UX###)
- [ ] Create mockup issues (U_S###_M###)
- [ ] Create UI component issues (U_S###_C###)
- [ ] Create technical scenario issue (T_S###)
- [ ] Create use case issues (T_S###_UC###)
- [ ] Create feature issues (T_S###_F###)
- [ ] Create technical component issues (T_S###_TC###)
- [ ] Create test scenario issue (TEST_S###)
- [ ] Create test case issues (TEST_S###_T###)
- [ ] Create bug report issues (TEST_S###_B###)
- [ ] Create acceptance criteria issues (TEST_S###_AC###)

### Post-Creation
- [ ] Verify all issues are properly labeled
- [ ] Check component relationships are linked
- [ ] Validate documentation generation
- [ ] Review with team
- [ ] Approve for development
```

## 🔄 **Workflow Benefits**

### **For Developers**
- **Single Interface**: Everything happens in GitHub
- **Real-time Updates**: Changes sync immediately
- **Version Control**: Full history of all changes
- **Collaboration**: Comments, mentions, assignments

### **For Documentation**
- **Always Current**: Auto-generated from GitHub
- **Consistent**: Enforced templates ensure consistency
- **Searchable**: GitHub's search becomes component search
- **Linked**: Everything cross-references automatically

### **For Project Management**
- **Visual Boards**: GitHub Projects for different views
- **Progress Tracking**: Status updates in real-time
- **Reporting**: Built-in analytics and insights
- **Automation**: Workflows handle repetitive tasks

## 🚀 **Migration Strategy**

### **Step 1: Create Component Issues**
```bash
# Script to create issues from existing components
for component in components/*; do
  gh issue create \
    --title "[COMPONENT] $(jq -r .id $component) - $(jq -r .title $component)" \
    --body "$(cat $component)" \
    --label "component,migration"
done
```

### **Step 2: Setup Automation**
1. Deploy GitHub Actions workflows
2. Test with a few components
3. Validate generated documentation

### **Step 3: Full Migration**
1. Run migration script for all components
2. Enable GitHub Actions
3. Archive old JSON files

## 🎯 **Success Metrics**

- **Zero Manual Sync**: All updates happen automatically
- **Real-time Updates**: Changes visible within minutes
- **Perfect Consistency**: GitHub and docs always match
- **Team Adoption**: Everyone uses GitHub for component management
- **Reduced Maintenance**: No manual documentation updates needed

This approach gives us the best of both worlds: GitHub's powerful collaboration features with automatic documentation generation, while maintaining our strict naming conventions and hierarchical structure.
