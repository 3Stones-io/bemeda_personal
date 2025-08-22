/**
 * GitHub Edit Buttons - Dynamic edit links for components
 * Automatically resolves component IDs to GitHub issue numbers
 */
class GitHubEditButtons {
  constructor() {
    this.baseUrl = 'https://github.com/3Stones-io/bemeda_personal';
    this.issuesApiUrl = 'https://api.github.com/repos/3Stones-io/bemeda_personal/issues';
    this.componentIssueMap = new Map();
    this.loadingPromise = null;
    
    console.log('🔗 Initializing GitHub Edit Buttons');
    this.init();
  }

  async init() {
    try {
      await this.loadComponentIssueMap();
      this.setupEditButtons();
      this.addGlobalEditHelpers();
      console.log(`✅ GitHub Edit Buttons ready (${this.componentIssueMap.size} components mapped)`);
    } catch (error) {
      console.error('❌ Failed to initialize GitHub Edit Buttons:', error);
    }
  }

  async loadComponentIssueMap() {
    if (this.loadingPromise) {
      return this.loadingPromise;
    }

    this.loadingPromise = this._loadComponentData();
    return this.loadingPromise;
  }

  async _loadComponentData() {
    try {
      // Try to load from generated registry first
      console.log('📥 Loading component registry...');
      const registryResponse = await fetch('/docs/MASTER-REGISTRY.json');
      
      if (registryResponse.ok) {
        const registry = await registryResponse.json();
        
        for (const [id, component] of Object.entries(registry.components || {})) {
          if (component.github?.issue_number) {
            this.componentIssueMap.set(id, {
              issueNumber: component.github.issue_number,
              title: component.title,
              url: component.github.url
            });
          }
        }
        
        console.log(`✅ Loaded ${this.componentIssueMap.size} components from registry`);
        return;
      }
    } catch (error) {
      console.warn('⚠️ Registry not available, falling back to GitHub API');
    }

    // Fallback to GitHub API
    try {
      console.log('📥 Loading from GitHub API...');
      const response = await fetch(`${this.issuesApiUrl}?labels=component&state=all&per_page=100`);
      
      if (!response.ok) {
        throw new Error(`GitHub API responded with ${response.status}`);
      }
      
      const issues = await response.json();
      
      issues.forEach(issue => {
        // Extract component ID from title patterns:
        // "[COMPONENT] US001 - Title" or "US001: Title" or just "US001"
        const patterns = [
          /\[COMPONENT\]\s*([A-Z]+\d+)/i,
          /^([A-Z]+\d+)\s*[:\-]/,
          /^([A-Z]+\d+)$/
        ];
        
        for (const pattern of patterns) {
          const match = issue.title.match(pattern);
          if (match) {
            this.componentIssueMap.set(match[1].toUpperCase(), {
              issueNumber: issue.number,
              title: issue.title,
              url: issue.html_url
            });
            break;
          }
        }
      });
      
      console.log(`✅ Loaded ${this.componentIssueMap.size} components from GitHub API`);
    } catch (error) {
      console.error('❌ Failed to load from GitHub API:', error);
    }
  }

  setupEditButtons() {
    // Find all elements with component edit attributes
    const editElements = document.querySelectorAll('[data-component-id], .component-edit, .edit-component');
    
    editElements.forEach(element => {
      this.setupSingleEditButton(element);
    });

    // Also setup any manual component ID references
    this.setupComponentLinks();
  }

  setupSingleEditButton(element) {
    const componentId = element.dataset.componentId || 
                       element.dataset.component ||
                       this.extractComponentIdFromElement(element);

    if (!componentId) {
      console.warn('⚠️ Edit button found without component ID:', element);
      return;
    }

    const componentData = this.componentIssueMap.get(componentId.toUpperCase());
    
    if (componentData) {
      // Component has GitHub issue
      element.href = componentData.url;
      element.title = `Edit ${componentId} on GitHub (Issue #${componentData.issueNumber})`;
      element.classList.add('edit-enabled');
      
      // Update button text if it's generic
      if (element.textContent.includes('Edit') && !element.textContent.includes(componentId)) {
        element.innerHTML = `📝 Edit ${componentId}`;
      }
      
    } else {
      // No issue found - create new one with template
      const newIssueUrl = `${this.baseUrl}/issues/new?template=component-definition.yml&title=[COMPONENT] ${componentId} - Component Title&component_id=${componentId}`;
      element.href = newIssueUrl;
      element.title = `Create GitHub issue for ${componentId} (uses template with proper labels)`;
      element.classList.add('edit-create');
      
      if (element.textContent.includes('Edit')) {
        element.innerHTML = `➕ Create ${componentId} (auto-labeled)`;
      }
    }

    // Add click analytics
    element.addEventListener('click', () => {
      console.log(`🔗 Edit clicked for component: ${componentId}`);
    });
  }

