/**
 * Component Registry GitHub Integration
 * Live sync with GitHub Issues and real-time status updates
 */

class RegistryGitHubSync {
    constructor() {
        this.config = {
            owner: '3Stones-io',
            repo: 'bemeda_personal'
        };
        this.components = [];
        this.scenarios = {};
        this.componentTypes = {};
    }

    async init() {
        await this.fetchComponents();
        this.renderAllViews();
        
        // Auto-refresh every 2 minutes
        setInterval(() => this.refresh(), 120000);
    }

    async fetchComponents() {
        try {
            const query = `
                repo:${this.config.owner}/${this.config.repo} 
                is:issue 
                label:component
            `;

            const response = await fetch(`https://api.github.com/search/issues?q=${encodeURIComponent(query)}&per_page=100`, {
                headers: {
                    'Accept': 'application/vnd.github.v3+json'
                }
            });

            const data = await response.json();
            
            if (data.items && data.items.length > 0) {
                this.components = data.items
                    .map(issue => this.parseIssue(issue))
                    .sort((a, b) => a.componentId.localeCompare(b.componentId));
                
                this.groupComponentsByScenario();
                this.groupComponentsByType();
            } else {
                // Use mock data for demonstration
                this.components = this.getMockComponents();
                this.groupComponentsByScenario();
                this.groupComponentsByType();
            }
        } catch (error) {
            console.warn('Failed to fetch from GitHub, using mock data:', error);
            this.components = this.getMockComponents();
            this.groupComponentsByScenario();
            this.groupComponentsByType();
        }
    }

    parseIssue(issue) {
        const componentMatch = issue.title.match(/^([A-Z]_[A-Z_]+\d+):\s*(.+)/);
        const componentId = componentMatch ? componentMatch[1] : issue.title.split(':')[0] || issue.title;
        const componentTitle = componentMatch ? componentMatch[2] : issue.title;
        
        return {
            id: issue.id,
            number: issue.number,
            componentId: componentId.trim(),
            title: componentTitle.trim(),
            description: issue.body ? issue.body.split('\n')[0].substring(0, 150) + '...' : '',
            status: this.getStatusFromLabels(issue.labels),
            domain: this.getDomainFromId(componentId),
            type: this.getTypeFromId(componentId),
            url: issue.html_url,
            updated: issue.updated_at,
            created: issue.created_at,
            state: issue.state
        };
    }

    getStatusFromLabels(labels) {
        const statusLabel = labels.find(l => l.name.startsWith('status:'));
        if (statusLabel) {
            const status = statusLabel.name.replace('status:', '');
            return status.replace('-', ' ').toLowerCase().replace(' ', '-');
        }
        return 'todo';
    }

    getDomainFromId(componentId) {
        if (componentId.startsWith('B_')) return 'business';
        if (componentId.startsWith('U_')) return 'ux';
        if (componentId.startsWith('T_')) return 'technical';
        return 'other';
    }

    getTypeFromId(componentId) {
        if (componentId.match(/^B_S\d+/)) return 'Scenario';
        if (componentId.match(/^B_US\d+/)) return 'User Story';
        if (componentId.match(/^B_USS\d+/)) return 'Story Step';
        if (componentId.match(/^U_M\d+/)) return 'Mockup';
        if (componentId.match(/^U_UX\d+/)) return 'User Flow';
        if (componentId.match(/^U_C\d+/)) return 'UI Component';
        if (componentId.match(/^T_UC\d+/)) return 'Use Case';
        if (componentId.match(/^T_F\d+/)) return 'Feature';
        if (componentId.match(/^T_TC\d+/)) return 'Tech Component';
        if (componentId.match(/^T_T\d+/)) return 'Test Case';
        return 'Other';
    }

