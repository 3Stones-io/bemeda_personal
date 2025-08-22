# 🔗 "Edit on GitHub" Button Implementation

## 🎯 Goal: Direct Component Editing

Add buttons/links throughout the documentation that redirect authenticated users to the corresponding GitHub issue for editing.

## 🎨 Button Design Options

### **Option 1: Simple Text Link**
```html
<a href="https://github.com/3Stones-io/bemeda_personal/issues/216" 
   class="edit-github-link">
  📝 Edit this component on GitHub
</a>
```

### **Option 2: GitHub-style Button**
```html
<a href="https://github.com/3Stones-io/bemeda_personal/issues/216" 
   class="btn-edit-github">
  <svg>GitHub icon</svg>
  Edit on GitHub
</a>
```

### **Option 3: Floating Edit Button**
```html
<div class="floating-edit-btn">
  <a href="https://github.com/3Stones-io/bemeda_personal/issues/216">
    ✏️ Edit
  </a>
</div>
```

## 🔧 Implementation Strategy

### **1. Add to Component Pages**

For each component page (e.g., `US001.html`), add edit button:

```html
<!-- In US001.html -->
<div class="component-header">
  <h1>US001 - Organisation Receives Cold Call</h1>
  <a href="#" class="btn-edit-component" data-component-id="US001">
    📝 Edit this component
  </a>
</div>
```

### **2. Dynamic GitHub Issue Lookup**

Add JavaScript to find the corresponding GitHub issue:

```javascript
// /docs/assets/js/github-edit-buttons.js
class GitHubEditButtons {
  constructor() {
    this.baseUrl = 'https://github.com/3Stones-io/bemeda_personal';
    this.issuesApiUrl = 'https://api.github.com/repos/3Stones-io/bemeda_personal/issues';
    this.componentIssueMap = new Map();
    this.init();
  }

  async init() {
    await this.loadComponentIssueMap();
    this.setupEditButtons();
  }

  async loadComponentIssueMap() {
    try {
      // Option 1: Load from generated registry
      const registry = await fetch('/docs/MASTER-REGISTRY.json').then(r => r.json());
      for (const [id, component] of Object.entries(registry.components)) {
        if (component.github?.issue_number) {
          this.componentIssueMap.set(id, component.github.issue_number);
        }
      }
    } catch (error) {
      console.warn('Could not load component registry, falling back to API');
      // Option 2: Fallback to GitHub API
      await this.loadFromGitHubAPI();
    }
  }

  async loadFromGitHubAPI() {
    try {
      const response = await fetch(`${this.issuesApiUrl}?labels=component&state=all&per_page=100`);
      const issues = await response.json();
      
      issues.forEach(issue => {
        // Extract component ID from title: "[COMPONENT] US001 - Title"
        const match = issue.title.match(/\[COMPONENT\]\s*([A-Z]+\d+)/);
        if (match) {
          this.componentIssueMap.set(match[1], issue.number);
        }
      });
    } catch (error) {
      console.error('Failed to load GitHub issues:', error);
    }
  }

  setupEditButtons() {
    // Find all edit buttons
    document.querySelectorAll('[data-component-id]').forEach(button => {
      const componentId = button.dataset.componentId;
      const issueNumber = this.componentIssueMap.get(componentId);
      
      if (issueNumber) {
        button.href = `${this.baseUrl}/issues/${issueNumber}`;
        button.title = `Edit ${componentId} on GitHub (Issue #${issueNumber})`;
        button.classList.add('edit-enabled');
      } else {
        // No issue found - option to create new one
        button.href = `${this.baseUrl}/issues/new?template=component-definition.yml&title=[COMPONENT] ${componentId}`;
        button.textContent = '➕ Create GitHub issue for this component';
        button.title = 'This component needs a GitHub issue';
        button.classList.add('edit-create');
      }
    });
  }

  // Quick access method for manual component lookup
  getEditUrl(componentId) {
    const issueNumber = this.componentIssueMap.get(componentId);
    if (issueNumber) {
      return `${this.baseUrl}/issues/${issueNumber}`;
    }
    return `${this.baseUrl}/issues/new?template=component-definition.yml&title=[COMPONENT] ${componentId}`;
  }
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
  window.githubEdit = new GitHubEditButtons();
});
```

### **3. CSS Styling**

```css
/* /docs/assets/css/github-edit-buttons.css */
.btn-edit-component {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: #238636;
  color: white;
  text-decoration: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  transition: background-color 0.2s;
  border: 1px solid rgba(240, 246, 252, 0.1);
}

.btn-edit-component:hover {
  background: #2ea043;
  text-decoration: none;
  color: white;
}

