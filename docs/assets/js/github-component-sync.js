/**
 * GitHub Component Sync System
 * 
 * Provides real-time synchronization between GitHub Issues and component pages
 * Fetches issue data, comments, and status updates dynamically
 */

class GitHubComponentSync {
    constructor(config = {}) {
        this.config = {
            owner: '3Stones-io',
            repo: 'bemeda_personal',
            baseApiUrl: 'https://api.github.com',
            ...config
        };
        
        this.cache = new Map();
        this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
    }

    /**
     * Fetch component data from GitHub Issue
     * @param {string} componentId - Component ID (e.g., 'US001', 'F001', 'M001')
     * @returns {Promise<Object>} Component data
     */
    async fetchComponent(componentId) {
        const cacheKey = `component_${componentId}`;
        const cached = this.cache.get(cacheKey);
        
        if (cached && (Date.now() - cached.timestamp) < this.cacheTimeout) {
            return cached.data;
        }

        try {
            // First, find the issue by searching for the component ID in title
            const searchUrl = `${this.config.baseApiUrl}/search/issues?q=repo:${this.config.owner}/${this.config.repo}+label:component+in:title+"${componentId}"`;
            
            const searchResponse = await fetch(searchUrl);
            if (!searchResponse.ok) {
                throw new Error(`GitHub API search failed: ${searchResponse.status}`);
            }
            
            const searchData = await searchResponse.json();
            if (searchData.items.length === 0) {
                throw new Error(`Component ${componentId} not found`);
            }

            const issue = searchData.items[0];
            
            // Fetch detailed issue data
            const issueUrl = `${this.config.baseApiUrl}/repos/${this.config.owner}/${this.config.repo}/issues/${issue.number}`;
            const issueResponse = await fetch(issueUrl);
            if (!issueResponse.ok) {
                throw new Error(`Failed to fetch issue details: ${issueResponse.status}`);
            }
            
            const issueData = await issueResponse.json();
            
            // Parse component metadata from issue body
            const componentData = this.parseComponentData(issueData, componentId);
            
            // Cache the result
            this.cache.set(cacheKey, {
                data: componentData,
                timestamp: Date.now()
            });
            
            return componentData;
            
        } catch (error) {
            console.error(`Failed to fetch component ${componentId}:`, error);
            return this.getComponentFallback(componentId);
        }
    }

    /**
     * Fetch comments for a component
     * @param {string} componentId - Component ID
     * @returns {Promise<Array>} Array of comments
     */
    async fetchComments(componentId) {
        try {
            const component = await this.fetchComponent(componentId);
            if (!component.issueNumber) {
                return [];
            }

            const commentsUrl = `${this.config.baseApiUrl}/repos/${this.config.owner}/${this.config.repo}/issues/${component.issueNumber}/comments`;
            const response = await fetch(commentsUrl);
            
            if (!response.ok) {
                throw new Error(`Failed to fetch comments: ${response.status}`);
            }
            
            const comments = await response.json();
            
            return comments.map(comment => ({
                id: comment.id,
                author: comment.user.login,
                authorAvatar: comment.user.avatar_url,
                body: comment.body,
                createdAt: new Date(comment.created_at),
                updatedAt: new Date(comment.updated_at),
                url: comment.html_url
            }));
            
        } catch (error) {
            console.error(`Failed to fetch comments for ${componentId}:`, error);
            return [];
        }
    }

