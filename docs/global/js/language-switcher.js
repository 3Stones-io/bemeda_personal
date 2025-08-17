// Language Switcher Script
(function() {
    // Get current language from localStorage or default to 'en'
    let currentLang = localStorage.getItem('bemeda-lang') || 'en';
    
    // Language switcher component
    function createLanguageSwitcher() {
        const switcher = document.createElement('div');
        switcher.className = 'language-switcher';
        switcher.innerHTML = `
            <button class="lang-btn ${currentLang === 'en' ? 'active' : ''}" data-lang="en">EN</button>
            <button class="lang-btn ${currentLang === 'de' ? 'active' : ''}" data-lang="de">DE</button>
        `;
        return switcher;
    }
    
    // Add language switcher to all navigation bars (only if none exists)
    function addLanguageSwitchers() {
        // Check if language switcher already exists
        if (document.querySelector('.language-switcher-container')) {
            return; // Don't add if one already exists
        }
        
        const navBars = document.querySelectorAll('.top-nav .nav-list');
        navBars.forEach(nav => {
            const switcher = createLanguageSwitcher();
            nav.parentElement.appendChild(switcher);
        });
        
        // Add event listeners
        document.querySelectorAll('.lang-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                const newLang = this.getAttribute('data-lang');
                switchLanguage(newLang);
            });
        });
    }
    
    // Switch language function
    function switchLanguage(lang) {
        if (lang === currentLang) return;
        
        currentLang = lang;
        localStorage.setItem('bemeda-lang', lang);
        
        // Update active button
        document.querySelectorAll('.lang-btn').forEach(btn => {
            btn.classList.toggle('active', btn.getAttribute('data-lang') === lang);
        });
        
        // Get current page name
        const currentPage = window.location.pathname.split('/').pop() || 'index.html';
        
        // Redirect to appropriate language version
        if (lang === 'de') {
            // For German, redirect to de/ subdirectory
            if (!window.location.pathname.includes('/de/')) {
                // Check if German version exists before redirecting
                const germanPath = 'de/' + currentPage;
                fetch(germanPath, { method: 'HEAD' })
                    .then(response => {
                        if (response.ok) {
                            window.location.href = germanPath;
                        } else {
                            // German version doesn't exist, stay on current page
                            console.log('German version not available for:', currentPage);
                        }
                    })
                    .catch(() => {
                        // German version doesn't exist, stay on current page
                        console.log('German version not available for:', currentPage);
                    });
            }
        } else {
            // For English, redirect to root
            if (window.location.pathname.includes('/de/')) {
                window.location.href = '../' + currentPage;
            }
        }
    }
    
    // Apply translations for current page
    function applyTranslations() {
        document.querySelectorAll('[data-i18n]').forEach(element => {
            const key = element.getAttribute('data-i18n');
            const translation = translations[currentLang][key];
            if (translation) {
                element.textContent = translation;
            }
        });
    }
    
    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
    
    function init() {
        addLanguageSwitchers();
        applyTranslations();
    }
})();

// Common translations
const translations = {
    en: {
        'nav.index': 'Index',
        'nav.job': 'JOB',
        'nav.tmp': 'TMP',
        'nav.tmp-temporary': 'TMP-Temporary',
        'nav.tmp-tryhire': 'TMP & Hire',
        'nav.tmp-pool': 'TMP-Pool',
        'nav.table-view': 'Table View',
        'nav.team': 'Team',
        'nav.projects': 'Projects',
        'back.main': '← Back to Main Index',
        'back.job-vermittlung': '← Back to JOB-Vermittlung',
        'back.tmp-verleih': '← Back to TMP-Verleih'
    },
    de: {
        'nav.index': 'Startseite',
        'nav.job': 'JOB',
        'nav.tmp': 'TMP',
        'nav.tmp-temporary': 'TMP-Temporär',
        'nav.tmp-tryhire': 'TMP & Anstellung',
        'nav.tmp-pool': 'TMP-Pool',
        'nav.table-view': 'Tabellenansicht',
        'nav.team': 'Team',
        'nav.projects': 'Projekte',
        'back.main': '← Zurück zur Hauptseite',
        'back.job-vermittlung': '← Zurück zu JOB-Vermittlung',
        'back.tmp-verleih': '← Zurück zu TMP-Verleih'
    }
};