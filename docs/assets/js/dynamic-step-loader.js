/**
 * Dynamic Step Content Loader
 * Loads GitHub issue content into step pages in real-time
 */

class DynamicStepLoader {
    constructor() {
        this.stepId = null;
        this.refreshInterval = null;
        this.refreshIntervalTime = 60000; // 1 minute
        this.isLoading = false;
    }

    /**
     * Initialize the loader for a specific step page
     */
    async init(stepId) {
        this.stepId = stepId;
        console.log(`Initializing dynamic loader for step: ${stepId}`);
        
        // Wait for GitHub API to be ready
        if (!window.githubAPI) {
            console.error('GitHub API service not available');
            this.showError('GitHub API service not loaded');
            return;
        }

        await window.githubAPI.initialize();
        
        // Load initial data
        await this.loadStepData();
        
        // Set up auto-refresh
        this.startAutoRefresh();
    }

    /**
     * Load and display step data from GitHub
     */
    async loadStepData() {
        if (this.isLoading) return;
        
        this.isLoading = true;
        this.showLoadingState();
        
        console.log(`[DynamicStepLoader] Starting to load data for step: ${this.stepId}`);

        try {
            // Check if dependencies are loaded
            console.log('[DynamicStepLoader] Dependencies check:', {
                githubAPI: !!window.githubAPI,
                stepMapping: !!window.stepIssueMapping,
                fallbackData: !!window.githubFallbackData,
                getFallbackFn: !!window.getFallbackStepData
            });
            
            const data = await window.githubAPI.getStepData(this.stepId);
            console.log(`[DynamicStepLoader] Received data for ${this.stepId}:`, data);
            
            if (data.error) {
                console.warn(`[DynamicStepLoader] Error for ${this.stepId}:`, data.error, data.message);
                this.showError(data.message || data.error);
            } else {
                console.log(`[DynamicStepLoader] Successfully loaded data for ${this.stepId} from ${data.dataSource}`);
                this.renderStepData(data);
            }
        } catch (error) {
            console.error('[DynamicStepLoader] Exception loading step data:', error);
            this.showError('Failed to load step data from GitHub');
        } finally {
            this.isLoading = false;
            this.hideLoadingState();
        }
    }

    /**
     * Show loading state in the GitHub integration section
     */
    showLoadingState() {
        const githubSection = document.querySelector('.github-integration');
        if (githubSection) {
            const content = githubSection.querySelector('.github-content');
            if (content) {
                content.innerHTML = `
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div style="width: 20px; height: 20px; border: 2px solid #ffffff40; border-top: 2px solid #ffffff; border-radius: 50%; animation: spin 1s linear infinite;"></div>
                        <p><strong>Loading live GitHub content...</strong></p>
                    </div>
                    <style>
                        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
                    </style>
                `;
            }
        }
    }

    /**
     * Hide loading state
     */
    hideLoadingState() {
        // Loading state is replaced by actual content or error message
    }

