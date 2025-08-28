/**
 * Simple Read-Only Kanban View
 * Displays GitHub project components in kanban format with filtering
 */

class SimpleKanbanView {
    constructor(config) {
        this.config = {
            containerId: config.containerId || 'kanban-board',
            owner: config.owner || '3Stones-io',
            repo: config.repo || 'bemeda_personal',
            prefix: config.prefix || 'B_', // B_, U_, T_ for filtering
            columns: config.columns || [
                { id: 'todo', title: 'Todo', count: 0 },
                { id: 'in-progress', title: 'In Progress', count: 0 },
                { id: 'done', title: 'Done', count: 0 }
            ]
        };
        
        this.components = [];
        this.showGantt = false;
    }

    async init() {
        await this.fetchComponents();
        this.render();
        this.updateCounts();
        
        // Auto-refresh every 30 seconds
        setInterval(() => this.refresh(), 30000);
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
                    .filter(component => component.componentId.startsWith(this.config.prefix))
                    .sort((a, b) => a.componentId.localeCompare(b.componentId));
            } else {
                // Use mock data for demonstration
                this.components = this.getMockComponents();
            }
        } catch (error) {
            console.warn('Failed to fetch from GitHub, using mock data:', error);
            this.components = this.getMockComponents();
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
            url: issue.html_url,
            assignees: issue.assignees || [],
            labels: issue.labels || [],
            updated: issue.updated_at,
            created: issue.created_at
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

    getMockComponents() {
        const prefix = this.config.prefix;
        if (prefix === 'B_') {
            return [
                {
                    id: 1, number: 1, componentId: 'B_S001', 
                    title: 'Cold Call to Candidate Placement',
                    description: 'Complete recruitment workflow from initial sales contact through candidate placement',
                    status: 'todo', url: '#', assignees: [], labels: [], 
                    updated: '2024-01-15', created: '2024-01-10'
                },
                {
                    id: 2, number: 2, componentId: 'B_US001', 
                    title: 'Organisation Receives Cold Call',
                    description: 'Healthcare organisation receives initial contact from Bemeda sales representative',
                    status: 'in-progress', url: '#', assignees: [], labels: [], 
                    updated: '2024-01-14', created: '2024-01-10'
                },
                {
                    id: 3, number: 3, componentId: 'B_US002', 
                    title: 'Discuss Staffing Needs',
                    description: 'Organisation discusses current staffing challenges and requirements',
                    status: 'in-progress', url: '#', assignees: [], labels: [], 
                    updated: '2024-01-13', created: '2024-01-10'
                },
                {
                    id: 4, number: 4, componentId: 'B_USS001', 
                    title: 'Initial Phone Contact',
                    description: 'Sales team makes first contact with healthcare facility',
                    status: 'done', url: '#', assignees: [], labels: [], 
                    updated: '2024-01-12', created: '2024-01-10'
                }
            ];
        } else if (prefix === 'U_') {
            return [
                {
                    id: 5, number: 5, componentId: 'U_UX001', 
                    title: 'User Registration Flow',
                    description: 'Complete user experience for new user registration process',
                    status: 'todo', url: '#', assignees: [], labels: [], 
                    updated: '2024-01-15', created: '2024-01-10'
                },
                {
                    id: 6, number: 6, componentId: 'U_C001', 
                    title: 'Login Component',
                    description: 'Reusable login form component with validation',
                    status: 'in-progress', url: '#', assignees: [], labels: [], 
                    updated: '2024-01-14', created: '2024-01-10'
                }
            ];
        } else if (prefix === 'T_') {
            return [
                {
                    id: 7, number: 7, componentId: 'T_UC001', 
                    title: 'User Authentication Use Case',
                    description: 'Technical specification for user authentication system',
                    status: 'in-progress', url: '#', assignees: [], labels: [], 
                    updated: '2024-01-15', created: '2024-01-10'
                },
                {
                    id: 8, number: 8, componentId: 'T_F001', 
                    title: 'JWT Token Management',
                    description: 'Implementation of JWT token generation and validation',
                    status: 'done', url: '#', assignees: [], labels: [], 
                    updated: '2024-01-13', created: '2024-01-10'
                }
            ];
        }
        return [];
    }

    render() {
        const container = document.getElementById(this.config.containerId);
        
        if (this.showGantt) {
            container.innerHTML = this.renderGanttView();
        } else {
            container.innerHTML = this.renderKanbanView();
        }
    }

    renderKanbanView() {
        return `
            <div class="view-header">
                <h2>${this.config.prefix.replace('_', '')} Components</h2>
                <div class="view-controls">
                    <button onclick="kanbanView.refresh()" class="view-toggle">
                        <span class="icon">🔄</span> Refresh Now
                    </button>
                    <button onclick="kanbanView.toggleView()" class="view-toggle">
                        <span class="icon">📅</span> Switch to Timeline View
                    </button>
                    <a href="https://github.com/${this.config.owner}/${this.config.repo}/issues" 
                       target="_blank" class="github-link">
                        <span class="icon">🔗</span> Edit on GitHub
                    </a>
                </div>
            </div>
            <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 12px; margin-bottom: 20px; font-size: 0.9rem;">
                <strong>💡 Status Updates:</strong> This kanban reads from issue labels. When you move cards in the GitHub Project, also update the issue labels:
                <code>status:todo</code>, <code>status:in-progress</code>, <code>status:done</code>
            </div>
            <div class="simple-kanban">
                ${this.config.columns.map(column => `
                    <div class="simple-column">
                        <div class="column-header">
                            <h3>${column.title}</h3>
                            <span class="count">${this.getComponentsByStatus(column.id).length}</span>
                        </div>
                        <div class="column-cards">
                            ${this.renderColumnCards(column.id)}
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }

    renderColumnCards(status) {
        const components = this.getComponentsByStatus(status);
        if (components.length === 0) {
            return '<div class="empty-column">No items</div>';
        }
        
        return components.map(component => `
            <div class="simple-card">
                <div class="card-id">${component.componentId}</div>
                <div class="card-title">${component.title}</div>
                <div class="card-description">${component.description}</div>
                <div class="card-footer">
                    <span class="updated">Updated ${this.formatDate(component.updated)}</span>
                    <a href="${component.url}" target="_blank" class="card-link">View →</a>
                </div>
            </div>
        `).join('');
    }

    renderGanttView() {
        return `
            <div class="view-header">
                <h2>${this.config.prefix.replace('_', '')} Timeline</h2>
                <div class="view-controls">
                    <button onclick="kanbanView.refresh()" class="view-toggle">
                        <span class="icon">🔄</span> Refresh Now
                    </button>
                    <button onclick="kanbanView.toggleView()" class="view-toggle">
                        <span class="icon">📋</span> Switch to Kanban View
                    </button>
                    <a href="https://github.com/${this.config.owner}/${this.config.repo}/issues" 
                       target="_blank" class="github-link">
                        <span class="icon">🔗</span> Edit on GitHub
                    </a>
                </div>
            </div>
            <div class="timeline-view">
                <div class="timeline-header">
                    <div class="timeline-labels">Component</div>
                    <div class="timeline-grid">
                        <div class="timeline-months">
                            ${this.renderTimelineMonths()}
                        </div>
                    </div>
                </div>
                <div class="timeline-content">
                    ${this.components.map(component => `
                        <div class="timeline-row">
                            <div class="timeline-label">
                                <div class="component-id">${component.componentId}</div>
                                <div class="component-title">${component.title}</div>
                            </div>
                            <div class="timeline-bar-container">
                                ${this.renderTimelineBar(component)}
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }

    renderTimelineMonths() {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
        return months.map(month => `<div class="month">${month}</div>`).join('');
    }

    renderTimelineBar(component) {
        const statusColors = {
            'todo': '#f0f0f0',
            'in-progress': '#fff3cd', 
            'done': '#d1ecf1'
        };
        
        const width = Math.random() * 60 + 20; // Random width for demo
        const left = Math.random() * 30; // Random start position
        
        return `
            <div class="timeline-bar" 
                 style="background: ${statusColors[component.status]}; 
                        width: ${width}%; 
                        left: ${left}%;">
                <span class="bar-label">${component.status}</span>
            </div>
        `;
    }

    getComponentsByStatus(status) {
        return this.components.filter(c => c.status === status);
    }

    updateCounts() {
        this.config.columns.forEach(column => {
            column.count = this.getComponentsByStatus(column.id).length;
        });
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diffTime = Math.abs(now - date);
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays === 0) return 'today';
        if (diffDays === 1) return 'yesterday';
        if (diffDays < 7) return `${diffDays} days ago`;
        return date.toLocaleDateString();
    }

    toggleView() {
        this.showGantt = !this.showGantt;
        this.render();
    }

    async refresh() {
        await this.fetchComponents();
        this.render();
        this.updateCounts();
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('kanban-board')) {
        const prefix = document.body.dataset.prefix || 'B_';
        window.kanbanView = new SimpleKanbanView({
            containerId: 'kanban-board',
            prefix: prefix
        });
        window.kanbanView.init();
    }
});