    /**
     * Parse component data from GitHub issue
     * @param {Object} issueData - Raw GitHub issue data
     * @param {string} componentId - Component ID
     * @returns {Object} Parsed component data
     */
    parseComponentData(issueData, componentId) {
        // Extract metadata from issue body
        const metadata = this.extractMetadata(issueData.body);
        
        // Parse labels for status, priority, domain, etc.
        const labels = issueData.labels.map(label => label.name);
        const status = this.extractLabelValue(labels, 'status:', 'planning');
        const priority = this.extractLabelValue(labels, 'priority:', 'medium');
        const domain = this.extractLabelValue(labels, 'domain:', 'scenarios');
        const type = this.getComponentType(componentId, labels);
        
        return {
            id: componentId,
            title: issueData.title.replace(/^\[COMPONENT\]\s*/, '').replace(new RegExp(`^${componentId}\\s*-\\s*`), ''),
            description: this.extractDescription(issueData.body),
            type,
            domain,
            status,
            priority,
            labels,
            issueNumber: issueData.number,
            issueUrl: issueData.html_url,
            createdAt: new Date(issueData.created_at),
            updatedAt: new Date(issueData.updated_at),
            author: issueData.user.login,
            assignees: issueData.assignees.map(a => a.login),
            metadata,
            acceptanceCriteria: this.extractAcceptanceCriteria(issueData.body),
            userStory: this.extractUserStory(issueData.body),
            relatedComponents: this.extractRelatedComponents(issueData.body)
        };
    }

    /**
     * Extract metadata JSON from issue body
     */
    extractMetadata(body) {
        const metadataMatch = body.match(/```json\s*\n([\s\S]*?)\n```/);
        if (metadataMatch) {
            try {
                return JSON.parse(metadataMatch[1]);
            } catch (e) {
                console.warn('Failed to parse metadata JSON:', e);
            }
        }
        return {};
    }

