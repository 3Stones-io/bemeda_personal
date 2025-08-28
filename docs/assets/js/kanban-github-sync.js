/**
 * Kanban Board with GitHub Project Sync
 * Provides drag-and-drop functionality with real-time GitHub updates
 */

class KanbanGitHubSync {
    constructor(config) {
        this.config = {
            containerId: config.containerId || 'kanban-board',
            githubToken: config.githubToken || localStorage.getItem('github_token'),
            owner: config.owner || '3Stones-io',
            repo: config.repo || 'bemeda_personal',
            projectNumber: config.projectNumber || 12,
            columns: config.columns || [
                { id: 'planning', title: 'Planning', githubField: 'Status', githubValue: 'Planning' },
                { id: 'in-progress', title: 'In Progress', githubField: 'Status', githubValue: 'In Progress' },
                { id: 'review', title: 'Review', githubField: 'Status', githubValue: 'Review' },
                { id: 'completed', title: 'Completed', githubField: 'Status', githubValue: 'Completed' }
            ],
            domain: config.domain || 'all', // 'business', 'ux', 'tech', 'testing', or 'all'
            readOnly: config.readOnly !== false // Default to read-only mode
        };
        
        this.components = [];
        this.draggedElement = null;
        this.projectId = null;
        this.fieldId = null;
        this.isAuthenticated = !!this.config.githubToken;
    }

    async init() {
        // Only fetch project info if authenticated (needed for edits)
        if (this.isAuthenticated) {
            await this.fetchProjectInfo();
        }
        await this.fetchComponents();
        this.render();
        if (!this.config.readOnly) {
            this.initDragDrop();
        }
        this.initCollapsibles();
        
        // Auto-refresh every 30 seconds
        setInterval(() => this.refresh(), 30000);
    }

    async fetchProjectInfo() {
        const query = `
            query($org: String!, $number: Int!) {
                organization(login: $org) {
                    projectV2(number: $number) {
                        id
                        field(name: "Status") {
                            ... on ProjectV2SingleSelectField {
                                id
                                options {
                                    id
                                    name
                                }
                            }
                        }
                    }
                }
            }
        `;

        const response = await this.graphQLRequest(query, {
            org: this.config.owner,
            number: this.config.projectNumber
        });

        this.projectId = response.data.organization.projectV2.id;
        this.fieldId = response.data.organization.projectV2.field.id;
        this.statusOptions = response.data.organization.projectV2.field.options;
    }

    async fetchComponents() {
        const domainFilter = this.config.domain !== 'all' 
            ? `label:"domain:${this.config.domain}"` 
            : '';
            
        const query = `
            repo:${this.config.owner}/${this.config.repo} 
            is:issue 
            label:component 
            ${domainFilter}
        `;

        const headers = {
            'Accept': 'application/vnd.github.v3+json'
        };
        
        // Only add auth header if token exists
        if (this.config.githubToken) {
            headers['Authorization'] = `token ${this.config.githubToken}`;
        }

        const response = await fetch(`https://api.github.com/search/issues?q=${encodeURIComponent(query)}&per_page=100`, {
            headers: headers
        });

        const data = await response.json();
        
        console.log('GitHub API Response:', data);
        console.log('Total issues found:', data.total_count);
        
        if (data.items.length === 0) {
            console.warn('No components found. Query was:', query);
            
            // Use mock data for demonstration
            this.components = this.getMockComponents();
            return;
        }
        
        this.components = data.items.map(issue => {
            // Extract component data from issue
            const componentMatch = issue.title.match(/^([A-Z]_[A-Z]+\d+):\s*(.+)/);
            const componentId = componentMatch ? componentMatch[1] : issue.title;
            const componentTitle = componentMatch ? componentMatch[2] : issue.title;
            
            // Parse dates from issue body if available
            const startDateMatch = issue.body?.match(/Start Date:\s*(\d{4}-\d{2}-\d{2})/);
            const endDateMatch = issue.body?.match(/End Date:\s*(\d{4}-\d{2}-\d{2})/);
            
            return {
                id: issue.id,
                nodeId: issue.node_id,
                number: issue.number,
                componentId: componentId,
                title: componentTitle,
                description: issue.body?.split('\n')[0] || '',
                status: this.getStatusFromLabels(issue.labels),
                labels: issue.labels,
                url: issue.html_url,
                assignees: issue.assignees,
                startDate: startDateMatch ? startDateMatch[1] : null,
                endDate: endDateMatch ? endDateMatch[1] : null,
                comments: issue.comments,
                updated: issue.updated_at
            };
        });
    }

