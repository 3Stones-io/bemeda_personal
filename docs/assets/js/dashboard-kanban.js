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
            business: { prefix: 'US', components: [], githubFilter: 'label%3A%22business%22+label%3A%22component%22' },
            ux: { prefix: 'UX', components: [], githubFilter: 'label%3A%22ux%22+label%3A%22component%22' },
            technical: { prefix: 'T_S', components: [], githubFilter: 'label%3A%22existing-component%22+OR+label%3A%22missing-component%22' }
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
        // Handle modern formats like "US001 - Organisation Receives Cold Call" or "T_S001_AUTH001 - Authentication System"
        const componentMatch = issue.title.match(/^([A-Z_]+\d+(?:_[A-Z_]+\d+)*)\s*[-:]\s*(.+)/);
        let componentId = componentMatch ? componentMatch[1] : issue.title.split(/[-:]/)[0] || issue.title;
        const componentTitle = componentMatch ? componentMatch[2] : issue.title;
        
        // Clean up component ID for consistency
        componentId = componentId.trim();
        
        return {
            id: issue.id,
            number: issue.number,
            componentId: componentId,
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
        if (prefix === 'US') {
            return [
                // No Status (4 items)
                {
                    id: 1, number: 334, componentId: 'B_S001', 
                    title: 'Cold Call to Placement - Epic',
                    status: 'todo', url: 'https://github.com/3Stones-io/bemeda_personal/issues/334', updated: '2024-01-15'
                },
                {
                    id: 2, number: 335, componentId: 'B_S001_US001', 
                    title: 'Organisation User Story',
                    status: 'todo', url: 'https://github.com/3Stones-io/bemeda_personal/issues/335', updated: '2024-01-14'
                },
                {
                    id: 3, number: 336, componentId: 'B_S001_US002', 
                    title: 'JobSeeker User Story',
                    status: 'todo', url: 'https://github.com/3Stones-io/bemeda_personal/issues/336', updated: '2024-01-13'
                },
                {
                    id: 4, number: 337, componentId: 'B_S001_US003', 
                    title: 'Sales Team User Story',
                    status: 'todo', url: 'https://github.com/3Stones-io/bemeda_personal/issues/337', updated: '2024-01-12'
                },
                // In Progress (1 item)
                {
                    id: 5, number: 338, componentId: 'US001', 
                    title: 'Organisation Receives Cold Call',
                    status: 'in-progress', url: 'https://github.com/3Stones-io/bemeda_personal/issues/338', updated: '2024-01-11'
                },
                // Done (5 items)
                {
                    id: 6, number: 339, componentId: 'STEP001', 
                    title: 'Listen to Platform Overview',
                    status: 'done', url: 'https://github.com/3Stones-io/bemeda_personal/issues/339', updated: '2024-01-10'
                },
                {
                    id: 7, number: 340, componentId: 'STEP002', 
                    title: 'Express Interest or Concerns',
                    status: 'done', url: 'https://github.com/3Stones-io/bemeda_personal/issues/340', updated: '2024-01-09'
                },
                {
                    id: 8, number: 341, componentId: 'STEP003', 
                    title: 'Discuss Specific Staffing Needs',
                    status: 'done', url: 'https://github.com/3Stones-io/bemeda_personal/issues/341', updated: '2024-01-08'
                }
            ];
        } else if (prefix === 'UX') {
            return [
                {
                    id: 9, number: 342, componentId: 'UX_JOURNEY001', 
                    title: 'JobSeeker Journey: Profile to Placement',
                    status: 'done', url: 'https://github.com/3Stones-io/bemeda_personal/issues/342', updated: '2024-01-07'
                },
                {
                    id: 10, number: 343, componentId: 'UX_JOURNEY002', 
                    title: 'Sales Team Journey: Lead to Placement Success',
                    status: 'done', url: 'https://github.com/3Stones-io/bemeda_personal/issues/343', updated: '2024-01-06'
                }
            ];
        } else if (prefix === 'T_S') {
            return [
                {
                    id: 11, number: 361, componentId: 'T_S001_AUTH001', 
                    title: 'Authentication System',
                    status: 'done', url: 'https://github.com/3Stones-io/bemeda_personal/issues/361', updated: '2024-01-15'
                },
                {
                    id: 12, number: 363, componentId: 'T_S003_JOBS001', 
                    title: 'Job Posting System',
                    status: 'done', url: 'https://github.com/3Stones-io/bemeda_personal/issues/363', updated: '2024-01-14'
                },
                {
                    id: 13, number: 367, componentId: 'T_S011_INTV001', 
                    title: 'Interview Scheduling System',
                    status: 'todo', url: 'https://github.com/3Stones-io/bemeda_personal/issues/367', updated: '2024-01-13'
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
                                <a href="https://github.com/orgs/3Stones-io/projects/12/views/2?filterQuery=label%3A%22domain%3A${domainKey === 'business' ? 'scenarios' : domainKey === 'ux' ? 'ux-ui' : 'technical'}%22+label%3A%22component%22" target="_blank">
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