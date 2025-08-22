# 🚀 GitHub-First Single Source of Truth Solution

## 💡 The Paradigm Shift: GitHub IS the Database

Instead of syncing TO GitHub, we sync FROM GitHub. GitHub becomes our live database.

## 🎯 Core Concept: GitHub Issues = Component Database

### **Each Issue IS a Component**

```yaml
# GitHub Issue #216
Title: [COMPONENT] US001 - Organisation Receives Cold Call
Labels: component:user-story, domain:scenarios, participant:organisation, status:active
Body: |
  ## Component Metadata
  ```json
  {
    "id": "US001",
    "type": "user-story",
    "title": "Organisation Receives Cold Call",
    "description": "Organisation receives cold call from Bemeda sales representative",
    "participant": "Organisation",
    "scenario": "S001",
    "urls": {
      "spec": "https://3stones-io.github.io/bemeda_personal/docs/scenarios/S001/US001.html",
      "figma": "https://figma.com/..."
    }
  }
  ```
  
  ## Description
  Full component description here...
  
  ## Acceptance Criteria
  - [ ] Cold call script defined
  - [ ] Success metrics established
```

### **Advantages of GitHub-First:**

1. **Built-in Version Control** - Issue history tracks all changes
2. **Native Collaboration** - Comments, assignments, mentions
3. **API Access** - GraphQL/REST APIs for querying
4. **Webhooks** - Real-time updates trigger regeneration
5. **Search & Filter** - GitHub's powerful search becomes component search
6. **No Extra Infrastructure** - No database to maintain

## 🏗️ Architecture

### **1. GitHub Project as Master Registry**

Your existing project becomes THE registry:

```
GitHub Project: Bemeda Platform (projects/12)
├── View: Component Registry (Table)
├── View: By Type (Board)
├── View: By Domain (Board)
└── Custom Fields:
    ├── Component ID (text)
    ├── Component Type (select)
    ├── Domain (select)
    └── Participant (select)
```

### **2. GitHub Actions for Automation**

**No external server needed!** Use GitHub Actions:

```yaml
# .github/workflows/sync-components.yml
name: Sync Components from Issues

on:
  issues:
    types: [opened, edited, closed, labeled]
  workflow_dispatch: # Manual trigger

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      - name: Fetch All Component Issues
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
            
            // Parse component metadata from issues
            const components = issues.data.map(issue => {
              const metadata = extractMetadata(issue.body);
              return {
                issue_number: issue.number,
                ...metadata
              };
            });
            
            // Write to registry file
            fs.writeFileSync('docs/MASTER-REGISTRY.json', 
              JSON.stringify(components, null, 2));
      
      - name: Generate Documentation
        run: |
          node scripts/generate-docs-from-registry.js
          
      - name: Commit and Push
        run: |
          git config --global user.name 'GitHub Actions'
          git config --global user.email 'actions@github.com'
          git add .
          git commit -m "🤖 Auto-sync from GitHub issues"
          git push
```

### **3. Issue Templates as Schema**

```yaml
# .github/ISSUE_TEMPLATE/component-definition.yml
name: Component Definition
description: Define a new platform component
title: "[COMPONENT] [ID] - [Title]"
labels: ["component"]
body:
  - type: input
    id: component_id
    attributes:
      label: Component ID
      description: "Unique identifier (e.g., US001, TC001)"
      placeholder: "US001"
    validations:
      required: true
      
  - type: dropdown
    id: component_type
    attributes:
      label: Component Type
      options:
        - user-story
        - technical-component
        - ui-component
        - feature
        - test-case
        
  - type: textarea
    id: metadata
    attributes:
      label: Component Metadata (JSON)
      description: "Full component metadata in JSON format"
      value: |
        ```json
        {
          "id": "",
          "type": "",
          "title": "",
          "description": "",
          "participant": "",
          "scenario": ""
        }
        ```
```

## 🔄 The Complete Workflow

### **1. Creating a Component**
```bash
# Developer creates issue using template
gh issue create --template component-definition.yml
```

### **2. Automatic Sync (GitHub Actions)**
1. Issue created/updated triggers workflow
2. Action fetches all component issues
3. Parses metadata from issue bodies
4. Generates `MASTER-REGISTRY.json`
5. Runs documentation generators
6. Commits and pushes changes
7. GitHub Pages auto-deploys

### **3. Querying Components**
```javascript
// Via GitHub API
const components = await octokit.issues.listForRepo({
  owner: '3Stones-io',
  repo: 'bemeda_personal',
  labels: 'component',
});

// Or via generated registry
const registry = await fetch('/docs/MASTER-REGISTRY.json');
```

## 🎯 Benefits Over External Sync

1. **No Infrastructure** - GitHub handles everything
2. **Single Login** - Team already uses GitHub
3. **Audit Trail** - Issue history = component history  
4. **Real-time** - Webhooks trigger immediate updates
5. **Permissions** - GitHub permissions control who can edit
6. **Cost** - Free with GitHub (no server costs)
7. **Reliability** - GitHub's uptime becomes your uptime

## 🚀 Migration Path

### **Phase 1: Create Component Issues (This Week)**
```bash
# Script to create issues from existing components
for component in components/*; do
  gh issue create \
    --title "[COMPONENT] $(jq -r .id $component) - $(jq -r .title $component)" \
    --body "$(cat $component)" \
    --label "component,migration"
done
```

### **Phase 2: Setup GitHub Actions (Next Week)**
1. Create sync workflow
2. Test with a few components
3. Validate generated documentation

### **Phase 3: Full Migration (Week 3)**
1. Run migration script for all components
2. Enable GitHub Actions
3. Archive old JSON files

## 🔧 For Different Users

### **Developers**
- Edit components = Edit GitHub issues
- Use GitHub UI, CLI, or API
- Changes auto-propagate everywhere

### **Claude/AI**
```markdown
# CLAUDE.md
## Component Lookup
1. Check GitHub issues with label 'component'
2. Or use generated MASTER-REGISTRY.json
3. Issue number = authoritative source
```

### **Web Users**
- See auto-generated docs
- Can submit changes via GitHub issues
- Can comment on components directly

## 📊 Example Queries

```bash
# Find all user stories
gh issue list --label "component:user-story"

# Find components by participant  
gh issue list --label "participant:organisation"

# Get specific component
gh issue view 216 --json body | jq '.body'

# Search components
gh issue list --search "cold call" --label "component"
```

## 🤖 No Server Needed!

Everything runs on GitHub's infrastructure:
- **GitHub Actions** = Your cron jobs (up to 2000 mins/month free)
- **GitHub Pages** = Your web hosting
- **GitHub API** = Your database queries
- **GitHub Issues** = Your database
- **GitHub Projects** = Your admin UI

This is truly serverless and maintenance-free!

## 🎉 Summary

By making GitHub Issues the source of truth:
1. Zero infrastructure to maintain
2. Built-in collaboration features
3. Automatic version control
4. Free automation via Actions
5. Single system for everything

The registry file becomes a generated artifact, not the source. GitHub IS your database!