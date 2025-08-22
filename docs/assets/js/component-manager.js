/**
 * Component Management System
 * Handles metadata-driven component rendering and GitHub integration
 */
class ComponentManager {
    constructor() {
        this.components = new Map();
        this.basePath = this.getBasePath();
        this.githubConfig = {
            owner: 'spitexbemeda',
            repo: 'Bemeda-Personal-Page',
            token: null, // Will be loaded from config or environment
            issuePrefix: '[PLATFORM]'
        };
    }

    /**
     * Get base path for relative navigation
     */
    getBasePath() {
        const path = window.location.pathname;
        const segments = path.split('/').filter(s => s);
        const docsIndex = segments.findIndex(s => s === 'docs');
        
        if (docsIndex >= 0) {
            return '../'.repeat(segments.length - docsIndex - 1);
        }
        return '';
    }

    /**
     * Load component metadata
     */
    async loadComponent(componentId) {
        try {
            const response = await fetch(`${this.basePath}metadata/components/${componentId}.json`);
            if (!response.ok) throw new Error(`Component ${componentId} not found`);
            
            const data = await response.json();
            this.components.set(componentId, data.component);
            return data.component;
        } catch (error) {
            console.warn(`Could not load component ${componentId}:`, error);
            return null;
        }
    }

    /**
     * Save component metadata
     */
    async saveComponent(componentId, componentData) {
        try {
            // In a real implementation, this would POST to an API
            const payload = {
                component: componentData
            };
            
            // For now, just update in memory and log
            this.components.set(componentId, componentData);
            console.log('Component saved:', componentId, payload);
            
            // Trigger GitHub sync if configured
            if (componentData.github?.issue) {
                await this.syncWithGitHub(componentData);
            }
            
            return true;
        } catch (error) {
            console.error('Failed to save component:', error);
            return false;
        }
    }

