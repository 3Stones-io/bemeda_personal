#!/bin/bash

# Script to close outdated issues and guide to new structure

echo "🧹 Cleaning up outdated issues..."
echo "================================"

# Message to add when closing
CLOSE_MESSAGE="This issue uses the old component structure (B_S001_US format). 

We've moved to a simplified structure:
- **Scenario Steps**: S1, S2, S3... (individual steps, not user stories)
- **UX Components**: U1, U2, U3... (UI components)
- **Technical Components**: T1, T2, T3... (APIs, services, etc.)

Please create new issues using the templates:
- 📋 Scenario Step: \`gh issue create --repo 3Stones-io/bemeda_personal --template scenario-step.yml\`
- 🎨 UX Component: \`gh issue create --repo 3Stones-io/bemeda_personal --template ux-component.yml\`
- ⚙️ Technical: \`gh issue create --repo 3Stones-io/bemeda_personal --template technical-component.yml\`

All new issues are automatically added to the project board: https://github.com/orgs/3Stones-io/projects/12"

# Close old B_S001 style issues
echo "Closing B_S001 style issues..."
for issue in 354 355 356 357 358 359; do
    echo "Closing issue #$issue..."
    gh issue close --repo 3Stones-io/bemeda_personal $issue --comment "$CLOSE_MESSAGE" --reason "not planned"
done

# Close old technical component issues with T_S0XX pattern
echo "Closing old technical component issues..."
for issue in 361 362 363 364 365 366 367 368 369; do
    echo "Closing issue #$issue..."
    gh issue close --repo 3Stones-io/bemeda_personal $issue --comment "$CLOSE_MESSAGE" --reason "not planned"
done

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Create new components using the simplified structure (S#, U#, T#)"
echo "2. Use the provided templates to ensure consistency"
echo "3. All new issues will be automatically added to the project"
echo ""
echo "Run './scripts/create-component.sh' to create new components easily!"