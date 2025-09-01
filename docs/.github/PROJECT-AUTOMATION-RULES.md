# 🤖 Project Automation Rules for BDD Scenarios

## Overview
Configure intelligent automation rules that make your BDD scenario management self-managing and responsive to changes.

---

## 🚨 **Priority 1: Critical Failure Detection**

### **Rule**: Critical BDD Failure Alert
```yaml
Trigger: 
  Field Changed: "BDD Status" → "🔴 Critical Failures"
  AND Priority Level: "🔴 Critical - Must Have"

Actions:
  - Add label: "urgent-attention"
  - Move to: "🚨 Needs Immediate Attention" column  
  - Assign to: @dev-team-lead
  - Add comment: "🚨 Critical BDD scenario failing - immediate attention required"
  - Set status: "Blocked"
```

**Use Case**: Automatically escalate when critical business scenarios have failing tests

---

## ✅ **Priority 2: Completion Automation**  

### **Rule**: Auto-Complete on Full Validation
```yaml
Trigger:
  BDD Status: "🟢 All Tests Passing"
  AND Test Coverage: >= 85
  AND All checkboxes: checked

Actions:
  - Set Execution Status: "Completed"
  - Move to: "✅ Done" column
  - Add label: "validated"
  - Add comment: "🎉 Scenario fully validated and completed!"
  - Close issue (if configured)
```

**Use Case**: Automatically mark scenarios as done when all criteria met

---

## 🔄 **Priority 3: Parallel Scenario Sync**

### **Rule**: Parallel Scenario Status Sync
```yaml  
Trigger:
  Issue updated with parallel scenario references
  
Actions:
  - Parse parallel scenario IDs from issue body
  - Check status of referenced scenarios
  - Update comment with parallel scenario health:
    "🔗 Parallel Scenarios: T_S001 ✅ | U_S001 🟡"
  - If all parallel scenarios complete: Move to "Ready for Integration Testing"
```

**Use Case**: Keep parallel B_S/T_S/U_S scenarios synchronized

---

## 🏷️ **Priority 4: Smart Labeling**

### **Rule**: Auto-Label by Actor Type
```yaml
Trigger:
  Issue created or edited
  Contains actor mentions in body

Actions:
  - Scan issue body for actor patterns:
    - "Healthcare Organisation" → add "actor:healthcare-org"  
    - "Auth System" → add "actor:auth-system"
    - "Mobile User" → add "actor:mobile-user"
  - Set Scenario Type based on actor patterns:
    - Human actors → "B_S (Business)"
    - System actors → "T_S (Technical)"
    - Interface actors → "U_S (UX/UI)"
```

**Use Case**: Automatically categorize scenarios based on actor involvement

---

## ⚠️ **Priority 5: Risk Escalation**

### **Rule**: High Risk + No Activity Alert
```yaml
Trigger:
  Risk Assessment: "🔴 Critical Risk" OR "🟠 High Risk"
  AND No activity for: 48 hours
  AND Status: NOT "Completed"

Actions:  
  - Add to project: "Executive Review"
  - Assign: @project-manager  
  - Add comment: "⚠️ High-risk scenario requires attention - no activity in 48h"
  - Send notification to: project-stakeholders channel
```

**Use Case**: Prevent high-risk scenarios from stalling

---

## 🧪 **Priority 6: Test Coverage Monitoring**

### **Rule**: Low Test Coverage Warning  
```yaml
Trigger:
  Test Coverage: < 70%
  AND BDD Status: NOT "📝 Gherkin Only"
  AND Age: > 7 days

Actions:
  - Add label: "needs-testing"
  - Move to: "🧪 Testing Required" column
  - Add comment: "📊 Test coverage below 70% - please add more automated tests"
  - Assign: @qa-team
```

**Use Case**: Ensure scenarios maintain adequate test coverage

---

## 📊 **Priority 7: Inheritance Tracking**

### **Rule**: Parent Scenario Change Notification
```yaml
Trigger:
  Scenario with inheritance_percentage > 0
  Parent scenario status changes

Actions:
  - Find all child scenarios (inherit from this one)
  - Add comment to each: "👨‍👩‍👧‍👦 Parent scenario [PARENT_ID] status changed to [STATUS]"  
  - If parent completed: Add label "ready-for-inheritance-update"
  - If parent failed: Add label "inheritance-blocked"
```

**Use Case**: Keep inherited scenarios in sync with their parents

---

## 🎯 **Priority 8: Business Value Prioritization**

### **Rule**: Must-Have Scenario Prioritization
```yaml
Trigger:
  Business Value: "Must Have"
  AND Status: "Ready to Execute"

Actions:
  - Set Priority Level: "🔴 Critical - Must Have" (if not already set)
  - Move to: "🎯 High Priority" column
  - Add to milestone: "Current Sprint"
  - Add comment: "🎯 Must-have scenario ready for implementation"
```

