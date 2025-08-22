#!/bin/bash

# GitHub Project Setup Commands for Bemeda Platform
# Run this script after authenticating with: gh auth login

echo "🚀 Setting up Bemeda Platform GitHub Project..."

# Check authentication first
echo "🔐 Checking GitHub CLI authentication..."
if ! gh auth status &>/dev/null; then
    echo "❌ GitHub CLI not authenticated. Please run: gh auth login"
    exit 1
fi
echo "✅ GitHub CLI authenticated successfully"

# 1. Create the project
echo "📋 Creating GitHub Project..."
gh project create "Bemeda Platform" --owner @me

# Get the project URL (will be needed for field creation)
echo "🔍 Finding project details..."
PROJECT_URL=$(gh project list --owner @me --format json | jq -r '.projects[] | select(.title=="Bemeda Platform") | .url')
echo "✅ Project created at: $PROJECT_URL"

# 2. Add custom fields
echo "📊 Adding custom fields..."

# Extract project number from URL for field creation
PROJECT_NUMBER=$(echo $PROJECT_URL | grep -o 'projects/[0-9]*' | cut -d'/' -f2)
echo "📋 Project number: $PROJECT_NUMBER"

# Add Component Type field with correct syntax
echo "🏷️ Adding Component Type field..."
gh project field-create $PROJECT_NUMBER --name "Component Type" --data-type SINGLE_SELECT \
  --single-select-options "User Story,Feature,Technical Spec,API Endpoint,UX/UI Design,Testing,Bug Report"

# Add Domain field
echo "🏷️ Adding Domain field..."
gh project field-create $PROJECT_NUMBER --name "Domain" --data-type SINGLE_SELECT \
  --single-select-options "Scenarios,Technical,UX/UI,Testing,Platform Infrastructure"

# Add Sprint field
echo "🏷️ Adding Sprint field..."
gh project field-create $PROJECT_NUMBER --name "Sprint" --data-type TEXT

echo "✅ Custom fields created!"

# 3. Create initial project views
echo "📈 Setting up project views..."
echo "ℹ️  You'll need to manually create Board, Table, and Roadmap views in the GitHub UI"
echo "ℹ️  Project URL: $PROJECT_URL"

# 4. Setup repository automation (requires manual configuration in GitHub UI)
echo "🤖 Setting up automation..."
echo "ℹ️  To auto-assign issues to project:"
echo "   1. Go to your repository settings"
echo "   2. Navigate to 'Actions' → 'General'"
echo "   3. Add a workflow to auto-add issues with 'platform' label to project"

echo ""
echo "🎉 Setup complete! Next steps:"
echo "   • Visit project: $PROJECT_URL"
echo "   • Create Board, Table, and Roadmap views"
echo "   • Configure repository automation rules"
echo "   • Start creating platform issues!"