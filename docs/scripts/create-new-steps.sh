#!/bin/bash

echo "📋 Creating New Scenario Steps"
echo "=============================="

# Create new S6: Get proposals per email
echo "Creating S6: Get proposals per email..."
gh issue create --repo 3Stones-io/bemeda_personal \
  --title "S6: Get proposals per email" \
  --label "step,domain:scenarios,scenario:1,status:todo,priority:medium" \
  --body "## Step ID
S6

## Actor
Organisation

## Description
Healthcare organisation receives tailored staffing proposals via email based on their expressed needs and requirements.

## Acceptance Criteria
- [ ] Proposals match discussed requirements
- [ ] Clear pricing and terms included
- [ ] Multiple options presented
- [ ] Next steps clearly outlined

---
*Created as part of scenario restructuring.*"

# Create S21: Confirm Decision Email
echo "Creating S21: Confirm Decision Email..."
gh issue create --repo 3Stones-io/bemeda_personal \
  --title "S21: Confirm Decision Email" \
  --label "step,domain:scenarios,scenario:1,status:todo,priority:medium" \
  --body "## Step ID
S21

## Actor
Organisation

## Description
Healthcare organisation sends confirmation email regarding their hiring decision and selected candidates.

## Acceptance Criteria
- [ ] Decision clearly communicated
- [ ] Selected candidates identified
- [ ] Terms and conditions confirmed
- [ ] Start dates established

---
*Created as part of scenario restructuring.*"

# Create S22: Receive a Bill
echo "Creating S22: Receive a Bill..."
gh issue create --repo 3Stones-io/bemeda_personal \
  --title "S22: Receive a Bill" \
  --label "step,domain:scenarios,scenario:1,status:todo,priority:medium" \
  --body "## Step ID
S22

## Actor
Organisation

## Description
Healthcare organisation receives billing for successful placement services.

## Acceptance Criteria
- [ ] Invoice details match agreement
- [ ] Services clearly itemized
- [ ] Payment terms specified
- [ ] Contact for billing questions included

---
*Created as part of scenario restructuring.*"

echo ""
echo "✅ New steps created!"
echo ""
echo "Next: Need to renumber existing S6-S19 to S7-S20 in GitHub"