#!/bin/bash

# Quick script to create components that will be automatically added to the project

echo "🚀 Create Component for Bemeda Platform"
echo "======================================="
echo "Choose component type:"
echo "1) Scenario Step (S)"
echo "2) UX Component (U)"
echo "3) Technical Component (T)"
echo -n "Select (1-3): "
read -r choice

case $choice in
    1)
        echo "Creating Scenario Step..."
        gh issue create --repo 3Stones-io/bemeda_personal --template scenario-step.yml
        ;;
    2)
        echo "Creating UX Component..."
        gh issue create --repo 3Stones-io/bemeda_personal --template ux-component.yml
        ;;
    3)
        echo "Creating Technical Component..."
        gh issue create --repo 3Stones-io/bemeda_personal --template technical-component.yml
        ;;
    *)
        echo "Invalid selection"
        exit 1
        ;;
esac

echo ""
echo "✅ Issue created! It will be automatically added to the project."
echo "📊 View project: https://github.com/orgs/3Stones-io/projects/12"