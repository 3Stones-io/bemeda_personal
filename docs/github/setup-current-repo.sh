#!/bin/bash

# Bemeda Platform GitHub Integration Setup
# Current Repository + Prefix Approach

echo "🚀 Setting up Bemeda Platform GitHub Integration"
echo "Repository: spitexbemeda/Bemeda-Personal-Page"
echo "Strategy: Current repo + [PLATFORM] prefix"
echo

# Check if we're in the right directory
if [ ! -f ".github/ISSUE_TEMPLATE/platform-user-story.md" ]; then
    echo "❌ Please run this script from the repository root directory"
    exit 1
fi

echo "✅ Issue templates created:"
echo "   - User Story Template"
echo "   - Feature Template" 
echo "   - Technical Spec Template"
echo "   - API Template"
echo "   - Bug Report Template"
echo

echo "📋 Next Steps:"
echo

echo "1. 🏷️  Create GitHub Labels"
echo "   Visit: https://github.com/spitexbemeda/Bemeda-Personal-Page/labels"
echo "   Create these labels:"
echo "   - platform (color: #7057ff)"
echo "   - user-story (color: #4a148c)" 
echo "   - feature (color: #2e7d32)"
echo "   - technical (color: #1976d2)"
echo "   - api (color: #ff5722)"
echo "   - testing (color: #795548)"
echo "   - ux-ui (color: #9c27b0)"
echo "   - priority:high (color: #d73a49)"
echo "   - priority:medium (color: #fbca04)"
echo "   - priority:low (color: #0e8a16)"
echo "   - status:planning (color: #ffffff)"
echo "   - status:in-progress (color: #0052cc)"
echo "   - status:review (color: #5319e7)"
echo "   - status:completed (color: #28a745)"
echo "   - domain:scenarios (color: #4a148c)"
echo "   - domain:technical (color: #1976d2)"
echo "   - domain:ux-ui (color: #9c27b0)"
echo "   - domain:testing (color: #795548)"
echo

echo "2. 📊 Create Project Board"
echo "   Visit: https://github.com/spitexbemeda/Bemeda-Personal-Page/projects"
echo "   - Create new project: 'Bemeda Platform Development'"
echo "   - Add columns: Backlog, In Progress, Review, Done"
echo "   - Setup automation: auto-add issues with 'platform' label"
echo

echo "3. 🎫 Create Sample Issues"
echo "   Visit: https://github.com/spitexbemeda/Bemeda-Personal-Page/issues/new/choose"
echo "   Create issues for existing components:"
echo "   - [PLATFORM] US001: Organisation Posts Job and Manages Applications"
echo "   - [PLATFORM] US002: JobSeeker Applies for Job Position"
echo "   - [PLATFORM] US003: JobSeeker Discovers Platform Opportunity"
echo

echo "4. 🔧 Configure Webhook (Optional)"
echo "   For automated sync between GitHub and documentation:"
echo "   - Deploy webhook handler service"
echo "   - Configure webhook URL in repository settings"
echo "   - Add webhook secret to environment variables"
echo

echo "5. 🔑 Setup GitHub Token (Optional)"
echo "   For API integration:"
echo "   - Create personal access token with repo permissions"
echo "   - Add token to your environment or configuration"
echo "   - Enable automated issue creation and updates"
echo

echo "6. 👥 Add Team Members"
echo "   - Add collaborators to repository"
echo "   - Assign roles and permissions"
echo "   - Share workflow documentation"
echo

echo "🎯 Quick Test:"
echo "1. Create a test issue using the Platform User Story template"
echo "2. Apply the correct labels (platform, user-story, etc.)"
echo "3. Add to the project board"
echo "4. Verify the issue appears in platform-filtered searches"
echo

echo "📚 Useful GitHub Search Queries:"
echo "- All platform issues: label:platform"
echo "- User stories only: label:platform label:user-story"
echo "- High priority: label:platform label:priority:high"
echo "- In progress: label:platform label:status:in-progress"
echo "- By domain: label:platform label:domain:scenarios"
echo

echo "✨ Ready to Go!"
echo "The current repository + prefix approach is now configured."
echo "Visit the GitHub integration guide for detailed instructions:"
echo "https://spitexbemeda.github.io/Bemeda-Personal-Page/docs/github/"
echo
echo "Happy collaborating! 🚀"