    /**
     * Show error message
     */
    showError(message) {
        const githubSection = document.querySelector('.github-integration');
        if (githubSection) {
            const content = githubSection.querySelector('.github-content');
            if (content) {
                // Get step info from mapping
                const stepInfo = window.getStepIssueInfo ? window.getStepIssueInfo(this.stepId) : null;
                
                content.innerHTML = `
                    <div style="background: rgba(59, 130, 246, 0.2); border: 1px solid rgba(59, 130, 246, 0.4); border-radius: 6px; padding: 12px; margin: 10px 0;">
                        <p><strong>📋 GitHub Issue Pending</strong></p>
                        <p style="font-size: 0.9em; margin: 8px 0;">${message}</p>
                        ${stepInfo ? `
                            <p style="font-size: 0.9em; margin: 8px 0;">Expected issue title: "${this.stepId}: ${stepInfo.title}"</p>
                        ` : ''}
                        <div style="margin-top: 12px; display: flex; gap: 8px; flex-wrap: wrap;">
                            <button onclick="stepLoader.loadStepData()" style="padding: 4px 12px; background: rgba(255,255,255,0.2); border: 1px solid rgba(255,255,255,0.3); border-radius: 4px; color: white; cursor: pointer;">
                                🔄 Retry
                            </button>
                            <a href="https://github.com/3Stones-io/bemeda_personal/issues/new?labels=step:${this.stepId}&title=${encodeURIComponent(this.stepId + ': ' + (stepInfo ? stepInfo.title : 'Step Title'))}" 
                               target="_blank" 
                               style="padding: 4px 12px; background: rgba(34, 197, 94, 0.2); border: 1px solid rgba(34, 197, 94, 0.4); border-radius: 4px; color: white; text-decoration: none; display: inline-block;">
                                ➕ Create Issue
                            </a>
                        </div>
                    </div>
                    <div style="background: rgba(255,255,255,0.1); border-radius: 6px; padding: 12px; margin: 12px 0;">
                        <p style="margin: 0 0 8px;"><strong>📝 Placeholder Content:</strong></p>
                        <p style="font-size: 0.9em; margin: 4px 0;">This step is part of the ${this.getActorName()} journey in the Bemeda platform.</p>
                        <p style="font-size: 0.9em; margin: 4px 0;">The GitHub issue for this step will contain:</p>
                        <ul style="font-size: 0.85em; margin: 8px 0; padding-left: 20px;">
                            <li>Detailed step description and requirements</li>
                            <li>Acceptance criteria and test cases</li>
                            <li>Links to related UX and Technical components</li>
                            <li>Discussion and implementation notes</li>
                        </ul>
                    </div>
                `;
            }
        }
    }
    
    /**
     * Get actor name based on step ID
     */
    getActorName() {
        const stepNum = parseInt(this.stepId.substring(1));
        if (stepNum >= 1 && stepNum <= 8) return 'Healthcare Organisation';
        if (stepNum >= 9 && stepNum <= 14) return 'JobSeeker';
        if (stepNum >= 15 && stepNum <= 19) return 'Sales Team';
        return 'Platform';
    }

    /**
     * Render step data from GitHub
     */
    renderStepData(data) {
        const { issue, comments, crossReferences, lastUpdated, dataSource } = data;
        
        // Update GitHub integration section
        this.renderGitHubSection(issue, comments, crossReferences, lastUpdated, dataSource);
        
        // Update step metadata if needed
        this.updateStepMetadata(issue);
        
        // Update cross-references section
        this.updateCrossReferences(crossReferences);
        
        // Update acceptance criteria if present in issue
        this.updateAcceptanceCriteria(issue);
    }

