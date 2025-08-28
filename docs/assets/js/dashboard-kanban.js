/**
 * Dashboard Kanban View
 * Compact kanban views for all domains with limited cards (4-5 per column)
 */

class DashboardKanban {
    constructor() {
        this.config = {
            owner: '3Stones-io',
            repo: 'bemeda_personal',
            maxCards: 4, // Limit cards per column
            columns: [
                { id: 'todo', title: 'Todo', count: 0 },
                { id: 'in-progress', title: 'In Progress', count: 0 },
                { id: 'done', title: 'Done', count: 0 }
            ]
        };
        
        this.domains = {
            business: { prefix: 'B_', components: [], githubFilter: 'label%3A%22domain%3Ascenarios%22' },
            ux: { prefix: 'U_', components: [], githubFilter: 'label%3A%22domain%3Aux%22' },
            technical: { prefix: 'T_', components: [], githubFilter: 'label%3A%22domain%3Atechnical%22' }
        };
    }

    async init() {
        await this.fetchAllDomains();
        this.renderAllDomains();
        
        // Auto-refresh every 2 minutes
        setInterval(() => this.refreshAllDomains(), 120000);
    }

    async fetchAllDomains() {
        for (const domain in this.domains) {
            await this.fetchDomain(domain);
        }
    }

    async fetchDomain(domainKey) {
        try {
            const domain = this.domains[domainKey];
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
                domain.components = data.items
                    .map(issue => this.parseIssue(issue))
                    .filter(component => component.componentId.startsWith(domain.prefix))
                    .sort((a, b) => a.componentId.localeCompare(b.componentId));
            } else {
                domain.components = this.getMockComponents(domain.prefix);
            }
        } catch (error) {
            console.warn(`Failed to fetch ${domainKey} components:`, error);
            this.domains[domainKey].components = this.getMockComponents(this.domains[domainKey].prefix);
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
            description: issue.body ? issue.body.split('\n')[0].substring(0, 100) + '...' : '',
            status: this.getStatusFromLabels(issue.labels),
            url: issue.html_url,
            updated: issue.updated_at
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

    getMockComponents(prefix) {
        if (prefix === 'B_') {
            return [
                {
                    id: 1, number: 1, componentId: 'B_S001', 
                    title: 'Cold Call to Candidate Placement',
                    status: 'todo', url: '#', updated: '2024-01-15'
                },
                {
                    id: 2, number: 2, componentId: 'B_US001', 
                    title: 'Organisation Receives Cold Call',
                    status: 'in-progress', url: '#', updated: '2024-01-14'
                },
                {
                    id: 3, number: 3, componentId: 'B_US002', 
                    title: 'Discuss Staffing Needs',
                    status: 'in-progress', url: '#', updated: '2024-01-13'
                },
                {
                    id: 4, number: 4, componentId: 'B_USS001', 
                    title: 'Initial Phone Contact',
                    status: 'done', url: '#', updated: '2024-01-12'
                }
            ];
        } else if (prefix === 'U_') {
            return [
                {
                    id: 5, number: 5, componentId: 'U_UX001', 
                    title: 'User Registration Flow',
                    status: 'todo', url: '#', updated: '2024-01-15'
                },
                {
                    id: 6, number: 6, componentId: 'U_C001', 
                    title: 'Login Component',
                    status: 'in-progress', url: '#', updated: '2024-01-14'
                }
            ];
        } else if (prefix === 'T_') {
            return [
                {
                    id: 7, number: 7, componentId: 'T_UC001', 
                    title: 'User Authentication Use Case',
                    status: 'in-progress', url: '#', updated: '2024-01-15'
                },
                {
                    id: 8, number: 8, componentId: 'T_F001', 
                    title: 'JWT Token Management',
                    status: 'done', url: '#', updated: '2024-01-13'
                }
            ];
        }
        return [];
    }

    renderAllDomains() {
        this.renderDomain('business');
        this.renderDomain('ux');
        this.renderDomain('technical');
    }

    renderDomain(domainKey) {
        const domain = this.domains[domainKey];
        const boardElement = document.getElementById(domainKey + '-board');
        
        if (!boardElement) return;
        
        const html = this.config.columns.map(column => {
            const components = this.getComponentsByStatus(domain.components, column.id);
            const limitedComponents = components.slice(0, this.config.maxCards);
            const hasMore = components.length > this.config.maxCards;
            
            return `
                <div class="compact-column">
                    <div class="compact-header">
                        <h4>${column.title}</h4>
                        <span class="compact-count">${components.length}</span>
                    </div>
                    <div class="compact-cards">
                        ${limitedComponents.length === 0 
                            ? '<div style="text-align: center; color: var(--color-text-tertiary); font-style: italic; padding: 20px;">No items</div>'
                            : limitedComponents.map(component => `
                                <div class="compact-card ${domainKey}">
                                    <div class="card-id">${component.componentId}</div>
                                    <div class="card-title">${component.title}</div>
                                </div>
                            `).join('')
                        }
                        ${hasMore ? `
                            <div class="more-link">
                                <a href="https://github.com/orgs/3Stones-io/projects/12/views/2?filterQuery=${domain.githubFilter}" target="_blank">
                                    +${components.length - this.config.maxCards} more →
                                </a>
                            </div>
                        ` : ''}
                    </div>
                </div>
            `;
        }).join('');
        
        boardElement.innerHTML = html;
    }

    getComponentsByStatus(components, status) {
        return components.filter(c => c.status === status);
    }

    async refreshDomain(domainKey) {
        await this.fetchDomain(domainKey);
        this.renderDomain(domainKey);
    }

    async refreshAllDomains() {
        await this.fetchAllDomains();
        this.renderAllDomains();
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    if (document.querySelector('.compact-kanban')) {
        window.dashboardKanban = new DashboardKanban();
        window.dashboardKanban.init();
    }
});