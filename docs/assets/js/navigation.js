/**
 * Dynamic Navigation System
 * Loads navigation from metadata and renders consistent navigation across all pages
 */
class NavigationManager {
    constructor() {
        this.navigationData = null;
        this.currentPath = window.location.pathname;
        this.basePath = this.getBasePath();
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
     * Load navigation metadata
     */
    async loadNavigation() {
        try {
            const response = await fetch(`${this.basePath}metadata/navigation.json`);
            const data = await response.json();
            this.navigationData = data.navigation;
            return this.navigationData;
        } catch (error) {
            console.warn('Could not load navigation metadata, using fallback');
            return this.getFallbackNavigation();
        }
    }

    /**
     * Fallback navigation if metadata fails to load
     */
    getFallbackNavigation() {
        return {
            main: [
                { id: "home", label: "🏠 Home", path: "index.html" },
                { id: "scenarios", label: "📋 Scenarios", path: "scenarios/index.html" },
                { id: "ux-ui", label: "🎨 UX/UI", path: "ux-ui/index.html" },
                { id: "technical", label: "⚙️ Technical", path: "technical/index.html" },
                { id: "testing", label: "🧪 Testing", path: "testing/index.html" },
                { id: "unified-view", label: "📊 Unified View", path: "unified-view/index.html" },
                { id: "registry", label: "🔍 Registry", path: "registry/index.html" }
            ]
        };
    }

    /**
     * Determine which navigation item should be active
     */
    getActiveNavItem() {
        const currentPath = window.location.pathname.toLowerCase();
        
        if (currentPath.includes('/scenarios/')) return 'scenarios';
        if (currentPath.includes('/ux-ui/')) return 'ux-ui';
        if (currentPath.includes('/technical/')) return 'technical';
        if (currentPath.includes('/testing/')) return 'testing';
        if (currentPath.includes('/unified-view/')) return 'unified-view';
        if (currentPath.includes('/registry/')) return 'registry';
        if (currentPath.includes('/index.html') || currentPath.endsWith('/docs/')) return 'home';
        
        return null;
    }

    /**
     * Render navigation HTML
     */
    renderNavigation(containerId = 'navigation-container') {
        if (!this.navigationData) return;

        const container = document.getElementById(containerId);
        if (!container) return;

        const activeItem = this.getActiveNavItem();
        
        const navigationHTML = `
            <nav class="top-nav">
                <ul class="nav-list">
                    ${this.navigationData.main.map(item => `
                        <li class="nav-item">
                            <a href="${this.basePath}${item.path}" 
                               class="nav-link ${activeItem === item.id ? 'active' : ''}"
                               title="${item.description || ''}">
                                ${item.label}
                            </a>
                        </li>
                    `).join('')}
                </ul>
            </nav>
        `;

        container.innerHTML = navigationHTML;
    }

    /**
     * Initialize navigation system
     */
    async init() {
        await this.loadNavigation();
        this.renderNavigation();
        
        // Add navigation update event listener
        document.addEventListener('DOMContentLoaded', () => {
            this.renderNavigation();
        });
    }

    /**
     * Update navigation metadata (for future admin functionality)
     */
    async updateNavigation(newNavigationData) {
        try {
            // This would be a POST request to update the navigation
            // For now, just update locally
            this.navigationData = newNavigationData;
            this.renderNavigation();
            return true;
        } catch (error) {
            console.error('Failed to update navigation:', error);
            return false;
        }
    }
}

// Global navigation instance
window.NavigationManager = new NavigationManager();

// Auto-initialize if DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.NavigationManager.init();
    });
} else {
    window.NavigationManager.init();
}