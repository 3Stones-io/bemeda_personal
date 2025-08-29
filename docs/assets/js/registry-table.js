/**
 * Component Registry Table - Filtering and GitHub Integration
 * Handles table functionality, search, and live data synchronization
 */

class RegistryTable {
    constructor() {
        this.config = {
            owner: '3Stones-io',
            repo: 'bemeda_personal',
            baseApiUrl: 'https://api.github.com'
        };
        
        this.components = [];
        this.filteredComponents = [];
        this.isLoading = false;
        
        this.initializeElements();
        this.attachEventListeners();
        this.loadComponents();
    }

    initializeElements() {
        this.tableBody = document.getElementById('table-body');
        this.resultsCount = document.getElementById('results-count');
        this.searchInput = document.getElementById('search-input');
        this.domainFilter = document.getElementById('domain-filter');
        this.statusFilter = document.getElementById('status-filter');
        this.typeFilter = document.getElementById('type-filter');
    }

    attachEventListeners() {
        // Search input with debounce
        let searchTimeout;
        this.searchInput?.addEventListener('input', (e) => {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(() => {
                this.applyFilters();
            }, 300);
        });

        // Filter dropdowns
        this.domainFilter?.addEventListener('change', () => this.applyFilters());
        this.statusFilter?.addEventListener('change', () => this.applyFilters());
        this.typeFilter?.addEventListener('change', () => this.applyFilters());
    }

    async loadComponents() {
        if (this.isLoading) return;
        
        this.isLoading = true;
        this.showLoadingState();

        try {
            const query = `repo:${this.config.owner}/${this.config.repo} is:issue label:component`;
            const response = await fetch(
                `${this.config.baseApiUrl}/search/issues?q=${encodeURIComponent(query)}&per_page=100`,
                {
                    headers: {
                        'Accept': 'application/vnd.github.v3+json'
                    }
                }
            );

            if (!response.ok) {
                throw new Error(`GitHub API failed: ${response.status}`);
            }

            const data = await response.json();
            
            if (data.items && data.items.length > 0) {
                this.components = data.items
                    .map(issue => this.parseIssue(issue))
                    .sort((a, b) => a.componentId.localeCompare(b.componentId));
            } else {
                // Use mock data for demonstration
                this.components = this.getMockComponents();
            }
            
            this.filteredComponents = [...this.components];
            this.renderTable();
            this.updateResultsCount();
            
            // Update comparison view if function exists
            if (typeof window.updateComparisonData === 'function') {
                window.updateComparisonData(this.components);
            }
            
        } catch (error) {
            console.warn('Failed to fetch from GitHub, using mock data:', error);
            this.components = this.getMockComponents();
            this.filteredComponents = [...this.components];
            this.renderTable();
            this.updateResultsCount();
            
            // Update comparison view with mock data if function exists
            if (typeof window.updateComparisonData === 'function') {
                window.updateComparisonData(this.components);
            }
        }

        this.isLoading = false;
    }

    parseIssue(issue) {
        // Extract component ID from title
        const componentMatch = issue.title.match(/^([A-Z]_[A-Z_]+\d+):\s*(.+)/) || 
                              issue.title.match(/^([A-Z]+\d{3})[-:\s]*(.+)/);
        
        const componentId = componentMatch ? componentMatch[1] : 
                           issue.title.split(':')[0] || 
                           issue.title.split(' ')[0] || 
                           'UNKNOWN';
        
        const componentTitle = componentMatch ? componentMatch[2] : issue.title;
        
        return {
            id: issue.id,
            number: issue.number,
            componentId: componentId.trim(),
            title: componentTitle.trim(),
            description: this.extractDescription(issue.body),
            status: this.getStatusFromLabels(issue.labels),
            domain: this.getDomainFromId(componentId),
            type: this.getTypeFromId(componentId),
            url: issue.html_url,
            updated: new Date(issue.updated_at),
            created: new Date(issue.created_at),
            state: issue.state,
            labels: issue.labels.map(l => l.name)
        };
    }