    /**
     * Extract description from issue body
     */
    extractDescription(body) {
        const descMatch = body.match(/### Description\s*\n(.*?)(?=\n###|\n\n|$)/s);
        return descMatch ? descMatch[1].trim() : '';
    }

    /**
     * Extract acceptance criteria from issue body
     */
    extractAcceptanceCriteria(body) {
        const criteriaMatch = body.match(/### Acceptance Criteria\s*\n(.*?)(?=\n###|\n\n|$)/s);
        if (criteriaMatch) {
            return criteriaMatch[1]
                .split('\n')
                .filter(line => line.trim().startsWith('- ['))
                .map(line => ({
                    completed: line.includes('- [x]'),
                    text: line.replace(/- \[[x ]\]\s*/, '').trim()
                }));
        }
        return [];
    }

    /**
     * Extract user story from issue body
     */
    extractUserStory(body) {
        const storyMatch = body.match(/As a\s+([^,]+),\s*I want to\s+([^,]+)\s*so that\s+(.+?)(?=\.|$)/i);
        if (storyMatch) {
            return {
                who: storyMatch[1].trim(),
                what: storyMatch[2].trim(),
                why: storyMatch[3].trim(),
                full: storyMatch[0]
            };
        }
        return null;
    }

    /**
     * Extract related components from issue body
     */
    extractRelatedComponents(body) {
        const componentsMatch = body.match(/### Related Components\s*\n(.*?)(?=\n###|\n\n|$)/s);
        if (componentsMatch) {
            const componentIds = componentsMatch[1].match(/[A-Z]+\d{3}/g);
            return componentIds || [];
        }
        return [];
    }

    /**
     * Extract label value with prefix
     */
    extractLabelValue(labels, prefix, defaultValue) {
        const label = labels.find(l => l.startsWith(prefix));
        return label ? label.replace(prefix, '') : defaultValue;
    }

    /**
     * Determine component type from ID and labels
     */
    getComponentType(componentId, labels) {
        const typeMap = {
            'US': 'user-story',
            'UC': 'use-case', 
            'UX': 'ui-component',
            'F': 'feature',
            'TC': 'technical-component',
            'T': 'test-case',
            'M': 'mockup',
            'C': 'component'
        };
        
        const prefix = componentId.match(/^[A-Z]+/)?.[0];
        return typeMap[prefix] || 'component';
    }

    /**
     * Fallback data when GitHub fetch fails
     */
    getComponentFallback(componentId) {
        return {
            id: componentId,
            title: `Component ${componentId}`,
            description: 'Component data unavailable - please check GitHub Issue',
            type: this.getComponentType(componentId, []),
            domain: 'scenarios',
            status: 'unknown',
            priority: 'medium',
            labels: [],
            issueNumber: null,
            issueUrl: `https://github.com/${this.config.owner}/${this.config.repo}/issues`,
            createdAt: new Date(),
            updatedAt: new Date(),
            author: 'unknown',
            assignees: [],
            metadata: {},
            acceptanceCriteria: [],
            userStory: null,
            relatedComponents: []
        };
    }

    /**
     * Render component data to HTML
     */
    renderComponent(componentData, container) {
        if (typeof container === 'string') {
            container = document.querySelector(container);
        }
        
        if (!container) {
            console.error('Container not found for component rendering');
            return;
        }

        const html = this.generateComponentHTML(componentData);
        container.innerHTML = html;
        
        // Add event listeners for GitHub links
        this.attachEventListeners(container, componentData);
    }

    /**
     * Generate HTML for component
     */
    generateComponentHTML(data) {
        const statusClass = {
            'planning': 'status-planning',
            'in-progress': 'status-progress', 
            'review': 'status-review',
            'completed': 'status-completed'
        }[data.status] || 'status-planning';

        const priorityClass = {
            'high': 'priority-high',
            'medium': 'priority-medium',
            'low': 'priority-low'
        }[data.priority] || 'priority-medium';

        return `
            <div class="github-banner">
                <div class="github-info">
                    <span style="font-size: 1.2rem;">🔗</span>
                    <div>
                        <div style="font-weight: 600;">Live GitHub Component</div>
                        <div style="font-size: 0.9rem; opacity: 0.9;">
                            Issue #${data.issueNumber} • Updated ${this.formatDate(data.updatedAt)}
                        </div>
                    </div>
                </div>
                <div class="github-actions">
                    <a href="${data.issueUrl}" class="github-btn" target="_blank">💬 View Discussion</a>
                    <a href="${data.issueUrl}" class="github-btn primary" target="_blank">✏️ Edit Component</a>
                </div>
            </div>

            <div class="component-header">
                <div class="component-title">
                    <span class="component-id">${data.id}</span>
                    <h1 class="component-name">${data.title}</h1>
                </div>
                <div class="component-meta">
                    <div class="meta-item">
                        <span class="meta-label">Type:</span>
                        <span>${data.type.replace('-', ' ')}</span>
                    </div>
                    <div class="meta-item">
                        <span class="meta-label">Domain:</span>
                        <span>${data.domain}</span>
                    </div>
                    <div class="meta-item">
                        <span class="meta-label">Status:</span>
                        <span class="${statusClass}">${data.status}</span>
                    </div>
                    <div class="meta-item">
                        <span class="meta-label">Priority:</span>
                        <span class="${priorityClass}">${data.priority}</span>
                    </div>
                </div>
                <p class="component-description">${data.description}</p>
            </div>

            ${data.userStory ? this.renderUserStory(data.userStory) : ''}
            ${data.acceptanceCriteria.length ? this.renderAcceptanceCriteria(data.acceptanceCriteria) : ''}
            ${data.relatedComponents.length ? this.renderRelatedComponents(data.relatedComponents) : ''}
            
            <div class="comments-container" id="comments-${data.id}">
                <div class="loading">Loading comments...</div>
            </div>
        `;
    }

    /**
     * Render user story section
     */
    renderUserStory(story) {
        return `
            <div class="content-section">
                <h2 class="section-title">📝 User Story</h2>
                <div class="user-story-format">
                    <div class="story-text">${story.full}</div>
                    <div class="story-breakdown">
                        <div class="breakdown-item">
                            <div class="breakdown-label">Who</div>
                            <div class="breakdown-value">${story.who}</div>
                        </div>
                        <div class="breakdown-item">
                            <div class="breakdown-label">What</div>
                            <div class="breakdown-value">${story.what}</div>
                        </div>
                        <div class="breakdown-item">
                            <div class="breakdown-label">Why</div>
                            <div class="breakdown-value">${story.why}</div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    /**
     * Render acceptance criteria
     */
    renderAcceptanceCriteria(criteria) {
        const criteriaHTML = criteria.map(criterion => `
            <li class="criteria-item">
                <span class="criteria-check">${criterion.completed ? '✓' : '○'}</span>
                <span class="criteria-text">${criterion.text}</span>
            </li>
        `).join('');

        return `
            <div class="content-section">
                <h2 class="section-title">✅ Acceptance Criteria</h2>
                <ul class="criteria-list">${criteriaHTML}</ul>
            </div>
        `;
    }

    /**
     * Render related components
     */
    renderRelatedComponents(components) {
        const componentsHTML = components.map(comp => `
            <a href="${comp}.html" class="component-link">${comp}</a>
        `).join('');

        return `
            <div class="content-section">
                <h2 class="section-title">🔗 Related Components</h2>
                <div class="related-components">${componentsHTML}</div>
            </div>
        `;
    }

    /**
     * Render comments section
     */
    async renderComments(componentId, container) {
        const comments = await this.fetchComments(componentId);
        
        if (typeof container === 'string') {
            container = document.querySelector(container);
        }

        const commentsHTML = comments.length ? comments.map(comment => `
            <div class="comment-item">
                <div class="comment-header">
                    <img src="${comment.authorAvatar}" alt="${comment.author}" class="comment-avatar">
                    <span class="comment-author">${comment.author}</span>
                    <span class="comment-time">${this.formatDate(comment.createdAt)}</span>
                </div>
                <div class="comment-content">${this.formatMarkdown(comment.body)}</div>
            </div>
        `).join('') : '<p class="no-comments">No comments yet.</p>';

        container.innerHTML = `
            <div class="comments-section">
                <div class="comments-header">
                    <h3>💬 Team Discussion</h3>
                    <a href="${await this.getIssueUrl(componentId)}#issuecomment-new" class="github-btn" target="_blank">
                        ➕ Add Comment
                    </a>
                </div>
                ${commentsHTML}
            </div>
        `;
    }

    /**
     * Format date for display
     */
    formatDate(date) {
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);

        if (diffMins < 60) return `${diffMins} minutes ago`;
        if (diffHours < 24) return `${diffHours} hours ago`;
        if (diffDays < 30) return `${diffDays} days ago`;
        return date.toLocaleDateString();
    }

    /**
     * Basic markdown formatting
     */
    formatMarkdown(text) {
        return text
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/g, '<em>$1</em>')
            .replace(/`(.*?)`/g, '<code>$1</code>')
            .replace(/\n/g, '<br>');
    }

    /**
     * Get issue URL for component
     */
    async getIssueUrl(componentId) {
        const component = await this.fetchComponent(componentId);
        return component.issueUrl;
    }

    /**
     * Attach event listeners
     */
    attachEventListeners(container, componentData) {
        // Auto-refresh functionality
        const refreshInterval = setInterval(async () => {
            // Clear cache for this component
            this.cache.delete(`component_${componentData.id}`);
            
            // Re-fetch and update
            const updatedData = await this.fetchComponent(componentData.id);
            if (updatedData.updatedAt > componentData.updatedAt) {
                this.renderComponent(updatedData, container);
                
                // Update comments
                const commentsContainer = container.querySelector(`#comments-${componentData.id}`);
                if (commentsContainer) {
                    await this.renderComments(componentData.id, commentsContainer);
                }
            }
        }, 60000); // Check every minute

        // Store interval ID for cleanup
        container.dataset.refreshInterval = refreshInterval;
    }
}

// Global instance
window.gitHubSync = new GitHubComponentSync();

// Auto-initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
    // Auto-detect component ID from page
    const componentId = document.querySelector('[data-component-id]')?.dataset.componentId ||
                       document.querySelector('.component-id')?.textContent?.trim() ||
                       document.title.match(/^([A-Z]+\d{3})/)?.[1];

    if (componentId) {
        const container = document.querySelector('.component-container') || 
                         document.querySelector('#component-content') ||
                         document.querySelector('.container');
        
        if (container) {
            // Load and render component
            window.gitHubSync.fetchComponent(componentId).then(data => {
                window.gitHubSync.renderComponent(data, container);
                
                // Load comments
                const commentsContainer = container.querySelector(`#comments-${componentId}`);
                if (commentsContainer) {
                    window.gitHubSync.renderComments(componentId, commentsContainer);
                }
            });
        }
    }
});