    getStatusFromLabels(labels) {
        const statusLabel = labels.find(l => l.name.startsWith('status:'));
        if (statusLabel) {
            const status = statusLabel.name.replace('status:', '');
            return status.replace('-', ' ').toLowerCase();
        }
        return 'planning';
    }

    render() {
        const container = document.getElementById(this.config.containerId);
        container.innerHTML = `
            <div class="kanban-header">
                <h2>Component Status Board ${this.config.readOnly ? '(Read-Only)' : '(Edit Mode)'}</h2>
                <div class="kanban-controls">
                    ${!this.isAuthenticated ? `
                        <button onclick="kanban.enableEditMode()" class="auth-btn">
                            <span class="icon">🔓</span> Enable Edit Mode
                        </button>
                    ` : ''}
                    <button onclick="kanban.toggleView()" class="view-toggle">
                        <span class="icon">📊</span> Switch to Gantt View
                    </button>
                    <button onclick="kanban.refresh()" class="refresh-btn">
                        <span class="icon">🔄</span> Refresh
                    </button>
                </div>
            </div>
            <div class="kanban-columns">
                ${this.config.columns.map(column => `
                    <div class="kanban-column" data-column="${column.id}">
                        <div class="column-header">
                            <h3>${column.title}</h3>
                            <span class="count">${this.getComponentsByStatus(column.id).length}</span>
                        </div>
                        <div class="column-content" data-status="${column.id}">
                            ${this.renderCards(column.id)}
                        </div>
                    </div>
                `).join('')}
            </div>
            
            <!-- Scenario Flow View -->
            <div class="scenario-flow-section">
                <div class="flow-header">
                    <h2>Scenario Flow View</h2>
                    <p>Complete business logic flow - drag cards to kanban board above</p>
                </div>
                <div class="scenario-blocks">
                    ${this.renderScenarioBlocks()}
                </div>
            </div>
        `;
    }

    renderCards(status) {
        const components = this.getComponentsByStatus(status);
        return components.map(component => 
            this.renderCardContent(component)
        ).join('');
    }

    getDomainClass(component) {
        const domainLabel = component.labels.find(l => l.name.startsWith('domain:'));
        if (domainLabel) {
            return `domain-${domainLabel.name.replace('domain:', '')}`;
        }
        return '';
    }

    getComponentsByStatus(status) {
        return this.components.filter(c => c.status === status);
    }

    renderScenarioBlocks() {
        if (this.components.length === 0) {
            return `
                <div class="scenario-block">
                    <div style="text-align: center; padding: 40px; color: var(--color-text-secondary);">
                        <p>No components found. This could mean:</p>
                        <ul style="list-style: none; margin-top: 20px;">
                            <li>• No GitHub issues with "component" label exist yet</li>
                            <li>• Authentication may be needed for private repositories</li>
                            <li>• The domain filter may not match any components</li>
                        </ul>
                        <p style="margin-top: 20px;">Try creating a component using the Quick Actions below.</p>
                    </div>
                </div>
            `;
        }
        
        // Group components by scenario
        const scenarios = this.groupComponentsByScenario();
        
        if (Object.keys(scenarios).length === 0) {
            return `
                <div class="scenario-block">
                    <div style="text-align: center; padding: 40px; color: var(--color-text-secondary);">
                        <p>Components found but no valid scenarios detected.</p>
                    </div>
                </div>
            `;
        }
        
        return Object.entries(scenarios).map(([scenarioId, scenarioData]) => `
            <div class="scenario-block">
                <div class="scenario-header">
                    <h3>${scenarioId}: ${scenarioData.title || 'Scenario'}</h3>
                    <span class="scenario-count">${scenarioData.components.length} components</span>
                </div>
                <div class="scenario-flow">
                    ${this.renderScenarioFlow(scenarioData)}
                </div>
            </div>
        `).join('');
    }