    groupComponentsByScenario() {
        this.scenarios = {};
        
        this.components.forEach(component => {
            // Extract scenario ID (e.g., S001 from B_S001 or B_US001)
            let scenarioId = 'S001'; // default
            if (component.componentId.includes('S001')) {
                scenarioId = 'S001';
            } else if (component.componentId.includes('S002')) {
                scenarioId = 'S002';
            }
            // Add more scenarios as needed
            
            if (!this.scenarios[scenarioId]) {
                this.scenarios[scenarioId] = {
                    id: scenarioId,
                    title: this.getScenarioTitle(scenarioId),
                    description: this.getScenarioDescription(scenarioId),
                    components: []
                };
            }
            
            this.scenarios[scenarioId].components.push(component);
        });
    }

    groupComponentsByType() {
        this.componentTypes = {};
        
        this.components.forEach(component => {
            const type = component.type;
            
            if (!this.componentTypes[type]) {
                this.componentTypes[type] = {
                    type: type,
                    domain: component.domain,
                    components: []
                };
            }
            
            this.componentTypes[type].components.push(component);
        });
    }

    getScenarioTitle(scenarioId) {
        const titles = {
            'S001': 'Cold Call to Candidate Placement',
            'S002': 'Direct Application Process',
            'S003': 'Recurring Placements'
        };
        return titles[scenarioId] || `Scenario ${scenarioId}`;
    }

    getScenarioDescription(scenarioId) {
        const descriptions = {
            'S001': 'Complete recruitment workflow from initial sales contact through successful candidate placement',
            'S002': 'Direct job application process without sales intervention',
            'S003': 'Ongoing placement activities for returning clients'
        };
        return descriptions[scenarioId] || `Description for scenario ${scenarioId}`;
    }

    getMockComponents() {
        return [
            {
                id: 1, number: 1, componentId: 'B_S001', 
                title: 'Cold Call to Candidate Placement',
                description: 'Complete recruitment workflow from initial sales contact through candidate placement',
                status: 'in-progress', domain: 'business', type: 'Scenario',
                url: '#', updated: '2024-01-15', created: '2024-01-10', state: 'open'
            },
            {
                id: 2, number: 2, componentId: 'B_US001', 
                title: 'Organisation Receives Cold Call',
                description: 'Healthcare organisation receives initial contact from Bemeda sales representative',
                status: 'in-progress', domain: 'business', type: 'User Story',
                url: '#', updated: '2024-01-14', created: '2024-01-10', state: 'open'
            },
            {
                id: 3, number: 3, componentId: 'U_M001', 
                title: 'Healthcare Organisation Dashboard',
                description: 'Main dashboard interface for healthcare organisations',
                status: 'todo', domain: 'ux', type: 'Mockup',
                url: '#', updated: '2024-01-13', created: '2024-01-10', state: 'open'
            },
            {
                id: 4, number: 4, componentId: 'T_UC001', 
                title: 'User Authentication System',
                description: 'Complete authentication system with role-based access control',
                status: 'done', domain: 'technical', type: 'Use Case',
                url: '#', updated: '2024-01-12', created: '2024-01-10', state: 'closed'
            }
        ];
    }

    renderAllViews() {
        this.renderScenarioView();
        this.renderTypeView();
        this.renderTableView();
    }

    renderScenarioView() {
        const scenarioContent = document.getElementById('scenario-content');
        if (!scenarioContent) return;

        const scenarioKeys = Object.keys(this.scenarios).sort();
        
        if (scenarioKeys.length === 0) {
            scenarioContent.innerHTML = '<div class="loading">No scenarios found</div>';
            return;
        }

        const html = scenarioKeys.map(scenarioId => {
            const scenario = this.scenarios[scenarioId];
            const completedCount = scenario.components.filter(c => c.status === 'done').length;
            const totalCount = scenario.components.length;
            const isActive = completedCount > 0 && completedCount < totalCount;
            
            return `
                <div class="scenario-card">
                    <div class="scenario-id">B_${scenario.id}</div>
                    <h3 class="scenario-title">${scenario.title}</h3>
                    <p class="scenario-description">${scenario.description}</p>
                    <div class="scenario-components">
                        ${scenario.components.slice(0, 8).map(c => 
                            `<span class="component-tag">${c.componentId}</span>`
                        ).join('')}
                        ${scenario.components.length > 8 ? 
                            `<span class="component-tag">+${scenario.components.length - 8} more</span>` : ''
                        }
                    </div>
                    <div class="scenario-stats">
                        <span class="stats-left">${totalCount} components</span>
                        <div class="live-status">
                            <div class="status-dot ${isActive ? '' : 'pending'}"></div>
                            ${isActive ? 'Active' : 'Planning'}
                        </div>
                    </div>
                </div>
            `;
        }).join('');

        scenarioContent.innerHTML = html;
    }

