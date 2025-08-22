# GitHub Integration Guide

This document outlines how to integrate the Bemeda Platform documentation system with GitHub for real-time collaboration and synchronization.

## 🔗 Integration Architecture

```
GitHub Issues ←→ Component Metadata ←→ Documentation Pages
      ↓                    ↓                    ↓
  Comments          Status Updates      Real-time UI
  Assignees         Progress Tracking   Cross-references
  Labels            Dependencies        Search Index
```

## 📋 Setup Instructions

### 1. GitHub Repository Setup

Create issues for each component using this template:

```markdown
---
component_id: US001
component_type: user-story
---

## US001: Organisation Posts Job and Manages Applications

**Description:**
Healthcare organisation posts a job opening, manages incoming applications, and tracks the entire hiring process.

**Status:** in-progress
**Priority:** high
**Domain:** scenarios

### Acceptance Criteria
- [ ] Organisation successfully creates job posting
- [ ] Job posting is published and visible
- [ ] Applications are received and tracked

### Related Components
- Dependencies: F001, TC001
- UI Flows: UX001
- Test Cases: T001
```

### 2. Webhook Configuration

Set up GitHub webhooks to sync changes:

```json
{
  "url": "https://your-domain.com/webhooks/github",
  "content_type": "json",
  "events": [
    "issues",
    "issue_comment",
    "pull_request"
  ]
}
```

### 3. Environment Variables

```bash
GITHUB_TOKEN=your_personal_access_token
GITHUB_OWNER=bemeda-platform
GITHUB_REPO=platform
WEBHOOK_SECRET=your_webhook_secret
```

## 🔄 Synchronization Flow

### Issue → Component Metadata

When GitHub issues are updated:

1. **Status Change**: Issue state updates component status
2. **Comments**: Appended to component activity log
3. **Labels**: Mapped to component tags and categories
4. **Assignees**: Updated in component metadata
5. **Milestones**: Linked to project phases

### Component → GitHub Issue

When documentation is updated:

1. **Progress Updates**: Reflected in issue comments
2. **Relationship Changes**: Updated in issue description
3. **Status Changes**: Issue state synchronized
4. **Cross-references**: Automatic linking between related issues

## 🛠️ Implementation Examples

### 1. Webhook Handler (Node.js)

```javascript
const express = require('express');
const crypto = require('crypto');
const fs = require('fs').promises;

const app = express();

app.post('/webhooks/github', async (req, res) => {
  const signature = req.headers['x-hub-signature-256'];
  const payload = JSON.stringify(req.body);
  
  // Verify webhook signature
  const expectedSignature = crypto
    .createHmac('sha256', process.env.WEBHOOK_SECRET)
    .update(payload)
    .digest('hex');
    
  if (!crypto.timingSafeEqual(
    Buffer.from(signature), 
    Buffer.from(`sha256=${expectedSignature}`)
  )) {
    return res.status(401).send('Unauthorized');
  }

  // Process the webhook
  await processGitHubWebhook(req.body);
  res.status(200).send('OK');
});

async function processGitHubWebhook(payload) {
  const { action, issue } = payload;
  
  if (action === 'opened' || action === 'edited') {
    await updateComponentFromIssue(issue);
  }
  
  if (action === 'closed') {
    await markComponentCompleted(issue);
  }
}

async function updateComponentFromIssue(issue) {
  const componentId = extractComponentId(issue.body);
  if (!componentId) return;
  
  const componentPath = `./docs/metadata/components/${componentId}.json`;
  const component = JSON.parse(await fs.readFile(componentPath, 'utf8'));
  
  // Update component metadata
  component.component.github.issue = issue.number;
  component.component.status = issue.state === 'closed' ? 'completed' : 'in-progress';
  component.component.metadata.updated = new Date().toISOString();
  
  // Extract and update acceptance criteria
  const criteria = extractAcceptanceCriteria(issue.body);
  if (criteria.length > 0) {
    component.component.acceptance_criteria = criteria;
  }
  
  await fs.writeFile(componentPath, JSON.stringify(component, null, 2));
}
```

### 2. GitHub API Client

```javascript
class GitHubIntegration {
  constructor(token, owner, repo) {
    this.token = token;
    this.owner = owner;
    this.repo = repo;
    this.baseUrl = 'https://api.github.com';
  }

  async createIssue(component) {
    const issue = {
      title: `${component.id}: ${component.title}`,
      body: this.generateIssueBody(component),
      labels: this.mapComponentToLabels(component),
      assignees: component.assignee ? [component.assignee] : []
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

  async updateIssueProgress(issueNumber, progress) {
    const comment = {
      body: `📊 **Progress Update**\n\n${this.formatProgressUpdate(progress)}`
    };

    await fetch(`${this.baseUrl}/repos/${this.owner}/${this.repo}/issues/${issueNumber}/comments`, {
      method: 'POST',
      headers: {
        'Authorization': `token ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(comment)
    });
  }

  mapComponentToLabels(component) {
    const labels = [component.type];
    
    if (component.priority) labels.push(`priority:${component.priority}`);
    if (component.domain) labels.push(`domain:${component.domain}`);
    if (component.status) labels.push(`status:${component.status}`);
    
    return labels;
  }
}
```

## 📊 Analytics & Reporting

### GitHub Actions Workflow

```yaml
name: Documentation Analytics
on:
  schedule:
    - cron: '0 9 * * *'  # Daily at 9 AM
  workflow_dispatch:

jobs:
  analytics:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Generate Analytics
        run: |
          node scripts/generate-analytics.js
          
      - name: Update Dashboard
        run: |
          node scripts/update-dashboard.js
          
      - name: Commit Updates
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add docs/unified-view/analytics.json
          git commit -m "Update analytics dashboard" || exit 0
          git push
```

## 🚀 Benefits

1. **Real-time Collaboration**: Changes sync instantly between GitHub and documentation
2. **Single Source of Truth**: GitHub issues serve as the authoritative status
3. **Automated Tracking**: Progress and dependencies tracked automatically
4. **Team Visibility**: Everyone sees the same real-time project state
5. **Integration Ready**: Works with existing GitHub workflows and tools

## 🔧 Next Steps

1. Set up GitHub repository with component issues
2. Configure webhooks for real-time sync
3. Deploy webhook handler service
4. Test bidirectional synchronization
5. Add team member access and permissions
6. Implement search indexing for GitHub data
7. Create dashboard with GitHub analytics integration

## 📚 Advanced Features

- **Branch Integration**: Link branches to components for code tracking
- **Pull Request Mapping**: Connect PRs to implementation progress
- **Automated Testing**: Trigger tests when components are updated
- **Release Management**: Group components by milestones and releases
- **Team Analytics**: Track individual and team productivity metrics