.btn-edit-component.edit-create {
  background: #0969da;
  border-color: rgba(240, 246, 252, 0.1);
}

.btn-edit-component.edit-create:hover {
  background: #0860ca;
}

/* Floating edit button for long pages */
.floating-edit-btn {
  position: fixed;
  bottom: 20px;
  right: 20px;
  z-index: 1000;
}

.floating-edit-btn a {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  background: #238636;
  color: white;
  text-decoration: none;
  border-radius: 50px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transition: all 0.2s;
}

.floating-edit-btn a:hover {
  background: #2ea043;
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.2);
}

/* Component registry table edit buttons */
.component-table .edit-cell {
  text-align: center;
  white-space: nowrap;
}

.btn-edit-mini {
  padding: 4px 8px;
  font-size: 12px;
  background: #f6f8fa;
  color: #24292f;
  border: 1px solid #d1d9e0;
  border-radius: 4px;
  text-decoration: none;
  transition: all 0.2s;
}

.btn-edit-mini:hover {
  background: #f3f4f6;
  border-color: #c7d2db;
}
```

## 📍 Where to Add Edit Buttons

### **1. Component Pages (US001.html, etc.)**
```html
<!-- Add to each component page header -->
<div class="component-actions">
  <a href="#" class="btn-edit-component" data-component-id="US001">
    📝 Edit on GitHub
  </a>
  <a href="#" class="btn-view-history" data-component-id="US001">
    🕒 View History
  </a>
</div>
```

### **2. Component Tables**
```html
<!-- Add column to component tables -->
<table class="component-table">
  <thead>
    <tr>
      <th>ID</th>
      <th>Title</th>
      <th>Status</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>US001</td>
      <td>Organisation Receives Cold Call</td>
      <td>Active</td>
      <td class="edit-cell">
        <a href="#" class="btn-edit-mini" data-component-id="US001">Edit</a>
      </td>
    </tr>
  </tbody>
</table>
```

### **3. Registry/Index Pages**
```html
<!-- Add bulk edit options -->
<div class="registry-actions">
  <a href="https://github.com/3Stones-io/bemeda_personal/issues?q=is%3Aopen+label%3Acomponent" 
     class="btn-edit-component">
    📋 View All Components on GitHub
  </a>
  <a href="https://github.com/3Stones-io/bemeda_personal/issues/new?template=component-definition.yml" 
     class="btn-edit-component edit-create">
    ➕ Create New Component
  </a>
</div>
```

### **4. Floating Button (Optional)**
```html
<!-- Add to pages for quick access -->
<div class="floating-edit-btn">
  <a href="#" data-component-id="US001">
    ✏️ Edit
  </a>
</div>
```

## 🔐 Authentication Handling

### **GitHub Authentication States:**

1. **Not logged in**: Button links to GitHub, user prompted to sign in
2. **Logged in, no access**: User sees GitHub's "404" or permission error
3. **Logged in, with access**: User can edit directly

### **Enhanced Button with Auth Check:**

```javascript
// Enhanced button that checks authentication
async checkGitHubAuth() {
  try {
    const response = await fetch('https://api.github.com/user', {
      headers: {
        'Accept': 'application/vnd.github.v3+json'
      }
    });
    
    if (response.ok) {
      const user = await response.json();
      return user.login; // User is authenticated
    }
  } catch (error) {
    // User not authenticated or CORS blocked
  }
  return null;
}

// Update button text based on auth status
async updateButtonForAuth(button, componentId) {
  const user = await this.checkGitHubAuth();
  
  if (user) {
    button.textContent = `📝 Edit ${componentId}`;
    button.title = `Edit as ${user}`;
  } else {
    button.textContent = `📝 Edit ${componentId} (Login required)`;
    button.title = 'Click to login and edit on GitHub';
  }
}
```

## 🚀 Implementation Plan

### **Phase 1: Basic Edit Links**
1. Add edit buttons to US001-US018 pages
2. Include JavaScript to resolve issue numbers
3. Test with existing GitHub issues

### **Phase 2: Enhanced UI**
1. Add edit columns to component tables
2. Style buttons to match GitHub design
3. Add floating edit buttons for long pages

### **Phase 3: Smart Features**
1. Authentication awareness
2. Quick component creation for missing issues
3. Bulk editing options

## 📊 Benefits

1. **Direct Editing**: Click → Edit → Auto-deploy
2. **No Context Switching**: Stay in documentation, edit when needed
3. **Team Collaboration**: Anyone with access can contribute
4. **Version Control**: All edits tracked in GitHub
5. **Zero Setup**: Works immediately after implementation

This creates a **seamless edit experience** where the documentation becomes a direct interface to the GitHub-based component system!