    groupComponentsByScenario() {
        const scenarios = {};
        
        this.components.forEach(component => {
            // Extract scenario ID from component ID (e.g., B_S001 from B_US001)
            let scenarioId;
            if (component.componentId.startsWith('B_S')) {
                scenarioId = component.componentId;
            } else if (component.componentId.includes('US')) {
                // Extract scenario number from user story or step
                const match = component.componentId.match(/(\d+)/);
                if (match) {
                    scenarioId = `B_S${match[1].padStart(3, '0')}`;
                }
            }
            
            if (!scenarioId) return;
            
            if (!scenarios[scenarioId]) {
                scenarios[scenarioId] = {
                    title: '',
                    scenario: null,
                    userStories: [],
                    storySteps: [],
                    components: []
                };
            }
            
            scenarios[scenarioId].components.push(component);
            
            if (component.componentId.startsWith('B_S')) {
                scenarios[scenarioId].scenario = component;
                scenarios[scenarioId].title = component.title;
            } else if (component.componentId.startsWith('B_US')) {
                scenarios[scenarioId].userStories.push(component);
            } else if (component.componentId.startsWith('B_USS')) {
                scenarios[scenarioId].storySteps.push(component);
            }
        });
        
        return scenarios;
    }

    renderScenarioFlow(scenarioData) {
        const cards = [];
        
        // Add scenario card first
        if (scenarioData.scenario) {
            cards.push(this.renderFlowCard(scenarioData.scenario, 'scenario'));
        }
        
        // Sort and add user stories
        const sortedStories = scenarioData.userStories.sort((a, b) => 
            a.componentId.localeCompare(b.componentId)
        );
        
        sortedStories.forEach(story => {
            cards.push(this.renderFlowCard(story, 'story'));
            
            // Find and add related story steps
            const relatedSteps = scenarioData.storySteps
                .filter(step => {
                    const storyNum = story.componentId.match(/US(\d+)/)?.[1];
                    const stepNum = step.componentId.match(/USS(\d+)/)?.[1];
                    return stepNum && stepNum.startsWith(storyNum);
                })
                .sort((a, b) => a.componentId.localeCompare(b.componentId));
            
            relatedSteps.forEach(step => {
                cards.push(this.renderFlowCard(step, 'step'));
            });
        });
        
        return cards.join('');
    }

    renderFlowCard(component, type) {
        // Check if this component is already in the kanban (not in planning status)
        const isInKanban = component.status !== 'planning';
        const ghostClass = isInKanban ? 'ghost-card' : '';
        
        return `
            <div class="flow-card ${type}-card ${ghostClass} ${!this.config.readOnly ? 'draggable' : ''}" 
                 draggable="${!this.config.readOnly}"
                 data-component-id="${component.nodeId}"
                 data-issue-number="${component.number}"
                 data-flow-position="true">
                <div class="flow-card-id">${component.componentId}</div>
                <div class="flow-card-title">${component.title}</div>
                ${isInKanban ? '<div class="in-kanban-indicator">In Kanban</div>' : ''}
            </div>
        `;
    }

    initDragDrop() {
        const kanbanCards = document.querySelectorAll('.kanban-card');
        const flowCards = document.querySelectorAll('.flow-card.draggable');
        const columns = document.querySelectorAll('.column-content');

        // Handle kanban cards
        kanbanCards.forEach(card => {
            card.addEventListener('dragstart', (e) => this.handleDragStart(e));
            card.addEventListener('dragend', (e) => this.handleDragEnd(e));
        });

        // Handle flow cards
        flowCards.forEach(card => {
            card.addEventListener('dragstart', (e) => this.handleFlowDragStart(e));
            card.addEventListener('dragend', (e) => this.handleDragEnd(e));
        });

        columns.forEach(column => {
            column.addEventListener('dragover', (e) => this.handleDragOver(e));
            column.addEventListener('drop', (e) => this.handleDrop(e));
        });
    }

