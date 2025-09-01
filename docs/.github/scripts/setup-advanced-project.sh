#!/bin/bash

# 🚀 Advanced GitHub Project Setup for BDD + Actor Scenarios
# This script sets up custom fields and project views for our world-class system

set -e

# Configuration
PROJECT_ID="PVT_kwHOCsIgJ84ABADG"  # Replace with your project ID  
ORG="3Stones-io"
REPO="bemeda_personal"

echo "🚀 Setting up Advanced GitHub Project for BDD + Actor Scenarios..."

# Check if gh CLI is authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ Please authenticate with GitHub CLI first: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI authenticated"

# Function to create custom field
create_custom_field() {
    local field_name="$1"
    local field_type="$2"
    local options="$3"
    
    echo "📋 Creating custom field: $field_name ($field_type)"
    
    case $field_type in
        "single_select")
            gh api graphql -f query='
                mutation($projectId: ID!, $name: String!, $options: [ProjectV2SingleSelectFieldOptionInput!]!) {
                  createProjectV2Field(input: {
                    projectId: $projectId
                    dataType: SINGLE_SELECT
                    name: $name
                    singleSelectOptions: $options
                  }) {
                    projectV2Field {
                      id
                      name
                    }
                  }
                }' -f projectId="$PROJECT_ID" -f name="$field_name" -f options="$options"
            ;;
        "number")
            gh api graphql -f query='
                mutation($projectId: ID!, $name: String!) {
                  createProjectV2Field(input: {
                    projectId: $projectId
                    dataType: NUMBER
                    name: $name
                  }) {
                    projectV2Field {
                      id
                      name  
                    }
                  }
                }' -f projectId="$PROJECT_ID" -f name="$field_name"
            ;;
    esac
}

# Create Scenario Type field
echo "📋 Creating Scenario Type field..."
create_custom_field "Scenario Type" "single_select" '[
    {name: "B_S (Business)", description: "Business scenarios with human actors"},
    {name: "T_S (Technical)", description: "Technical scenarios with system actors"}, 
    {name: "U_S (UX/UI)", description: "UX scenarios with interface actors"},
    {name: "T_F (Foundational)", description: "Platform-wide technical components"}
]'

# Create BDD Status field
echo "🧪 Creating BDD Status field..."
create_custom_field "BDD Status" "single_select" '[
    {name: "🟢 All Tests Passing", description: "All BDD tests are green"},
    {name: "🟡 Some Tests Failing", description: "Some tests need attention"},
    {name: "🔴 Critical Failures", description: "Major test failures blocking progress"},
    {name: "⚫ Not Yet Automated", description: "Tests not yet written or automated"},
    {name: "📝 Gherkin Only", description: "Scenario written but not automated"}
]'

# Create Actor Complexity field
echo "🎭 Creating Actor Complexity field..."
create_custom_field "Actor Complexity" "single_select" '[
    {name: "Single Actor", description: "One primary actor"},
    {name: "Multi-Actor", description: "Multiple coordinated actors"},
    {name: "Cross-System", description: "Actors spanning multiple systems"}
]'

# Create Priority Level field
echo "🎯 Creating Priority Level field..."
create_custom_field "Priority Level" "single_select" '[
    {name: "🔴 Critical - Must Have", description: "Critical business functionality"},
    {name: "🟠 High - Should Have", description: "Important for user experience"},
    {name: "🟡 Medium - Could Have", description: "Nice to have features"},
    {name: "⚪ Low - Won't Have", description: "Out of scope for this release"}
]'

# Create Risk Assessment field  
echo "⚠️ Creating Risk Assessment field..."
create_custom_field "Risk Assessment" "single_select" '[
    {name: "🟢 Low Risk", description: "Well understood, standard implementation"},
    {name: "🟡 Medium Risk", description: "Some unknowns, moderate complexity"},
    {name: "🟠 High Risk", description: "Significant unknowns, high complexity"},
    {name: "🔴 Critical Risk", description: "Major unknowns, potential blockers"}
]'

# Create Inheritance Percentage field
echo "📊 Creating Inheritance Percentage field..."
create_custom_field "Inheritance Percentage" "number"

# Create Test Coverage field
echo "📈 Creating Test Coverage field..."
create_custom_field "Test Coverage %" "number"

# Create Business Value field
echo "💰 Creating Business Value field..."
create_custom_field "Business Value" "single_select" '[
    {name: "Must Have", description: "Core business requirement"},
    {name: "Should Have", description: "Important for success"},
    {name: "Could Have", description: "Enhances experience"},
    {name: "Won't Have", description: "Out of scope"}
]'

# Create Execution Status field
echo "🎬 Creating Execution Status field..."
create_custom_field "Execution Status" "single_select" '[
    {name: "Ready to Execute", description: "All prerequisites met"},
    {name: "In Progress", description: "Currently being executed"},
    {name: "Blocked", description: "Waiting for dependencies"},
    {name: "Completed", description: "All acceptance criteria met"},
    {name: "Failed", description: "Execution failed, needs attention"}
]'

echo ""
echo "🎉 Advanced GitHub Project setup completed!"
echo ""
echo "📋 Custom Fields Created:"
echo "   • Scenario Type (B_S, T_S, U_S, T_F)"
echo "   • BDD Status (Tests Passing/Failing/Not Automated)" 
echo "   • Actor Complexity (Single/Multi/Cross-System)"
echo "   • Priority Level (Critical/High/Medium/Low)"
echo "   • Risk Assessment (Low/Medium/High/Critical)"
echo "   • Inheritance Percentage (0-100%)"
echo "   • Test Coverage % (0-100%)"
echo "   • Business Value (Must/Should/Could/Won't Have)"
echo "   • Execution Status (Ready/In Progress/Blocked/Completed/Failed)"
echo ""
echo "🔗 Next Steps:"
echo "   1. Visit your project: https://github.com/orgs/$ORG/projects/12"
echo "   2. Configure project views using the new custom fields"
echo "   3. Set up automation rules based on field values"
echo "   4. Create your first BDD scenario issue using the new template"
echo ""
echo "💡 Pro Tip: Use filters like 'BDD Status:🔴 Critical Failures' + 'Priority Level:🔴 Critical'"
echo "   to quickly identify scenarios that need immediate attention!"