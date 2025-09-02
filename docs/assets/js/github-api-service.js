/**
 * GitHub API Service for Dynamic Content Loading
 * Handles authentication, issue fetching, and real-time synchronization
 */

class GitHubAPIService {
    constructor(config = {}) {
        this.baseURL = 'https://api.github.com';
        this.owner = config.owner || '3Stones-io';
        this.repo = config.repo || 'bemeda_personal';
        this.token = config.token || null; // Will try to get from localStorage or prompt user
        this.cache = new Map();
        this.cacheExpiry = 5 * 60 * 1000; // 5 minutes
    }

    /**
     * Initialize the service with authentication
     */
    async initialize() {
        try {
            // Try to get token from localStorage first
            this.token = localStorage.getItem('github_token');
            
            if (!this.token) {
                console.log('GitHub API: No token found, using public access (rate limited)');
                // Public API access - limited but works for basic functionality
                return { authenticated: false, rateLimited: true };
            }

            // Test the token
            const response = await this.makeRequest('/user');
            if (response.ok) {
                console.log('GitHub API: Authenticated successfully');
                return { authenticated: true, user: await response.json() };
            } else {
                console.warn('GitHub API: Invalid token, falling back to public access');
                this.token = null;
                return { authenticated: false, rateLimited: true };
            }
        } catch (error) {
            console.error('GitHub API initialization error:', error);
            return { authenticated: false, error: error.message };
        }
    }

    /**
     * Make authenticated request to GitHub API
     */
    async makeRequest(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const headers = {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'BemedaPlatform-Documentation',
            ...options.headers
        };

        if (this.token) {
            headers.Authorization = `token ${this.token}`;
        }

        return fetch(url, {
            ...options,
            headers
        });
    }

    /**
     * Get cached data or fetch from API
     */
    async getCachedData(cacheKey, fetchFunction) {
        const cached = this.cache.get(cacheKey);
        if (cached && Date.now() - cached.timestamp < this.cacheExpiry) {
            return cached.data;
        }

        try {
            const data = await fetchFunction();
            this.cache.set(cacheKey, {
                data,
                timestamp: Date.now()
            });
            return data;
        } catch (error) {
            // Return cached data if available, even if expired
            if (cached) {
                console.warn('Using expired cache due to API error:', error);
                return cached.data;
            }
            throw error;
        }
    }

    /**
     * Find issues by step ID (S1, S5, S9, etc.)
     */
    async findStepIssue(stepId) {
        const cacheKey = `step-${stepId}`;
        return this.getCachedData(cacheKey, async () => {
            // Search for issues with step label and title containing stepId
            const searchQuery = `repo:${this.owner}/${this.repo} is:issue label:step:${stepId} in:title`;
            const response = await this.makeRequest(`/search/issues?q=${encodeURIComponent(searchQuery)}&sort=updated&order=desc`);
            
            if (!response.ok) {
                throw new Error(`API request failed: ${response.status}`);
            }

            const data = await response.json();
            
            // If no results with exact label, try searching by title
            if (data.total_count === 0) {
                const titleSearchQuery = `repo:${this.owner}/${this.repo} is:issue "${stepId}:" in:title`;
                const titleResponse = await this.makeRequest(`/search/issues?q=${encodeURIComponent(titleSearchQuery)}&sort=updated&order=desc`);
                
                if (titleResponse.ok) {
                    const titleData = await titleResponse.json();
                    return titleData.items.length > 0 ? titleData.items[0] : null;
                }
            }
            
            return data.items.length > 0 ? data.items[0] : null;
        });
    }

    /**
     * Get issue comments
     */
    async getIssueComments(issueNumber) {
        const cacheKey = `comments-${issueNumber}`;
        return this.getCachedData(cacheKey, async () => {
            const response = await this.makeRequest(`/repos/${this.owner}/${this.repo}/issues/${issueNumber}/comments`);
            
            if (!response.ok) {
                throw new Error(`Failed to fetch comments: ${response.status}`);
            }

            return response.json();
        });
    }

    /**
     * Get cross-referenced issues from issue body
     */
    async getCrossReferencedIssues(issueBody) {
        const cacheKey = `cross-refs-${btoa(issueBody).slice(0, 16)}`;
        return this.getCachedData(cacheKey, async () => {
            // Extract issue numbers from #123 pattern
            const issueNumbers = [...issueBody.matchAll(/#(\d+)/g)].map(match => match[1]);
            
            if (issueNumbers.length === 0) {
                return [];
            }

            // Fetch referenced issues
            const referencedIssues = [];
            for (const issueNumber of issueNumbers.slice(0, 10)) { // Limit to first 10 references
                try {
                    const response = await this.makeRequest(`/repos/${this.owner}/${this.repo}/issues/${issueNumber}`);
                    if (response.ok) {
                        referencedIssues.push(await response.json());
                    }
                } catch (error) {
                    console.warn(`Failed to fetch issue #${issueNumber}:`, error);
                }
            }

            return referencedIssues;
        });
    }

    /**
     * Get comprehensive step data (issue + comments + cross-references)
     */
    async getStepData(stepId) {
        try {
            console.log(`Fetching data for step: ${stepId}`);
            
            // Get main step issue
            const issue = await this.findStepIssue(stepId);
            if (!issue) {
                return {
                    error: 'Issue not found',
                    stepId,
                    message: `No GitHub issue found for step ${stepId}. This might be a placeholder step.`
                };
            }

            // Get comments and cross-references in parallel
            const [comments, crossRefs] = await Promise.all([
                this.getIssueComments(issue.number).catch(() => []),
                this.getCrossReferencedIssues(issue.body || '').catch(() => [])
            ]);

            return {
                stepId,
                issue,
                comments,
                crossReferences: crossRefs,
                lastUpdated: new Date().toISOString()
            };
        } catch (error) {
            console.error(`Error fetching step data for ${stepId}:`, error);
            return {
                error: error.message,
                stepId,
                message: 'Failed to load GitHub data. Please check your connection and try again.'
            };
        }
    }

    /**
     * Set GitHub token for authenticated requests
     */
    setToken(token) {
        this.token = token;
        localStorage.setItem('github_token', token);
    }

    /**
     * Clear authentication
     */
    clearAuth() {
        this.token = null;
        localStorage.removeItem('github_token');
    }

    /**
     * Get API rate limit status
     */
    async getRateLimit() {
        try {
            const response = await this.makeRequest('/rate_limit');
            if (response.ok) {
                return response.json();
            }
        } catch (error) {
            console.error('Failed to check rate limit:', error);
        }
        return null;
    }
}

// Create global instance
window.githubAPI = new GitHubAPIService();

// Auto-initialize when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.githubAPI.initialize();
    });
} else {
    window.githubAPI.initialize();
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GitHubAPIService;
}