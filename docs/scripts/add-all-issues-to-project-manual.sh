#!/bin/bash

# Manual script to add all S/U/T issues to Bemeda Platform project
# Run this script from the command line after making it executable:
# chmod +x add-all-issues-to-project-manual.sh
# ./add-all-issues-to-project-manual.sh

echo "📊 Adding all issues to Bemeda Platform project"
echo "=============================================="
echo ""

# Function to add issue with error handling
add_issue() {
    local issue_num=$1
    local description=$2
    echo -n "Adding #$issue_num ($description)... "
    
    if gh project item-add 12 --owner 3Stones-io --url "https://github.com/3Stones-io/bemeda_personal/issues/$issue_num" 2>/dev/null; then
        echo "✅ Added"
    else
        echo "⚠️  Already in project or error"
    fi
}

echo "🔧 Technical Components:"
echo "------------------------"
add_issue 373 "T1: Contact Capture API"
add_issue 401 "T2: Platform data API"
add_issue 402 "T3: Interest tracking system"
add_issue 403 "T4: Questions API endpoint"
add_issue 404 "T5: Demo provisioning service"
add_issue 405 "T6: Analytics service"
add_issue 406 "T7: Candidate matching engine"
add_issue 407 "T8: Interview scheduling system"
add_issue 408 "T10: Profile creation service"
add_issue 409 "T11: Job notification engine"
add_issue 410 "T13: Application submission system"

echo ""
echo "📋 Scenario Steps:"
echo "------------------"
add_issue 371 "S1: Receive Bemeda sales call"
add_issue 377 "S2: Listen to platform overview"
add_issue 378 "S9: Create professional profile"
add_issue 376 "S8: Make hiring decision"
add_issue 383 "S3: Discuss staffing needs"
add_issue 384 "S4: Define job requirements"
add_issue 385 "S5: Publish job posting"
add_issue 386 "S6: Review matched candidates"
add_issue 387 "S7: Conduct interviews"
add_issue 388 "S10: Receive job notification"
add_issue 389 "S11: Review job details"
add_issue 390 "S12: Submit application"
add_issue 391 "S13: Participate in interview"
add_issue 392 "S17: Present platform benefits"
add_issue 393 "S18: Facilitate onboarding"
add_issue 394 "S19: Monitor placement success"
add_issue 398 "S14: Accept offer & onboard"
add_issue 399 "S15: Identify target healthcare organisations"
add_issue 400 "S16: Make initial contact"

echo ""
echo "🎨 UX Components:"
echo "-----------------"
add_issue 372 "U1: Call Reception Dashboard"
add_issue 374 "U25: Form Fields Component"

echo ""
echo "✅ Process complete!"
echo ""
echo "📊 View the project at:"
echo "https://github.com/orgs/3Stones-io/projects/12"
echo ""
echo "Note: Issues marked as 'Already in project' were previously added."