    /**
     * Sync component with GitHub issue
     */
    async syncWithGitHub(component) {
        if (!this.githubConfig.token) {
            console.warn('GitHub token not configured, skipping sync');
            return;
        }

        try {
            const issueData = {
                title: `${this.githubConfig.issuePrefix} ${component.id}: ${component.title}`,
                body: this.generateGitHubIssueBody(component),
                labels: component.github.labels || ['platform'],
                assignees: component.assignee ? [component.assignee] : [],
                milestone: component.github.milestone
            };

            // Update GitHub issue
            const response = await fetch(
                `https://api.github.com/repos/${this.githubConfig.owner}/${this.githubConfig.repo}/issues/${component.github.issue}`,
                {
                    method: 'PATCH',
                    headers: {
                        'Authorization': `token ${this.githubConfig.token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(issueData)
                }
            );

            if (!response.ok) throw new Error('Failed to update GitHub issue');
            
            console.log('Successfully synced with GitHub issue:', component.github.issue);
            return true;
        } catch (error) {
            console.error('GitHub sync failed:', error);
            return false;
        }
    }

    /**
     * Generate GitHub issue body from component metadata
     */
    generateGitHubIssueBody(component) {
        return `
## ${component.title}

**Description:**
${component.description}

**Status:** ${component.status}
**Priority:** ${component.priority}
**Progress:** ${component.progress.overall}%

### Acceptance Criteria
${component.acceptance_criteria.map(ac => 
    `- [${ac.status === 'completed' ? 'x' : ' '}] ${ac.description}`
).join('\n')}

### Dependencies
${component.relationships.dependencies.map(dep => `- ${dep}`).join('\n')}

### Related Components
- UI Flows: ${component.relationships.ui_flows.join(', ')}
- Test Cases: ${component.relationships.test_cases.join(', ')}
- API Endpoints: ${component.relationships.api_endpoints.join(', ')}

---
*Auto-generated from component metadata* | [View in Platform](${window.location.origin}${window.location.pathname})
        `.trim();
    }

    /**
     * Render component with metadata
     */
    async renderComponent(componentId, containerId) {
        const component = await this.loadComponent(componentId);
        if (!component) return false;

        const container = document.getElementById(containerId);
        if (!container) return false;

        // Update page title and meta information
        this.updatePageMetadata(component);

        // Update GitHub integration elements
        this.updateGitHubElements(component);

        // Update progress indicators
        this.updateProgressIndicators(component);

        // Update relationship links
        this.updateRelationshipLinks(component);

        return true;
    }

    /**
     * Update page metadata from component
     */
    updatePageMetadata(component) {
        // Update title
        const titleElement = document.querySelector('.story-name, .criteria-name, .spec-name');
        if (titleElement) {
            titleElement.textContent = component.title;
        }

        // Update status
        const statusElement = document.querySelector('.status-badge, [class*="status-"]');
        if (statusElement) {
            statusElement.className = `status-${component.status}`;
            statusElement.textContent = component.status.replace('-', ' ').toUpperCase();
        }

        // Update description
        const descElement = document.querySelector('.story-description, .criteria-description');
        if (descElement) {
            descElement.textContent = component.description;
        }
    }

    /**
     * Update GitHub-related elements
     */
    updateGitHubElements(component) {
        if (!component.github?.issue) return;

        // Add GitHub issue link
        const githubLink = document.createElement('a');
        githubLink.href = `https://github.com/${this.githubConfig.owner}/${this.githubConfig.repo}/issues/${component.github.issue}`;
        githubLink.target = '_blank';
        githubLink.innerHTML = `
            <span style="background: #24292e; color: white; padding: 4px 8px; border-radius: 4px; font-size: 0.9rem;">
                📝 Issue #${component.github.issue}
            </span>
        `;

        // Insert after title
        const titleElement = document.querySelector('.story-title, .criteria-title');
        if (titleElement) {
            titleElement.appendChild(githubLink);
        }
    }

    /**
     * Update progress indicators
     */
    updateProgressIndicators(component) {
        if (!component.progress) return;

        // Update overall progress
        const progressBar = document.querySelector('.timeline-progress');
        if (progressBar) {
            progressBar.style.width = `${component.progress.overall}%`;
        }

        // Update progress text
        const progressText = document.querySelector('.progress-percentage');
        if (progressText) {
            progressText.textContent = `${component.progress.overall}%`;
        }
    }

    /**
     * Update relationship links
     */
    updateRelationshipLinks(component) {
        if (!component.relationships) return;

        Object.entries(component.relationships).forEach(([type, items]) => {
            const container = document.querySelector(`.${type}-links, .relationship-links`);
            if (container && Array.isArray(items)) {
                container.innerHTML = items.map(item => 
                    `<a href="../${this.getComponentPath(item)}" class="relationship-link">${item}</a>`
                ).join('');
            }
        });
    }

    /**
     * Get component path based on ID prefix
     */
    getComponentPath(componentId) {
        const prefix = componentId.substring(0, 2);
        const paths = {
            'US': 'scenarios/',
            'UX': 'ux-ui/',
            'F': 'technical/',
            'TC': 'technical/', 
            'TS': 'technical/',
            'API': 'technical/',
            'DB': 'technical/',
            'T': 'testing/',
            'A': 'testing/'
        };
        return `${paths[prefix] || ''}${componentId}.html`;
    }

    /**
     * Search components
     */
    async searchComponents(query, filters = {}) {
        try {
            // In a real implementation, this would query an API
            // For now, simulate search results
            const mockResults = [
                {
                    id: 'US001',
                    title: 'Organisation Posts Job and Manages Applications',
                    type: 'user-story',
                    status: 'completed',
                    relevance: 0.95
                }
            ];

            return mockResults.filter(result => 
                result.title.toLowerCase().includes(query.toLowerCase()) ||
                result.id.toLowerCase().includes(query.toLowerCase())
            );
        } catch (error) {
            console.error('Search failed:', error);
            return [];
        }
    }

    /**
     * Search GitHub issues for platform components
     */
    async searchPlatformIssues(query = '', filters = {}) {
        if (!this.githubConfig.token) {
            console.warn('GitHub token not configured, skipping issue search');
            return [];
        }

        try {
            let searchQuery = `repo:${this.githubConfig.owner}/${this.githubConfig.repo} label:platform`;
            
            // Add query string if provided
            if (query.trim()) {
                searchQuery += ` ${query}`;
            }
            
            // Add filter labels
            Object.entries(filters).forEach(([key, value]) => {
                if (value) {
                    searchQuery += ` label:${key}:${value}`;
                }
            });

            const response = await fetch(
                `https://api.github.com/search/issues?q=${encodeURIComponent(searchQuery)}`,
                {
                    headers: {
                        'Authorization': `token ${this.githubConfig.token}`,
                        'Accept': 'application/vnd.github.v3+json'
                    }
                }
            );

            if (!response.ok) throw new Error('GitHub search failed');
            
            const data = await response.json();
            return data.items || [];
        } catch (error) {
            console.error('GitHub issue search failed:', error);
            return [];
        }
    }

    /**
     * Create GitHub issue for component
     */
    async createGitHubIssue(component) {
        if (!this.githubConfig.token) {
            console.warn('GitHub token not configured, skipping issue creation');
            return null;
        }

        try {
            const issueData = {
                title: `${this.githubConfig.issuePrefix} ${component.id}: ${component.title}`,
                body: this.generateGitHubIssueBody(component),
                labels: component.github?.labels || this.generateLabelsForComponent(component)
            };

            const response = await fetch(
                `https://api.github.com/repos/${this.githubConfig.owner}/${this.githubConfig.repo}/issues`,
                {
                    method: 'POST',
                    headers: {
                        'Authorization': `token ${this.githubConfig.token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(issueData)
                }
            );

            if (!response.ok) throw new Error('Failed to create GitHub issue');
            
            const issue = await response.json();
            
            // Update component metadata with issue number
            component.github = component.github || {};
            component.github.issue = issue.number;
            
            // Save updated component
            await this.saveComponent(component.id, component);
            
            return issue;
        } catch (error) {
            console.error('Failed to create GitHub issue:', error);
            return null;
        }
    }

    /**
     * Generate appropriate labels for a component
     */
    generateLabelsForComponent(component) {
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

    /**
     * Get component analytics
     */
    async getComponentAnalytics() {
        try {
            // In a real implementation, this would query an API
            return {
                totalComponents: 50,
                byStatus: {
                    completed: 20,
                    'in-progress': 25,
                    'not-started': 5
                },
                byType: {
                    'user-story': 18,
                    'feature': 8,
                    'test-case': 12,
                    'ui-flow': 12
                },
                averageProgress: 75
            };
        } catch (error) {
            console.error('Analytics failed:', error);
            return null;
        }
    }
}

// Global component manager instance
window.ComponentManager = new ComponentManager();

// Auto-initialize component if data-component-id is present
document.addEventListener('DOMContentLoaded', () => {
    const componentId = document.body.getAttribute('data-component-id');
    if (componentId) {
        window.ComponentManager.renderComponent(componentId, 'main-content');
    }
});