    /**
     * Render the main GitHub integration section
     */
    renderGitHubSection(issue, comments, crossReferences, lastUpdated, dataSource = 'api') {
        const githubSection = document.querySelector('.github-integration');
        if (!githubSection) return;

        const content = githubSection.querySelector('.github-content');
        if (!content) return;

        const lastUpdateTime = new Date(lastUpdated).toLocaleString();
        const commentsCount = comments.length;
        const crossRefCount = crossReferences.length;
        
        const dataSourceBadge = {
            'api': '🟢 Live API',
            'fallback': '🔵 Cached Data',
            'fallback-error': '🟡 Offline Mode',
            'mapping': '📋 Placeholder'
        }[dataSource] || '📡 Unknown';

        content.innerHTML = `
            <div style="display: flex; justify-content: between; align-items: flex-start; gap: 20px; margin-bottom: 16px;">
                <div style="flex: 1;">
                    <h3 style="margin: 0 0 8px 0; color: #e2e8f0;">
                        <a href="${issue.html_url}" target="_blank" style="color: #e2e8f0; text-decoration: none;">
                            📋 ${issue.title}
                        </a>
                    </h3>
                    <div style="font-size: 0.9em; color: #cbd5e1; margin-bottom: 12px;">
                        <strong>Issue #${issue.number}</strong> • 
                        ${issue.state === 'open' ? '🟢 Open' : '🔴 Closed'} • 
                        Updated: ${new Date(issue.updated_at).toLocaleDateString()}
                    </div>
                </div>
                <div style="text-align: right; font-size: 0.85em; color: #94a3b8;">
                    ${dataSourceBadge}<br/>
                    Last sync: ${lastUpdateTime}
                    <br/>
                    <button onclick="stepLoader.loadStepData()" style="margin-top: 4px; padding: 2px 8px; background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); border-radius: 4px; color: #e2e8f0; cursor: pointer; font-size: 0.8em;">
                        🔄 Refresh
                    </button>
                </div>
            </div>

            <div style="background: rgba(255,255,255,0.1); border-radius: 6px; padding: 12px; margin: 12px 0;">
                <div style="font-size: 0.9em; color: #e2e8f0;">
                    ${this.formatMarkdown(issue.body || 'No description provided.')}
                </div>
            </div>

            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; margin: 16px 0;">
                <div style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
                    <div style="font-size: 1.2em; font-weight: bold;">💬 ${commentsCount}</div>
                    <div style="font-size: 0.8em; color: #cbd5e1;">Comments</div>
                </div>
                <div style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
                    <div style="font-size: 1.2em; font-weight: bold;">🔗 ${crossRefCount}</div>
                    <div style="font-size: 0.8em; color: #cbd5e1;">Components</div>
                </div>
                <div style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
                    <div style="font-size: 1.2em; font-weight: bold;">${issue.labels.length}</div>
                    <div style="font-size: 0.8em; color: #cbd5e1;">Labels</div>
                </div>
            </div>

            ${commentsCount > 0 ? this.renderComments(comments) : ''}

            <div style="margin-top: 12px; text-align: center;">
                <a href="${issue.html_url}" target="_blank" style="display: inline-block; padding: 8px 16px; background: rgba(255,255,255,0.2); border: 1px solid rgba(255,255,255,0.3); border-radius: 6px; color: #e2e8f0; text-decoration: none; font-weight: 500;">
                    📝 View & Edit on GitHub →
                </a>
            </div>
        `;
    }

    /**
     * Render comments section
     */
    renderComments(comments) {
        const latestComments = comments.slice(-3); // Show last 3 comments
        
        return `
            <div style="margin-top: 16px;">
                <h4 style="margin: 0 0 12px 0; color: #e2e8f0; border-bottom: 1px solid rgba(255,255,255,0.2); padding-bottom: 4px;">
                    💬 Recent Discussion ${comments.length > 3 ? `(${comments.length - 3} more on GitHub)` : ''}
                </h4>
                ${latestComments.map(comment => `
                    <div style="background: rgba(255,255,255,0.05); border-left: 3px solid rgba(255,255,255,0.3); padding: 10px; margin: 8px 0; border-radius: 4px;">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                            <strong style="color: #e2e8f0; font-size: 0.9em;">
                                <img src="${comment.user.avatar_url}" style="width: 16px; height: 16px; border-radius: 50%; margin-right: 6px; vertical-align: middle;">
                                ${comment.user.login}
                            </strong>
                            <span style="font-size: 0.8em; color: #94a3b8;">
                                ${new Date(comment.created_at).toLocaleDateString()}
                            </span>
                        </div>
                        <div style="font-size: 0.85em; color: #cbd5e1; line-height: 1.4;">
                            ${this.formatMarkdown(comment.body)}
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }

    /**
     * Simple markdown formatting for basic text
     */
    formatMarkdown(text) {
        if (!text) return '';
        
        return text
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/g, '<em>$1</em>')
            .replace(/`(.*?)`/g, '<code style="background: rgba(255,255,255,0.2); padding: 2px 4px; border-radius: 2px;">$1</code>')
            .replace(/\n\n/g, '</p><p>')
            .replace(/\n/g, '<br>')
            .replace(/^(.*)$/, '<p>$1</p>');
    }

    /**
     * Update cross-references section
     */
    updateCrossReferences(crossReferences) {
        if (crossReferences.length === 0) return;

        const crossRefSection = document.querySelector('.content-section .component-links');
        if (crossRefSection) {
            // Add live cross-reference data
            crossReferences.forEach(ref => {
                const isUX = ref.labels.some(label => label.name === 'component:ux');
                const isTech = ref.labels.some(label => label.name === 'component:tech');
                
                if (isUX || isTech) {
                    const type = isUX ? 'ux' : 'tech';
                    const icon = isUX ? '🎨' : '⚙️';
                    const typeName = isUX ? 'UX' : 'Technical';
                    
                    const linkElement = document.createElement('a');
                    linkElement.href = ref.html_url;
                    linkElement.target = '_blank';
                    linkElement.className = `component-link ${type}`;
                    linkElement.innerHTML = `
                        <div class="component-title">${icon} ${typeName} - ${ref.title}</div>
                        <div class="component-description">
                            Issue #${ref.number} • ${ref.state === 'open' ? '🟢 Open' : '🔴 Closed'}
                            <br/>${ref.body ? ref.body.substring(0, 100) + '...' : 'No description'}
                        </div>
                    `;
                    
                    crossRefSection.appendChild(linkElement);
                }
            });
        }
    }

    /**
     * Update acceptance criteria from GitHub issue checkboxes
     */
    updateAcceptanceCriteria(issue) {
        const criteriaSection = document.querySelector('.content-section');
        const criteriaTitle = Array.from(document.querySelectorAll('.section-title')).find(
            title => title.textContent.includes('Acceptance Criteria')
        );
        
        if (criteriaTitle && issue.body) {
            // Extract checkboxes from issue body
            const checkboxes = [...issue.body.matchAll(/- \[([ x])\] (.*)/gi)];
            
            if (checkboxes.length > 0) {
                const criteriaContainer = criteriaTitle.parentElement;
                const existingList = criteriaContainer.querySelector('ul');
                
                if (existingList) {
                    existingList.innerHTML = checkboxes.map(checkbox => {
                        const isChecked = checkbox[1].toLowerCase() === 'x';
                        const text = checkbox[2];
                        return `<li style="color: ${isChecked ? '#28a745' : 'inherit'};">
                            ${isChecked ? '✅' : '🔲'} ${text}
                        </li>`;
                    }).join('');
                }
            }
        }
    }

    /**
     * Start auto-refresh for live updates
     */
    startAutoRefresh() {
        // Clear any existing interval
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }

        this.refreshInterval = setInterval(() => {
            console.log('Auto-refreshing step data...');
            this.loadStepData();
        }, this.refreshIntervalTime);
    }

    /**
     * Stop auto-refresh
     */
    stopAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
            this.refreshInterval = null;
        }
    }

    /**
     * Clean up when page unloads
     */
    destroy() {
        this.stopAutoRefresh();
    }
}

// Create global instance and auto-initialize
window.stepLoader = new DynamicStepLoader();

// Load step mapping and fallback data scripts first
const mappingScript = document.createElement('script');
mappingScript.src = '../../assets/js/step-issue-mapping.js';
document.head.appendChild(mappingScript);

const fallbackScript = document.createElement('script');
fallbackScript.src = '../../assets/js/github-fallback-data.js';
document.head.appendChild(fallbackScript);

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    // Extract step ID from URL or page context
    const pathMatch = window.location.pathname.match(/steps\/(\w+)\.html/);
    if (pathMatch) {
        const stepId = pathMatch[1].toUpperCase();
        window.stepLoader.init(stepId);
    }
});

// Clean up on page unload
window.addEventListener('beforeunload', () => {
    if (window.stepLoader) {
        window.stepLoader.destroy();
    }
});