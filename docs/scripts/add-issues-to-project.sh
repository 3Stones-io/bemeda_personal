#!/bin/bash

# Add existing issues to Bemeda Platform Project
# Project URL: https://github.com/orgs/3Stones-io/projects/12

echo "Adding existing issues to Bemeda Platform Project..."

# Get the project ID
PROJECT_ID=$(gh api graphql -f query='
  query {
    organization(login: "3Stones-io") {
      projectV2(number: 12) {
        id
      }
    }
  }
' --jq '.data.organization.projectV2.id')

echo "Project ID: $PROJECT_ID"

# Function to add issue to project
add_issue_to_project() {
    local issue_id=$1
    local issue_node_id=$2
    
    echo "Adding issue #$issue_id to project..."
    
    gh api graphql -f query="
        mutation {
            addProjectV2ItemById(input: {
                projectId: \"$PROJECT_ID\"
                contentId: \"$issue_node_id\"
            }) {
                item {
                    id
                }
            }
        }
    "
}

# Get all issues with our labels
echo "Fetching issues with component labels..."

# Get issues with 'step' label
gh issue list --repo 3Stones-io/bemeda_personal --label "step" --json number,id,title --limit 100 | jq -r '.[] | "\(.number) \(.id) \(.title)"' | while read -r issue_num issue_id issue_title; do
    echo "Processing step issue #$issue_num: $issue_title"
    add_issue_to_project "$issue_num" "$issue_id"
done

# Get issues with 'component:ux' label
gh issue list --repo 3Stones-io/bemeda_personal --label "component:ux" --json number,id,title --limit 100 | jq -r '.[] | "\(.number) \(.id) \(.title)"' | while read -r issue_num issue_id issue_title; do
    echo "Processing UX issue #$issue_num: $issue_title"
    add_issue_to_project "$issue_num" "$issue_id"
done

# Get issues with 'component:tech' label
gh issue list --repo 3Stones-io/bemeda_personal --label "component:tech" --json number,id,title --limit 100 | jq -r '.[] | "\(.number) \(.id) \(.title)"' | while read -r issue_num issue_id issue_title; do
    echo "Processing tech issue #$issue_num: $issue_title"
    add_issue_to_project "$issue_num" "$issue_id"
done

# Also check for issues that might have the old labels
echo "Checking for issues with legacy labels..."

# Old 'ux' label
gh issue list --repo 3Stones-io/bemeda_personal --label "ux" --json number,id,title --limit 100 | jq -r '.[] | "\(.number) \(.id) \(.title)"' | while read -r issue_num issue_id issue_title; do
    echo "Processing UX issue (old label) #$issue_num: $issue_title"
    add_issue_to_project "$issue_num" "$issue_id"
done

# Old 'technical' label
gh issue list --repo 3Stones-io/bemeda_personal --label "technical" --json number,id,title --limit 100 | jq -r '.[] | "\(.number) \(.id) \(.title)"' | while read -r issue_num issue_id issue_title; do
    echo "Processing tech issue (old label) #$issue_num: $issue_title"
    add_issue_to_project "$issue_num" "$issue_id"
done

echo "Done! Check your project at: https://github.com/orgs/3Stones-io/projects/12"