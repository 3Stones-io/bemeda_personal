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
            business: { prefix: 'B_', components: [], githubFilter: 'label%3A%22domain%3Ascenarios%22+label%3A%22component%22' },
            ux: { prefix: 'U_', components: [], githubFilter: 'label%3A%22domain%3Aux-ui%22+label%3A%22component%22' },
            technical: { prefix: 'T_', components: [], githubFilter: 'label%3A%22domain%3Atechnical%22+label%3A%22component%22' }
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
                label:"domain:${domainKey === 'business' ? 'scenarios' : domainKey === 'ux' ? 'ux-ui' : 'technical'}"
            `;

            console.log(`Fetching ${domainKey} components with query:`, query);

            const response = await fetch(`https://api.github.com/search/issues?q=${encodeURIComponent(query)}&per_page=100`, {
                headers: {
                    'Accept': 'application/vnd.github.v3+json'
                }
            });

            const data = await response.json();
            console.log(`${domainKey} API response:`, data);
            
            if (data.items && data.items.length > 0) {
                console.log(`Found ${data.items.length} ${domainKey} issues from GitHub`);
                domain.components = data.items
                    .map(issue => this.parseIssue(issue))
                    .filter(component => component.componentId.startsWith(domain.prefix))
                    .sort((a, b) => a.componentId.localeCompare(b.componentId));
                domain.dataSource = 'github';
            } else {
                console.log(`No ${domainKey} issues found, using mock data`);
                domain.components = this.getMockComponents(domain.prefix);
                domain.dataSource = 'mock';
            }
        } catch (error) {
            console.warn(`Failed to fetch ${domainKey} components:`, error);
            this.domains[domainKey].components = this.getMockComponents(this.domains[domainKey].prefix);
            this.domains[domainKey].dataSource = 'mock';
        }
    }

    parseIssue(issue) {
        // Handle format like "B_S001_US001_USS001 - Receive initial sales call"
        const componentMatch = issue.title.match(/^([A-Z_]+\d+(?:_[A-Z]+\d+)*)\s*[-:]\s*(.+)/);
        const componentId = componentMatch ? componentMatch[1] : issue.title.split(/[-:]/)[0] || issue.title;
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
            // Map GitHub status labels to our kanban columns
            if (status === 'planning' || status === 'backlog') return 'todo';
            if (status === 'in-progress' || status === 'development') return 'in-progress';
            if (status === 'completed' || status === 'done') return 'done';
            return status;
        }
        // Default to 'todo' if no status label
        return 'todo';
    }

    getMockComponents(prefix) {
        if (prefix === 'B_') {
            return [
                {
                    id: 1, number: 334, componentId: 'B_S001', 
                    title: 'Cold Call to Placement',
                    status: 'todo', url: 'https://github.com/3Stones-io/bemeda_personal/issues/334', updated: '2024-01-15'
                },
                {
                    id: 2, number: 335, componentId: 'B_S001_US001', 
                    title: 'Organisation Receives Cold Call',
                    status: 'in-progress', url: 'https://github.com/3Stones-io/bemeda_personal/issues/335', updated: '2024-01-14'
                },
                {
                    id: 3, number: 336, componentId: 'B_S001_US001_USS001', 
                    title: 'Organisation Receives Cold Call Step',
                    status: 'todo', url: 'https://github.com/3Stones-io/bemeda_personal/issues/336', updated: '2024-01-13'
                },
                {
                    id: 4, number: 4, componentId: 'B_S001_US001_USS002', 
                    title: 'Listen to platform overview',
                    status: 'in-progress', url: '#', updated: '2024-01-12'
                }
            ];
        } else if (prefix === 'U_') {
            return [
                {
                    id: 5, number: 337, componentId: 'U_S001', 
                    title: 'Cold Call to Placement - UX Scenario',
                    status: 'todo', url: 'https://github.com/3Stones-io/bemeda_personal/issues/337', updated: '2024-01-15'
                },
                {
                    id: 6, number: 339, componentId: 'U_S001_M001', 
                    title: 'Healthcare Organisation Dashboard',
                    status: 'in-progress', url: 'https://github.com/3Stones-io/bemeda_personal/issues/339', updated: '2024-01-14'
                }
            ];
        } else if (prefix === 'T_') {
            return [
                {
                    id: 7, number: 341, componentId: 'T_S001', 
                    title: 'Technical Implementation for Cold Call to Placement',
                    status: 'in-progress', url: 'https://github.com/3Stones-io/bemeda_personal/issues/341', updated: '2024-01-15'
                },
                {
                    id: 8, number: 342, componentId: 'T_S001_UC001', 
                    title: 'User Authentication and Registration',
                    status: 'todo', url: 'https://github.com/3Stones-io/bemeda_personal/issues/342', updated: '2024-01-13'
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
        
        // Add data source indicator
        const dataSourceBadge = domain.dataSource === 'github' 
            ? '<span style="background: #28a745; color: white; padding: 2px 8px; border-radius: 4px; font-size: 0.7rem; margin-left: 8px;">Live GitHub Data</span>'
            : '<span style="background: #ffc107; color: #000; padding: 2px 8px; border-radius: 4px; font-size: 0.7rem; margin-left: 8px;">Mock Data</span>';
        
        // Update section header with data source
        const sectionHeader = document.querySelector(`#${domainKey}-kanban .section-title`);
        if (sectionHeader && !sectionHeader.querySelector('span[style*="background"]')) {
            sectionHeader.insertAdjacentHTML('beforeend', dataSourceBadge);
        }
        
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
                                <a href="${component.url}" target="_blank" class="compact-card ${domainKey}" style="text-decoration: none; color: inherit; display: block;">
                                    <div class="card-id">${component.componentId}</div>
                                    <div class="card-title">${component.title}</div>
                                </a>
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