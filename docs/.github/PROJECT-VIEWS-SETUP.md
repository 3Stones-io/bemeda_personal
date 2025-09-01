# 📊 Actor-Based Project Views Setup Guide

## Overview
This guide walks you through setting up advanced project views that leverage our custom fields for powerful actor-based filtering and management.

---

## 🎯 **View 1: Business Actor Journey**
**Purpose**: Track scenarios from the perspective of human stakeholders

### Setup Instructions:
1. **Go to Project**: https://github.com/orgs/3Stones-io/projects/12
2. **Create New View**: Click "New view" → "Table"
3. **Name**: "🏢 Business Actor Journey"
4. **Configure Filters**:
   ```
   Type: is "B_S (Business)"
   Status: is not "Closed"
   ```
5. **Group By**: `Priority Level`
6. **Sort By**: `Updated` (newest first)
7. **Visible Fields**:
   - Title
   - Scenario Type
   - BDD Status  
   - Priority Level
   - Risk Assessment
   - Assignees
   - Labels (showing actor labels)

### Use Cases:
- 👥 **Product Owners**: See all business scenarios and their validation status
- 🎯 **Project Managers**: Prioritize scenarios based on business value
- 📞 **Sales Team**: Track scenarios involving their workflows

---

## ⚙️ **View 2: Technical Component Map** 
**Purpose**: Visualize system actor interactions and dependencies

### Setup Instructions:
1. **Create New View**: Board view
2. **Name**: "⚙️ Technical Component Map"
3. **Configure Filters**:
   ```
   Type: is "T_S (Technical)" OR "T_F (Foundational)"
   ```
4. **Group By**: `Actor Complexity`
5. **Board Columns**:
   - Single Actor (Green)
   - Multi-Actor (Yellow) 
   - Cross-System (Red)
6. **Card Fields**:
   - BDD Status
   - Test Coverage %
   - Risk Assessment
   - Linked scenarios

### Use Cases:
- 👨‍💻 **Developers**: Understand component dependencies
- 🏗️ **Architects**: Visualize system complexity
- 🧪 **QA Engineers**: Focus testing on high-risk components

---

## 🎨 **View 3: UX Flow Tracker**
**Purpose**: Monitor user experience scenarios and interface testing

### Setup Instructions:  
1. **Create New View**: Roadmap view
2. **Name**: "🎨 UX Flow Tracker"
3. **Configure Filters**:
   ```
   Type: is "U_S (UX/UI)"
   ```
4. **Group By**: `BDD Status`
5. **Timeline Fields**:
   - Start Date: Created date
   - End Date: Target date (if available)
6. **Roadmap Tracks**: Group by device type (extract from labels)

### Use Cases:
- 🎨 **UX Designers**: Track design implementation progress
- 📱 **Mobile Team**: Focus on mobile-specific scenarios  
- ♿ **Accessibility Team**: Ensure inclusive design coverage

---

## 🔗 **View 4: Cross-Scenario Dashboard**
**Purpose**: Visualize parallel scenario relationships

### Setup Instructions:
1. **Create New View**: Table view
2. **Name**: "🔗 Cross-Scenario Dashboard"  
3. **Configure Filters**:
   ```
   Labels: contains "bdd-scenario"
   ```
4. **Group By**: `Scenario Type`
5. **Custom Columns**:
   - Parallel Scenarios (parsed from issue body)
   - Inheritance Percentage
   - Dependency Count
6. **Color Coding**:
   - Green: All parallel scenarios completed
   - Yellow: Some parallel scenarios pending
   - Red: Blocked by dependencies

### Use Cases:
- 🎯 **System Architects**: Understand scenario relationships
- 📊 **Program Managers**: Track cross-functional delivery
- 🚀 **Release Managers**: Identify delivery dependencies

---

## 🧪 **View 5: BDD Test Status Dashboard**
**Purpose**: Monitor executable scenario health and test automation

### Setup Instructions:
1. **Create New View**: Board view
2. **Name**: "🧪 BDD Test Status"
3. **Configure Filters**:
   ```
   Labels: contains "bdd-scenario"  
   ```
4. **Group By**: `BDD Status`
5. **Board Columns**:
   - 🟢 All Tests Passing
   - 🟡 Some Tests Failing  
   - 🔴 Critical Failures
   - ⚫ Not Yet Automated
   - 📝 Gherkin Only