    renderTypeView() {
        const typeContent = document.getElementById('type-content');
        if (!typeContent) return;

        const typeKeys = Object.keys(this.componentTypes).sort();
        
        if (typeKeys.length === 0) {
            typeContent.innerHTML = '<div class="loading">No component types found</div>';
            return;
        }

        const html = typeKeys.map(typeKey => {
            const typeGroup = this.componentTypes[typeKey];
            
            return `
                <div class="type-card ${typeGroup.domain}">
                    <div class="type-header">
                        <h3 class="type-title">${typeGroup.type}</h3>
                        <span class="type-count">${typeGroup.components.length}</span>
                    </div>
                    <div class="type-items">
                        ${typeGroup.components.slice(0, 6).map(component => `
                            <div class="type-item">
                                <span class="item-id">${component.componentId}</span>
                                <span class="item-status ${this.getStatusClass(component.status)}">${component.status}</span>
                            </div>
                        `).join('')}
                        ${typeGroup.components.length > 6 ? 
                            `<div class="type-item">
                                <span style="font-style: italic; color: var(--color-text-tertiary);">
                                    +${typeGroup.components.length - 6} more components
                                </span>
                            </div>` : ''
                        }
                    </div>
                </div>
            `;
        }).join('');

        typeContent.innerHTML = html;
    }

    renderTableView() {
        const tableBody = document.getElementById('table-body');
        if (!tableBody) return;

        if (this.components.length === 0) {
            tableBody.innerHTML = '<tr><td colspan="6" class="loading">No components found</td></tr>';
            return;
        }

        const html = this.components.map(component => `
            <tr>
                <td><span class="table-id">${component.componentId}</span></td>
                <td>${component.title}</td>
                <td><span class="table-domain ${component.domain}">${component.domain}</span></td>
                <td><span class="item-status ${this.getStatusClass(component.status)}">${component.status}</span></td>
                <td>${this.formatDate(component.updated)}</td>
                <td>
                    <a href="${component.url}" target="_blank" style="color: var(--color-link); text-decoration: none;">
                        View →
                    </a>
                </td>
            </tr>
        `).join('');

        tableBody.innerHTML = html;
    }

    getStatusClass(status) {
        if (status === 'done') return 'done';
        if (status === 'in-progress') return 'progress';
        return 'todo';
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diffTime = Math.abs(now - date);
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays === 0) return 'today';
        if (diffDays === 1) return 'yesterday';
        if (diffDays < 7) return `${diffDays}d ago`;
        return date.toLocaleDateString();
    }

    async refresh() {
        // Show loading states
        const loadingElements = [
            'scenario-content',
            'type-content', 
            'table-body'
        ];
        
        loadingElements.forEach(id => {
            const element = document.getElementById(id);
            if (element) {
                if (id === 'table-body') {
                    element.innerHTML = '<tr><td colspan="6" class="loading">Refreshing...</td></tr>';
                } else {
                    element.innerHTML = '<div class="loading">Refreshing from GitHub...</div>';
                }
            }
        });

        await this.fetchComponents();
        this.renderAllViews();
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('scenario-content')) {
        window.registrySync = new RegistryGitHubSync();
        window.registrySync.init();
    }
});