    handleDragStart(e) {
        if (this.config.readOnly) {
            e.preventDefault();
            return;
        }
        
        // Check authentication on drag start
        if (!this.isAuthenticated) {
            e.preventDefault();
            this.promptForToken();
            return;
        }
        
        this.draggedElement = e.target;
        e.target.classList.add('dragging');
    }

    handleDragEnd(e) {
        e.target.classList.remove('dragging');
    }

    handleFlowDragStart(e) {
        if (this.config.readOnly) {
            e.preventDefault();
            return;
        }
        
        // Check authentication on drag start
        if (!this.isAuthenticated) {
            e.preventDefault();
            this.promptForToken();
            return;
        }
        
        // Create a kanban card from the flow card data
        const componentId = e.target.dataset.componentId;
        const component = this.components.find(c => c.nodeId === componentId);
        
        if (component) {
            // Create a temporary kanban card element
            const tempCard = document.createElement('div');
            tempCard.className = `kanban-card ${this.getDomainClass(component)}`;
            tempCard.dataset.componentId = component.nodeId;
            tempCard.dataset.issueNumber = component.number;
            tempCard.innerHTML = this.renderCardContent(component);
            
            this.draggedElement = tempCard;
            this.draggedFromFlow = true;
            e.target.classList.add('dragging');
            
            // Store component data for creating the actual card on drop
            e.dataTransfer.setData('componentData', JSON.stringify(component));
        }
    }

