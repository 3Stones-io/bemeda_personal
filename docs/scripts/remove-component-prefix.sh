#!/bin/bash

# Script to remove [COMPONENT] prefix from all GitHub issue titles

echo "Removing [COMPONENT] prefix from GitHub issue titles..."

# Get all issues with [COMPONENT] prefix
gh issue list --repo 3Stones-io/bemeda_personal --label component --limit 100 --json number,title | \
jq -r '.[] | select(.title | startswith("[COMPONENT]")) | @base64' | \
while read -r encoded; do
    # Decode the base64 to handle special characters in titles
    decoded=$(echo "$encoded" | base64 --decode)
    number=$(echo "$decoded" | jq -r '.number')
    old_title=$(echo "$decoded" | jq -r '.title')
    
    # Remove [COMPONENT] prefix
    new_title=$(echo "$old_title" | sed 's/^\[COMPONENT\] //')
    
    echo "Updating issue #$number: $old_title -> $new_title"
    
    # Update the issue title
    gh issue edit "$number" --repo 3Stones-io/bemeda_personal --title "$new_title"
    
    # Small delay to avoid rate limiting
    sleep 0.5
done

echo "Done! All issue titles have been updated."