6. **Automation Rules**:
   - Auto-move to "Critical Failures" when labeled `test:failing`
   - Auto-move to "All Tests Passing" when all checkboxes checked

### Use Cases:  
- 🧪 **QA Engineers**: Identify failing scenarios requiring attention
- 🤖 **DevOps Engineers**: Monitor test automation health  
- 👨‍💼 **Engineering Managers**: Track testing coverage and quality

---

## 🎯 **View 6: Stakeholder Overview (Non-Technical)**
**Purpose**: Simplified view for business stakeholders

### Setup Instructions:
1. **Create New View**: Board view
2. **Name**: "👥 Stakeholder Overview"
3. **Configure Filters**:
   ```
   Type: is "B_S (Business)"
   Labels: does not contain "technical"
   ```
4. **Group By**: `Execution Status`
5. **Hide Technical Fields**: Test Coverage, BDD Status, etc.
6. **Show Business Fields**: Business Value, Priority Level, Actor involvement
7. **Simple Status Colors**:
   - Green: Ready/Completed
   - Yellow: In Progress
   - Red: Blocked/Failed

### Use Cases:
- 👥 **Business Stakeholders**: High-level progress without technical details
- 📊 **Executive Reporting**: Clean metrics for leadership reviews
- 🎯 **Product Strategy**: Align development with business priorities

---

## 🚀 **Advanced View Features**

### **Smart Filters**
Combine multiple criteria for powerful insights:
```
Priority: "Critical" AND BDD Status: "Critical Failures" AND Risk: "High"  
→ Shows scenarios needing immediate attention

Type: "T_S" AND Actor: "database" AND Test Coverage: < 80%
→ Shows database-related scenarios needing better test coverage

Type: "B_S" AND Business Value: "Must Have" AND Status: "Blocked"  
→ Shows critical business scenarios that are blocked
```

### **Automation Rules**
Set up automatic actions based on field changes:

1. **High Priority Alert**:
   ```
   When: Priority = "Critical" AND BDD Status = "Critical Failures"
   Action: Add label "urgent-attention" + Notify @dev-team
   ```

2. **Completion Automation**:
   ```
   When: All checkboxes in issue are checked
   Action: Set BDD Status = "All Tests Passing" + Move to Done column
   ```

3. **Risk Escalation**:
   ```
   When: Risk Assessment = "Critical" AND no activity for 2 days
   Action: Add to "Executive Review" project + Notify @project-manager
   ```

### **Custom Dashboards**
Create role-specific dashboards by combining views:

- **Developer Dashboard**: Technical Component Map + BDD Test Status
- **Product Dashboard**: Business Actor Journey + Stakeholder Overview  
- **QA Dashboard**: BDD Test Status + Cross-Scenario Dependencies
- **Manager Dashboard**: All views with executive summary metrics

---

## 📊 **Metrics & KPIs**

Track these key metrics across your views:

### **Development Velocity**
- Scenarios completed per sprint
- Average time from creation to completion
- Percentage of scenarios with passing tests

### **Quality Metrics** 
- BDD test coverage percentage
- Scenario failure rate
- Cross-scenario dependency health

### **Business Alignment**
- Percentage of "Must Have" scenarios completed
- Business value delivered per sprint
- Stakeholder satisfaction scores

---

## 🎯 **Quick Setup Checklist**

- [ ] **Run project setup script**: `.github/scripts/setup-advanced-project.sh`
- [ ] **Create all 6 project views** using instructions above
- [ ] **Configure automation rules** for your workflow
- [ ] **Set up team permissions** for different view access
- [ ] **Train team members** on using the new views
- [ ] **Create first BDD scenario** using new issue template
- [ ] **Test automation workflows** by updating scenario status

---

## 💡 **Pro Tips**

### **View Optimization**
- Use **saved filters** for frequently accessed scenario combinations
- Set up **view notifications** for critical status changes  
- Create **team-specific views** by filtering on assignee/team labels
- Use **board automation** to move cards based on field changes

### **Performance**
- Limit views to ~100 scenarios for best performance
- Use **date-based filters** to focus on current/upcoming work
- Archive completed scenarios periodically to keep views fast

### **Collaboration**  
- Share **view links** in team communications
- Use **view comments** to discuss scenario prioritization
- Set up **view subscriptions** for automated progress reports

---

**Next Step**: Proceed to configure project automation rules in the GitHub Projects interface!