    extractDescription(body) {
        if (!body) return '';
        
        // Try to extract description after "### Description"
        const descMatch = body.match(/### Description\s*\n(.*?)(?=\n###|$)/s);
        if (descMatch) {
            return descMatch[1].trim().substring(0, 120) + '...';
        }
        
        // Fallback to first line
        const firstLine = body.split('\n')[0];
        return firstLine.substring(0, 120) + (firstLine.length > 120 ? '...' : '');
    }

    getStatusFromLabels(labels) {
        const statusLabel = labels.find(l => l.name.startsWith('status:'));
        if (statusLabel) {
            const status = statusLabel.name.replace('status:', '');
            return status.replace('-', ' ').toLowerCase();
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
        const typeMap = {
            'B_S': 'Scenario',
            'B_US': 'User Story', 
            'B_USS': 'Story Step',
            'U_M': 'Mockup',
            'U_UX': 'User Flow',
            'U_C': 'UI Component',
            'T_UC': 'Use Case',
            'T_F': 'Feature',
            'T_TC': 'Tech Component',
            'T_T': 'Test Case'
        };

        for (const [prefix, type] of Object.entries(typeMap)) {
            if (componentId.startsWith(prefix)) {
                return type;
            }
        }
        return 'Component';
    }

    getMockComponents() {
        return [
            {
                id: 1, number: 1, componentId: 'B_S001',
                title: 'Cold Call to Candidate Placement',
                description: 'Complete recruitment workflow from initial sales contact through candidate placement',
                status: 'in-progress', domain: 'business', type: 'Scenario',
                url: 'https://github.com/3Stones-io/bemeda_personal/issues/1',
                updated: new Date('2024-01-15'), created: new Date('2024-01-10')
            },
            {
                id: 2, number: 2, componentId: 'B_US001',
                title: 'Organisation Receives Cold Call',
                description: 'Healthcare organisation receives initial contact from Bemeda sales representative',
                status: 'in-progress', domain: 'business', type: 'User Story',
                url: 'https://github.com/3Stones-io/bemeda_personal/issues/2',
                updated: new Date('2024-01-14'), created: new Date('2024-01-10')
            },
            {
                id: 3, number: 3, componentId: 'U_M001',
                title: 'Healthcare Organisation Dashboard',
                description: 'Main dashboard interface for healthcare organisations with job postings overview',
                status: 'todo', domain: 'ux', type: 'Mockup',
                url: 'https://github.com/3Stones-io/bemeda_personal/issues/3',
                updated: new Date('2024-01-13'), created: new Date('2024-01-10')
            },
            {
                id: 4, number: 4, componentId: 'T_UC001',
                title: 'User Authentication System',
                description: 'Complete authentication system with role-based access control for all user types',
                status: 'done', domain: 'technical', type: 'Use Case',
                url: 'https://github.com/3Stones-io/bemeda_personal/issues/4',
                updated: new Date('2024-01-12'), created: new Date('2024-01-10')
            },
            {
                id: 5, number: 5, componentId: 'B_US002',
                title: 'Discuss Staffing Needs',
                description: 'Healthcare organisation discusses specific staffing requirements with Bemeda representative',
                status: 'todo', domain: 'business', type: 'User Story',
                url: 'https://github.com/3Stones-io/bemeda_personal/issues/5',
                updated: new Date('2024-01-11'), created: new Date('2024-01-10')
            },
            {
                id: 6, number: 6, componentId: 'U_C001',
                title: 'Job Posting Form',
                description: 'Interactive form component for creating and editing job postings',
                status: 'in-progress', domain: 'ux', type: 'UI Component',
                url: 'https://github.com/3Stones-io/bemeda_personal/issues/6',
                updated: new Date('2024-01-16'), created: new Date('2024-01-12')
            }
        ];
    }

    applyFilters() {
        const searchTerm = this.searchInput?.value.toLowerCase() || '';
        const domainFilter = this.domainFilter?.value || '';
        const statusFilter = this.statusFilter?.value || '';
        const typeFilter = this.typeFilter?.value || '';

        this.filteredComponents = this.components.filter(component => {
            // Search filter
            const matchesSearch = !searchTerm || 
                component.componentId.toLowerCase().includes(searchTerm) ||
                component.title.toLowerCase().includes(searchTerm) ||
                component.description.toLowerCase().includes(searchTerm);

            // Domain filter
            const matchesDomain = !domainFilter || component.domain === domainFilter;

            // Status filter
            const matchesStatus = !statusFilter || component.status === statusFilter;

            // Type filter  
            const matchesType = !typeFilter || component.type === typeFilter;

            return matchesSearch && matchesDomain && matchesStatus && matchesType;
        });

        this.renderTable();
        this.updateResultsCount();
    }

    renderTable() {
        if (!this.tableBody) return;

        if (this.filteredComponents.length === 0) {
            this.tableBody.innerHTML = `
                <tr>
                    <td colspan="7" class="empty-state">
                        ${this.components.length === 0 ? 
                          '🔄 Loading components...' : 
                          '🔍 No components match the current filters'}
                    </td>
                </tr>
            `;
            return;
        }

        const html = this.filteredComponents.map(component => `
            <tr data-component-id="${component.componentId}">
                <td>
                    <span class="table-id">${component.componentId}</span>
                </td>
                <td class="table-title">
                    <a href="${component.url}" target="_blank" class="table-link">
                        ${component.title}
                    </a>
                </td>
                <td>
                    <span class="table-domain ${component.domain}">
                        ${this.getDomainLabel(component.domain)}
                    </span>
                </td>
                <td class="table-type">${component.type}</td>
                <td>
                    <span class="table-status ${component.status.replace(' ', '-')}">
                        ${this.formatStatus(component.status)}
                    </span>
                </td>
                <td class="table-updated">${this.formatDate(component.updated)}</td>
                <td>
                    <a href="${component.url}" target="_blank" class="table-link">
                        GitHub →
                    </a>
                </td>
            </tr>
        `).join('');

        this.tableBody.innerHTML = html;
    }

    getDomainLabel(domain) {
        const labels = {
            'business': 'Business',
            'ux': 'UX/UI',
            'technical': 'Technical',
            'other': 'Other'
        };
        return labels[domain] || domain;
    }

    formatStatus(status) {
        const formatted = status.replace('-', ' ').toLowerCase();
        return formatted.charAt(0).toUpperCase() + formatted.slice(1);
    }

    formatDate(date) {
        const now = new Date();
        const diffTime = Math.abs(now - date);
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays === 0) return 'Today';
        if (diffDays === 1) return 'Yesterday';
        if (diffDays < 7) return `${diffDays}d ago`;
        if (diffDays < 30) return `${Math.floor(diffDays / 7)}w ago`;
        return date.toLocaleDateString();
    }

    updateResultsCount() {
        if (!this.resultsCount) return;
        
        const total = this.components.length;
        const filtered = this.filteredComponents.length;
        
        if (total === filtered) {
            this.resultsCount.textContent = `${total} components`;
        } else {
            this.resultsCount.textContent = `${filtered} of ${total} components`;
        }
    }

    showLoadingState() {
        if (this.tableBody) {
            this.tableBody.innerHTML = `
                <tr>
                    <td colspan="7" class="loading-state">
                        🔄 Loading components from GitHub...
                    </td>
                </tr>
            `;
        }
        
        if (this.resultsCount) {
            this.resultsCount.textContent = 'Loading...';
        }
    }

    // Public methods
    async refresh() {
        this.components = [];
        this.filteredComponents = [];
        await this.loadComponents();
    }

    clearFilters() {
        if (this.searchInput) this.searchInput.value = '';
        if (this.domainFilter) this.domainFilter.selectedIndex = 0;
        if (this.statusFilter) this.statusFilter.selectedIndex = 0;
        if (this.typeFilter) this.typeFilter.selectedIndex = 0;
        this.applyFilters();
    }
}

// Global functions for button interactions
function refreshRegistry() {
    if (window.registryTable) {
        window.registryTable.refresh();
    }
}

function clearFilters() {
    if (window.registryTable) {
        window.registryTable.clearFilters();
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.registryTable = new RegistryTable();
    
    // Auto-refresh every 5 minutes
    setInterval(() => {
        if (window.registryTable && !window.registryTable.isLoading) {
            window.registryTable.refresh();
        }
    }, 300000); // 5 minutes
});