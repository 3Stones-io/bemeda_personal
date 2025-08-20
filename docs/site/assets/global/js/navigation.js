// Shared Navigation Component for Bemeda Platform

class BemedaNavigation {
    constructor(options = {}) {
        this.currentPage = options.currentPage || '';
        this.isNarrow = options.isNarrow || false;
        this.init();
    }

    getNavigationHTML() {
        const navClass = this.isNarrow ? 'top-nav narrow' : 'top-nav';
        
        return `
            <nav class="${navClass}">
                <ul class="nav-list">
                    <li class="nav-item">
                        <a href="${this.getRelativePath()}index.html" class="nav-link ${this.currentPage === 'index' ? 'active' : ''}" data-i18n="nav.index">Index</a>
                    </li>
                    <li class="nav-item">
                        <a href="${this.getRelativePath()}job-vermittlung.html" class="nav-link ${this.currentPage === 'job' ? 'active' : ''}" data-i18n="nav.job">JOB</a>
                    </li>
                    <li class="nav-item dropdown">
                        <a href="${this.getRelativePath()}tmp-verleih.html" class="nav-link ${this.currentPage === 'tmp' ? 'active' : ''}" data-i18n="nav.tmp">TMP</a>
                        <div class="dropdown-content">
                            <a href="${this.getRelativePath()}tmp-temporary.html" data-i18n="nav.tmp-temporary">TMP-Temporary</a>
                            <a href="${this.getRelativePath()}tmp-tryhire.html" data-i18n="nav.tmp-tryhire">TMP & Hire</a>
                            <a href="${this.getRelativePath()}tmp-pool.html" data-i18n="nav.tmp-pool">TMP-Pool</a>
                        </div>
                    </li>
                    <li class="nav-item">
                        <a href="${this.getRelativePath()}scenarios-table.html" class="nav-link ${this.currentPage === 'table' ? 'active' : ''}" data-i18n="nav.table-view">Table View</a>
                    </li>
                    ${this.currentPage === 'team' || this.currentPage === 'projects' ? `
                    <li class="nav-item">
                        <a href="${this.getRelativePath()}team-dashboard.html" class="nav-link ${this.currentPage === 'team' ? 'active' : ''}" data-i18n="nav.team">Team</a>
                    </li>
                    <li class="nav-item">
                        <a href="${this.getRelativePath()}project-dashboard.html" class="nav-link ${this.currentPage === 'projects' ? 'active' : ''}" data-i18n="nav.projects">Projects</a>
                    </li>
                    ` : ''}
                </ul>
            </nav>
        `;
    }

    getLanguageSwitcherHTML() {
        return `
            <div class="language-switcher-container">
                <div class="language-switcher">
                    <button class="lang-btn active" data-lang="en">EN</button>
                    <button class="lang-btn" data-lang="de">DE</button>
                </div>
            </div>
        `;
    }

    getRelativePath() {
        // Determine if we're in a subdirectory
        const path = window.location.pathname;
        if (path.includes('/steps/') || path.includes('/de/')) {
            return '../';
        }
        return '';
    }

    getSharedCSS() {
        return `
            /* Shared Navigation Styles */
            .navigation-wrapper {
                margin-bottom: 20px;
            }
            
            .top-nav {
                background: white;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                padding: 0;
                border-radius: 8px;
                overflow: hidden;
            }
            
            .top-nav.narrow {
                max-width: 1200px;
                margin: 0 auto;
            }
            
            .nav-list {
                display: flex;
                list-style: none;
                margin: 0;
                padding: 0;
            }
            
            .nav-item {
                flex: 1;
            }
            
            .nav-link {
                display: block;
                padding: 16px 20px;
                text-decoration: none;
                color: #666;
                border-right: 1px solid #eee;
                text-align: center;
                transition: all 0.2s;
            }
            
            .nav-link:hover {
                background: #f8f9fa;
                color: #0066cc;
            }
            
            .nav-link.active {
                background: #0066cc;
                color: white;
            }
            
            .nav-item:last-child .nav-link {
                border-right: none;
            }
            
            /* Dropdown Styles */
            .dropdown {
                position: relative;
            }
            
            .dropdown-content {
                display: none;
                position: absolute;
                top: 100%;
                left: 0;
                right: 0;
                background: white;
                box-shadow: 0 4px 8px rgba(0,0,0,0.1);
                border-radius: 0 0 8px 8px;
                z-index: 1000;
            }
            
            .dropdown:hover .dropdown-content {
                display: block;
            }
            
            .dropdown-content a {
                display: block;
                padding: 12px 20px;
                text-decoration: none;
                color: #666;
                border-bottom: 1px solid #eee;
                transition: background 0.2s;
            }
            
            .dropdown-content a:last-child {
                border-bottom: none;
            }
            
            .dropdown-content a:hover {
                background: #f8f9fa;
                color: #0066cc;
            }
            
            /* Language Switcher Container */
            .language-switcher-container {
                background: #f8f9fa;
                padding: 8px 20px;
                border-bottom: 1px solid #eee;
                display: flex;
                justify-content: flex-end;
            }
            
            .language-switcher {
                display: flex;
                gap: 4px;
                background: rgba(255,255,255,0.8);
                padding: 4px;
                border-radius: 6px;
            }
            
            .lang-btn {
                background: white;
                border: 1px solid #ddd;
                color: #666;
                padding: 4px 12px;
                border-radius: 4px;
                cursor: pointer;
                font-size: 0.85rem;
                font-weight: 500;
                transition: all 0.2s;
                min-width: 40px;
            }
            
            .lang-btn:hover {
                background: #f0f0f0;
                color: #333;
                border-color: #999;
            }
            
            .lang-btn.active {
                background: #0066cc;
                color: white;
                border-color: #0066cc;
            }
            
            @media (max-width: 768px) {
                .language-switcher-container {
                    justify-content: center;
                }
                
                .nav-item {
                    flex: 1;
                    min-width: 0;
                }
                
                .nav-link {
                    padding: 12px 8px;
                    font-size: 0.9rem;
                }
            }
        `;
    }

    init() {
        // Add shared CSS to document head
        if (!document.getElementById('shared-navigation-styles')) {
            const style = document.createElement('style');
            style.id = 'shared-navigation-styles';
            style.textContent = this.getSharedCSS();
            document.head.appendChild(style);
        }
    }

    render(containerId) {
        const container = document.getElementById(containerId);
        if (container) {
            // Check if language switcher already exists on the page
            const existingLanguageSwitcher = document.querySelector('.language-switcher-container');
            const includeLanguageSwitcher = !existingLanguageSwitcher;
            
            container.innerHTML = `
                <div class="navigation-wrapper">
                    ${includeLanguageSwitcher ? this.getLanguageSwitcherHTML() : ''}
                    ${this.getNavigationHTML()}
                </div>
            `;
        }
    }
}

// Global function to initialize navigation
window.initBemedaNavigation = function(options = {}) {
    return new BemedaNavigation(options);
};