    renderCardContent(component) {
        return `
            <div class="kanban-card ${this.getDomainClass(component)} ${this.config.readOnly ? 'read-only' : ''}" 
                 draggable="${!this.config.readOnly}" 
                 data-component-id="${component.nodeId}"
                 data-issue-number="${component.number}">
                <div class="card-header" onclick="kanban.toggleCard(this)">
                    <span class="component-id">${component.componentId}</span>
                    <span class="dropdown-arrow">▼</span>
                </div>
                <div class="card-title">${component.title}</div>
                <div class="card-details" style="display: none;">
                    <p class="card-description">${component.description}</p>
                    <div class="card-dates">
                        ${component.startDate ? `
                            <div class="date-field">
                                <label>Start:</label>
                                <input type="date" value="${component.startDate}" 
                                       onchange="kanban.updateDate('${component.nodeId}', 'start', this.value)">
                            </div>
                        ` : ''}
                        ${component.endDate ? `
                            <div class="date-field">
                                <label>End:</label>
                                <input type="date" value="${component.endDate}" 
                                       onchange="kanban.updateDate('${component.nodeId}', 'end', this.value)">
                            </div>
                        ` : ''}
                    </div>
                    <div class="card-meta">
                        ${component.assignees.length > 0 ? `
                            <div class="assignees">
                                ${component.assignees.map(a => `
                                    <img src="${a.avatar_url}" alt="${a.login}" title="${a.login}">
                                `).join('')}
                            </div>
                        ` : ''}
                        <div class="card-actions">
                            <a href="${component.url}" target="_blank" class="github-link">
                                View on GitHub →
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    handleDragOver(e) {
        e.preventDefault();
        const column = e.target.closest('.column-content');
        if (column) {
            column.classList.add('drag-over');
        }
    }

    async handleDrop(e) {
        e.preventDefault();
        const column = e.target.closest('.column-content');
        if (column) {
            column.classList.remove('drag-over');
            const newStatus = column.dataset.status;
            const componentId = this.draggedElement.dataset.componentId;
            const issueNumber = this.draggedElement.dataset.issueNumber;
            
            // If dragged from flow view, create a proper kanban card
            if (this.draggedFromFlow) {
                const componentData = e.dataTransfer.getData('componentData');
                if (componentData) {
                    const component = JSON.parse(componentData);
                    // Create actual kanban card
                    const newCard = document.createElement('div');
                    newCard.className = `kanban-card ${this.getDomainClass(component)}`;
                    newCard.dataset.componentId = component.nodeId;
                    newCard.dataset.issueNumber = component.number;
                    newCard.draggable = !this.config.readOnly;
                    newCard.innerHTML = this.renderCardContent(component);
                    
                    // Add event listeners
                    newCard.addEventListener('dragstart', (e) => this.handleDragStart(e));
                    newCard.addEventListener('dragend', (e) => this.handleDragEnd(e));
                    
                    column.appendChild(newCard);
                    this.draggedElement = newCard;
                    
                    // Update flow view to show ghost card
                    const flowCard = document.querySelector(`.flow-card[data-component-id="${component.nodeId}"]`);
                    if (flowCard) {
                        flowCard.classList.add('ghost-card');
                        flowCard.innerHTML += '<div class="in-kanban-indicator">In Kanban</div>';
                    }
                }
                this.draggedFromFlow = false;
            } else {
                // Normal kanban card move
                column.appendChild(this.draggedElement);
            }
            
            // Update GitHub
            await this.updateGitHubStatus(componentId, issueNumber, newStatus);
        }
    }

    async updateGitHubStatus(nodeId, issueNumber, newStatus) {
        try {
            // Find the status option ID
            const statusOption = this.statusOptions.find(
                opt => opt.name.toLowerCase() === newStatus.replace('-', ' ')
            );
            
            if (!statusOption) {
                throw new Error(`Status option not found: ${newStatus}`);
            }

            // Update project item field
            const mutation = `
                mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: ProjectV2FieldValue!) {
                    updateProjectV2ItemFieldValue(input: {
                        projectId: $projectId
                        itemId: $itemId
                        fieldId: $fieldId
                        value: $value
                    }) {
                        projectV2Item {
                            id
                        }
                    }
                }
            `;

            await this.graphQLRequest(mutation, {
                projectId: this.projectId,
                itemId: nodeId,
                fieldId: this.fieldId,
                value: { singleSelectOptionId: statusOption.id }
            });

            // Update issue labels
            const statusLabel = `status:${newStatus}`;
            await this.updateIssueLabels(issueNumber, statusLabel);
            
            this.showNotification('Status updated successfully', 'success');
        } catch (error) {
            console.error('Failed to update status:', error);
            this.showNotification('Failed to update status', 'error');
            // Revert UI change
            await this.refresh();
        }
    }

    async updateIssueLabels(issueNumber, newStatusLabel) {
        // Remove old status labels
        const labelsResponse = await fetch(
            `https://api.github.com/repos/${this.config.owner}/${this.config.repo}/issues/${issueNumber}/labels`,
            {
                headers: {
                    'Authorization': `token ${this.config.githubToken}`,
                    'Accept': 'application/vnd.github.v3+json'
                }
            }
        );
        
        const currentLabels = await labelsResponse.json();
        const nonStatusLabels = currentLabels
            .filter(l => !l.name.startsWith('status:'))
            .map(l => l.name);
        
        // Add new status label
        const newLabels = [...nonStatusLabels, newStatusLabel];
        
        await fetch(
            `https://api.github.com/repos/${this.config.owner}/${this.config.repo}/issues/${issueNumber}/labels`,
            {
                method: 'PUT',
                headers: {
                    'Authorization': `token ${this.config.githubToken}`,
                    'Accept': 'application/vnd.github.v3+json',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(newLabels)
            }
        );
    }

    async updateDate(nodeId, dateType, value) {
        if (!this.isAuthenticated) {
            this.promptForToken();
            return;
        }
        
        // This would update the issue body with new dates
        // Implementation depends on how dates are stored in your issues
        console.log(`Updating ${dateType} date to ${value} for ${nodeId}`);
        this.showNotification('Date update functionality coming soon', 'info');
    }

    toggleCard(header) {
        const card = header.parentElement;
        const details = card.querySelector('.card-details');
        const arrow = header.querySelector('.dropdown-arrow');
        
        if (details.style.display === 'none') {
            details.style.display = 'block';
            arrow.textContent = '▲';
            card.classList.add('expanded');
        } else {
            details.style.display = 'none';
            arrow.textContent = '▼';
            card.classList.remove('expanded');
        }
    }

    toggleView() {
        // Switch between Kanban and Gantt view
        console.log('Switching to Gantt view...');
        this.showNotification('Gantt view coming soon', 'info');
    }

    async refresh() {
        await this.fetchComponents();
        this.render();
        if (!this.config.readOnly) {
            this.initDragDrop();
        }
        this.initCollapsibles();
    }

    initCollapsibles() {
        // Re-attach event listeners for card headers after render
        const cardHeaders = document.querySelectorAll('.card-header');
        cardHeaders.forEach(header => {
            header.onclick = () => this.toggleCard(header);
        });
    }

    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.remove();
        }, 3000);
    }

    async graphQLRequest(query, variables) {
        const response = await fetch('https://api.github.com/graphql', {
            method: 'POST',
            headers: {
                'Authorization': `bearer ${this.config.githubToken}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ query, variables })
        });
        
        if (!response.ok) {
            throw new Error(`GraphQL request failed: ${response.statusText}`);
        }
        
        return response.json();
    }
    
    enableEditMode() {
        this.promptForToken();
    }
    
    promptForToken() {
        const token = prompt('Please enter your GitHub personal access token to enable editing:\n\nRequired scopes: repo, project');
        if (token) {
            localStorage.setItem('github_token', token);
            this.config.githubToken = token;
            this.isAuthenticated = true;
            this.config.readOnly = false;
            // Reload with edit capabilities
            this.init();
        }
    }
    
    getMockComponents() {
        // Mock data for demonstration
        return [
            {
                id: 1,
                nodeId: 'mock_1',
                number: 1,
                componentId: 'B_S001',
                title: 'Cold Call to Candidate Placement',
                description: 'Complete recruitment workflow from initial sales contact through candidate placement',
                status: 'planning',
                labels: [{ name: 'component' }, { name: 'domain:scenarios' }],
                url: '#',
                assignees: [],
                startDate: null,
                endDate: null,
                comments: 0,
                updated: new Date().toISOString()
            },
            {
                id: 2,
                nodeId: 'mock_2',
                number: 2,
                componentId: 'B_US001',
                title: 'Organisation Receives Cold Call',
                description: 'Healthcare organisation receives initial contact from Bemeda sales representative',
                status: 'in-progress',
                labels: [{ name: 'component' }, { name: 'domain:scenarios' }],
                url: '#',
                assignees: [],
                startDate: null,
                endDate: null,
                comments: 0,
                updated: new Date().toISOString()
            },
            {
                id: 3,
                nodeId: 'mock_3',
                number: 3,
                componentId: 'B_US002',
                title: 'Discuss Staffing Needs',
                description: 'Organisation discusses current staffing challenges and requirements',
                status: 'in-progress',
                labels: [{ name: 'component' }, { name: 'domain:scenarios' }],
                url: '#',
                assignees: [],
                startDate: null,
                endDate: null,
                comments: 0,
                updated: new Date().toISOString()
            },
            {
                id: 4,
                nodeId: 'mock_4',
                number: 4,
                componentId: 'B_USS001',
                title: 'Initial Phone Contact',
                description: 'Sales team makes first contact with healthcare facility',
                status: 'planning',
                labels: [{ name: 'component' }, { name: 'domain:scenarios' }],
                url: '#',
                assignees: [],
                startDate: null,
                endDate: null,
                comments: 0,
                updated: new Date().toISOString()
            },
            {
                id: 5,
                nodeId: 'mock_5',
                number: 5,
                componentId: 'B_USS002',
                title: 'Identify Decision Maker',
                description: 'Find the right person to discuss staffing needs',
                status: 'planning',
                labels: [{ name: 'component' }, { name: 'domain:scenarios' }],
                url: '#',
                assignees: [],
                startDate: null,
                endDate: null,
                comments: 0,
                updated: new Date().toISOString()
            },
            {
                id: 6,
                nodeId: 'mock_6',
                number: 6,
                componentId: 'B_US007',
                title: 'JobSeeker Creates Profile',
                description: 'Healthcare professional creates profile on platform',
                status: 'review',
                labels: [{ name: 'component' }, { name: 'domain:scenarios' }],
                url: '#',
                assignees: [],
                startDate: null,
                endDate: null,
                comments: 0,
                updated: new Date().toISOString()
            }
        ];
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('kanban-board')) {
        window.kanban = new KanbanGitHubSync({
            containerId: 'kanban-board',
            domain: document.body.dataset.domain || 'all'
        });
        window.kanban.init();
    }
});