  setupComponentLinks() {
    // Look for component ID patterns in text and make them clickable
    const textNodes = this.getTextNodes(document.body);
    const componentPattern = /\b(US|UC|UI|TC|F|T)\d{3}\b/g;
    
    textNodes.forEach(node => {
      const text = node.textContent;
      if (componentPattern.test(text)) {
        const newHtml = text.replace(componentPattern, (match) => {
          const componentData = this.componentIssueMap.get(match);
          if (componentData) {
            return `<a href="${componentData.url}" class="component-link" title="Edit ${match} on GitHub">${match}</a>`;
          }
          return match;
        });
        
        if (newHtml !== text) {
          const wrapper = document.createElement('span');
          wrapper.innerHTML = newHtml;
          node.parentNode.replaceChild(wrapper, node);
        }
      }
    });
  }

  getTextNodes(element) {
    const textNodes = [];
    const walker = document.createTreeWalker(
      element,
      NodeFilter.SHOW_TEXT,
      {
        acceptNode: (node) => {
          // Skip script, style, and already processed elements
          const parent = node.parentElement;
          if (parent.tagName === 'SCRIPT' || 
              parent.tagName === 'STYLE' ||
              parent.classList.contains('component-link')) {
            return NodeFilter.FILTER_REJECT;
          }
          return NodeFilter.FILTER_ACCEPT;
        }
      }
    );
    
    let node;
    while (node = walker.nextNode()) {
      textNodes.push(node);
    }
    
    return textNodes;
  }

  extractComponentIdFromElement(element) {
    // Try to extract component ID from various sources
    const sources = [
      element.id,
      element.className,
      element.textContent,
      element.closest('[id]')?.id,
      element.closest('.component')?.dataset.id
    ];

    for (const source of sources) {
      if (!source) continue;
      
      const match = source.match(/\b([A-Z]+\d+)\b/);
      if (match) {
        return match[1];
      }
    }

    return null;
  }

  addGlobalEditHelpers() {
    // Add global edit utilities
    window.githubEdit = {
      // Get edit URL for any component
      getEditUrl: (componentId) => this.getEditUrl(componentId),
      
      // Add edit button to any element
      addEditButton: (element, componentId) => {
        element.dataset.componentId = componentId;
        this.setupSingleEditButton(element);
      },
      
      // Get all mapped components
      getComponents: () => this.componentIssueMap,
      
      // Refresh component mapping
      refresh: () => {
        this.componentIssueMap.clear();
        this.loadingPromise = null;
        return this.init();
      }
    };

    // Add CSS if not already included
    this.addDefaultStyles();
  }

  getEditUrl(componentId) {
    const componentData = this.componentIssueMap.get(componentId.toUpperCase());
    if (componentData) {
      return componentData.url;
    }
    return `${this.baseUrl}/issues/new?template=component-definition.yml&title=[COMPONENT] ${componentId} - Component Title&component_id=${componentId}`;
  }

  addDefaultStyles() {
    if (document.getElementById('github-edit-styles')) {
      return; // Already added
    }

    const styles = `
      <style id="github-edit-styles">
        .btn-edit-component {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          padding: 8px 16px;
          background: #238636;
          color: white !important;
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
          color: white !important;
        }

        .btn-edit-component.edit-create {
          background: #0969da;
        }

        .btn-edit-component.edit-create:hover {
          background: #0860ca;
        }

        .component-link {
          color: #0969da;
          text-decoration: none;
          font-weight: 500;
          border-bottom: 1px dotted #0969da;
        }

        .component-link:hover {
          text-decoration: underline;
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
      </style>
    `;

    document.head.insertAdjacentHTML('beforeend', styles);
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    new GitHubEditButtons();
  });
} else {
  new GitHubEditButtons();
}