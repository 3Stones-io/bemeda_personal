#!/bin/bash

echo "📋 Creating Missing Scenario Steps"
echo "=================================="

# Define all scenario steps with their descriptions and actors
declare -A STEPS=(
    # Already exist: S1, S2, S8, S9
    ["S3"]="Discuss staffing needs|Organisation"
    ["S4"]="Define job requirements|Organisation"
    ["S5"]="Publish job posting|Organisation"
    ["S6"]="Review matched candidates|Organisation"
    ["S7"]="Conduct interviews|Organisation"
    # S8 exists
    # S9 exists
    ["S10"]="Receive job notification|JobSeeker"
    ["S11"]="Review job details|JobSeeker"
    ["S12"]="Submit application|JobSeeker"
    ["S13"]="Participate in interview|JobSeeker"
    ["S14"]="Accept offer & onboard|JobSeeker"
    ["S15"]="Identify target healthcare organisations|Sales Team"
    ["S16"]="Make initial contact|Sales Team"
    ["S17"]="Present platform benefits|Sales Team"
    ["S18"]="Facilitate onboarding|Sales Team"
    ["S19"]="Monitor placement success|Sales Team"
)

# Check which steps already exist
echo "Checking existing steps..."
EXISTING_STEPS=$(gh issue list --repo 3Stones-io/bemeda_personal --search "in:title S1 S2 S3 S4 S5 S6 S7 S8 S9 S10 S11 S12 S13 S14 S15 S16 S17 S18 S19" --json title | jq -r '.[].title' | grep -oE 'S[0-9]+' | sort -u)

echo "Existing steps: $EXISTING_STEPS"
echo ""

# Create missing steps
for step in S3 S4 S5 S6 S7 S10 S11 S12 S13 S14 S15 S16 S17 S18 S19; do
    if echo "$EXISTING_STEPS" | grep -q "^$step$"; then
        echo "✓ $step already exists, skipping..."
    else
        IFS='|' read -r title actor <<< "${STEPS[$step]}"
        echo "Creating $step: $title ($actor)..."
        
        # Create the issue using GitHub CLI with the template
        gh issue create \
            --repo 3Stones-io/bemeda_personal \
            --title "$step: $title" \
            --label "step,domain:scenarios,scenario:1,status:todo,priority:medium" \
            --body "## Step ID
$step

## Actor
$actor

## Description
This step needs to be defined in detail.

## Acceptance Criteria
- [ ] Define detailed requirements
- [ ] Create UX components
- [ ] Implement technical components
- [ ] Test integration

---
*Created automatically. Please update with detailed information.*"
        
        sleep 2  # Avoid rate limiting
    fi
done

echo ""
echo "✅ All scenario steps created!"
echo ""
echo "📊 View in GitHub Project: https://github.com/orgs/3Stones-io/projects/12"
echo ""
echo "Next steps:"
echo "1. Review each step issue and add detailed descriptions"
echo "2. Create UX components (U#) for the user interfaces needed"
echo "3. Create Technical components (T#) for the backend services"
echo "4. Use './scripts/create-component.sh' for guided component creation"