**Use Case**: Automatically prioritize critical business scenarios

---

## 📈 **Priority 9: Progress Tracking**

### **Rule**: Stalled Scenario Detection
```yaml
Trigger:  
  Status: "In Progress"
  AND No checkbox checked in: 72 hours
  AND No comments in: 48 hours

Actions:
  - Add label: "stalled"
  - Add comment: "⏰ This scenario appears stalled - please provide status update"
  - Move to: "🚧 Needs Attention" column
  - Notify assignee
```

**Use Case**: Identify scenarios that need intervention

---

## 🔄 **Priority 10: Automated Validation**

### **Rule**: Gherkin Validation on Update
```yaml
Trigger:
  Issue body edited
  Contains "### Scenario:" section

Actions:
  - Validate Gherkin syntax (via GitHub Action)
  - Update BDD Status based on validation results:
    - Valid + checkboxes: "📝 Gherkin Only"  
    - Invalid syntax: Add label "validation-failed"
  - Add validation comment with results
```

**Use Case**: Ensure scenario quality through automated validation

---

## 📋 **Setup Instructions**

### **Step 1: Access Project Automation**
1. Go to your GitHub Project: https://github.com/orgs/3Stones-io/projects/12
2. Click **Settings** (gear icon)  
3. Select **Automation** from sidebar
4. Click **Add automation**

### **Step 2: Configure Each Rule**
For each priority rule above:
1. **Set Trigger**: Configure the conditions that activate the rule
2. **Define Actions**: Set what happens when triggered
3. **Test Rule**: Create a test scenario to verify it works
4. **Monitor**: Check automation logs for proper execution

### **Step 3: Advanced Configuration**

#### **Custom Field Automation**
```javascript
// Example: Custom field update via GitHub API
if (issue.custom_fields.bdd_status === "🟢 All Tests Passing" && 
    issue.custom_fields.test_coverage >= 85) {
    updateCustomField(issue.id, "execution_status", "Completed");
}
```

#### **Webhook Integration**  
```yaml
# Add webhook for external tool integration
webhook_url: "https://your-automation-service.com/github-webhook"
events: ["issues.updated", "issue_comment.created"]
```

---

## 📊 **Automation Metrics**

Track these metrics to optimize your automation:

### **Effectiveness Metrics**
- **Scenarios auto-completed**: How many scenarios are automatically moved to "Done"
- **Critical failures detected**: Response time to critical scenario failures  
- **False positives**: Automation rules triggered incorrectly
- **Manual overrides**: How often humans override automation decisions

### **Performance Metrics**  
- **Rule execution time**: How quickly automation rules respond
- **System load**: Impact of automation on GitHub performance
- **Error rate**: Percentage of automation rules that fail to execute

### **Business Impact**
- **Time saved**: Hours saved through automation vs manual management
- **Quality improvement**: Reduction in scenarios with missing tests
- **Risk mitigation**: Earlier detection of high-risk stalled scenarios

---

## 🚀 **Advanced Automation Patterns**

### **Conditional Cascading**
```yaml
Rule 1: When parent scenario completes
  → Trigger Rule 2: Check if all siblings complete
    → Trigger Rule 3: Mark epic as ready for release
```

### **Multi-Field Logic**
```yaml
Complex Condition:
  (Priority: Critical AND Risk: High) 
  OR (Business Value: Must Have AND Days Stalled: > 3)
  OR (Actor: Healthcare Org AND BDD Status: Critical Failures)
```

### **Time-Based Actions**
```yaml
Schedule: Every Monday 9 AM
Action: Generate weekly BDD health report
Recipients: project-managers, qa-leads
```

---

## ⚡ **Quick Start Checklist**

- [ ] **Enable GitHub Project automation** in project settings
- [ ] **Implement Priority 1-3 rules** (critical failure detection, completion, sync)
- [ ] **Test automation** with a sample scenario
- [ ] **Configure team notifications** for automated actions
- [ ] **Set up monitoring dashboard** for automation metrics
- [ ] **Train team** on automation behavior and override procedures
- [ ] **Iterate and optimize** based on team feedback

---

## 💡 **Best Practices**

### **Start Simple**
- Begin with 3-5 basic rules
- Add complexity gradually as team adapts
- Monitor automation logs regularly

### **Avoid Over-Automation**  
- Keep human oversight for critical decisions
- Allow easy override of automated actions
- Balance automation with team autonomy

### **Maintain Flexibility**
- Make rules easy to modify as processes evolve
- Use feature flags for experimental automation  
- Regularly review and prune unused rules

### **Communication**
- Document all automation rules clearly
- Notify team of automation changes
- Provide easy way to understand why automation acted

---

**Next**: Your automation rules will make scenario management largely self-managing, allowing teams to focus on implementation rather than project administration!