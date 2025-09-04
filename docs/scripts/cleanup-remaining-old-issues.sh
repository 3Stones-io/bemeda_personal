#!/bin/bash

# Close the TEST_PLATFORM epic
echo "Closing TEST_PLATFORM epic..."
gh issue close --repo 3Stones-io/bemeda_personal 360 --comment "This issue uses the old epic structure. Testing should be integrated into each component (S#, U#, T#) using our simplified structure." --reason "not planned"

# Close the overview issue
echo "Closing OVERVIEW issue..."
gh issue close --repo 3Stones-io/bemeda_personal 370 --comment "This overview is now outdated. Please refer to the streamlined component structure and project board: https://github.com/orgs/3Stones-io/projects/12" --reason "completed"

# Update labels on existing valid issues
echo "Updating labels on valid S/U/T issues..."

# S1 - already has good labels
echo "S1 (#371) already properly labeled"

# S2
echo "Updating S2 (#377)..."
gh issue edit 377 --repo 3Stones-io/bemeda_personal --add-label "step,domain:scenarios,scenario:1,actor:A1"

# S8
echo "Updating S8 (#376)..."
gh issue edit 376 --repo 3Stones-io/bemeda_personal --add-label "step,domain:scenarios,scenario:1,actor:A1"

# S9
echo "Updating S9 (#378)..."
gh issue edit 378 --repo 3Stones-io/bemeda_personal --add-label "step,domain:scenarios,scenario:1,actor:A2"

# Update U1 labels
echo "Updating U1 (#372)..."
gh issue edit 372 --repo 3Stones-io/bemeda_personal --add-label "domain:ux-ui,supports:S1" --remove-label "step:S1"

# Update T1 labels
echo "Updating T1 (#373)..."
gh issue edit 373 --repo 3Stones-io/bemeda_personal --add-label "domain:technical,supports:S1" --remove-label "step:S1"

# Update U25 labels
echo "Updating U25 (#374)..."
gh issue edit 374 --repo 3Stones-io/bemeda_personal --add-label "domain:ux-ui,supports:S1,S5,S9" --remove-label "step:S1+S5+S9"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📊 Remaining valid issues have been properly labeled"
echo "🔗 View in project: https://github.com/orgs/3Stones-io/projects/12"