# 🎯 GitHub Issue Hierarchy & Component Linking Strategy

## 📋 Proposed Issue Structure

### **Option A: Flat Structure with Smart Linking**
```
Issues:
├── S001: Cold Call to Candidate Placement (Master Scenario)
├── S1: Receive Bemeda sales call (Step Issue)
├── S2: Listen to platform overview (Step Issue)
├── S3: Discuss staffing needs (Step Issue)
├── ... (S4-S19)
├── U1: Call Reception Dashboard (UX Component)
├── U2: Contact Management Interface (UX Component)
├── T1: Contact Capture API (Technical Component)
├── T2: Call Logging Service (Technical Component)
└── ... (All U1-UN, T1-TN components)
```

**Benefits:**
- ✅ Simple, flat structure
- ✅ Easy to search and reference
- ✅ GitHub native linking (`#123`, `Closes #456`)
- ✅ Can use labels for organization

### **Option B: Hierarchical with Sub-issues** 
```
Issues:
├── S001: Cold Call to Candidate Placement (Master)
│   ├── A1: Healthcare Organisation Steps (Sub-issue)
│   │   ├── S1: Receive sales call (Sub-sub-issue)
│   │   └── S2-S8: Other org steps
│   ├── A2: JobSeeker Steps (Sub-issue)  
│   └── A3: Sales Team Steps (Sub-issue)
└── Components managed separately
```

**Benefits:**
- ✅ Clear hierarchy
- ❌ GitHub doesn't have native sub-issues
- ❌ Requires third-party tools or complex referencing

## 🔗 **RECOMMENDED: Option A with Smart Labeling**

### **Label Strategy:**
```
Scenario Labels:
- scenario:S001
- actor:A1, actor:A2, actor:A3
- step:S1, step:S2, etc.

Component Labels:
- component:ux, component:tech
- shared-component (for components used in multiple steps)
- step:S1+S5 (for components used in steps 1 and 5)

Status Labels:
- status:planning, status:in-progress, status:complete
- priority:high, priority:medium, priority:low
```

### **Cross-Reference Strategy:**
```
Step Issue S1 contains:
- Description: "Receive Bemeda sales call"
- Body: Detailed acceptance criteria, notes
- References: "Uses UX components: #45 #46 #47"
- References: "Uses Tech components: #78 #79 #80"
- Labels: scenario:S001, actor:A1, step:S1

UX Component U1 contains:
- Description: "Call Reception Dashboard"  
- Body: Design specs, mockups, responsive requirements
- References: "Supports steps: #12 #15" (links to S1, S4 issues)
- Labels: component:ux, step:S1+S4, shared-component
```

## 🔄 **Handling Shared UX/Tech Components**

### **Problem:** Component U25 (Form Fields) used in S1, S5, S9
### **Solution:**

1. **Single Component Issue:** Create one issue for U25
2. **Multi-Step Labels:** `step:S1+S5+S9` 
3. **Cross-References:** Link from S1, S5, S9 step issues
4. **Implementation Tracking:** Use checkboxes in U25 issue:
   ```
   - [ ] S1 integration (contact capture)
   - [x] S5 integration (job posting) 
   - [ ] S9 integration (profile creation)
   ```

## 🤖 **GitHub API Integration for Step Pages**

### **Dynamic Content Loading:**
```javascript
// Each step page (S1.html) will:
1. Fetch step issue content via GitHub API
2. Parse cross-references to find related components  
3. Load component descriptions and status
4. Display comments as discussion thread
5. Show task completion status
```

### **URL Pattern:**
```
Step Pages: /scenarios/steps/S1.html
API Calls: 
- GET /repos/3Stones-io/bemeda_personal/issues?labels=step:S1
- GET /repos/3Stones-io/bemeda_personal/issues/[step-issue-id]
- GET /repos/3Stones-io/bemeda_personal/issues/[step-issue-id]/comments
```

## 📝 **Implementation Phases**

### **Phase 1: Issue Template Update**
- Update `.github/ISSUE_TEMPLATE/component-definition.yml` 
- Add step/component selection dropdowns
- Include cross-reference fields

### **Phase 2: Create Core Issues** 
```bash
# Create scenario master issue
gh issue create --title "S001: Cold Call to Candidate Placement" --label "scenario:S001"

# Create step issues
gh issue create --title "S1: Receive Bemeda sales call" --label "scenario:S001,actor:A1,step:S1"
gh issue create --title "S2: Listen to platform overview" --label "scenario:S001,actor:A1,step:S2"

# Create component issues  
gh issue create --title "U1: Call Reception Dashboard" --label "component:ux,step:S1"
gh issue create --title "T1: Contact Capture API" --label "component:tech,step:S1"
```

### **Phase 3: JavaScript Integration**
- Update step pages to fetch GitHub content
- Add real-time comment loading
- Implement task status sync

## 🎯 **Example Complete Flow**

1. **User clicks S1 card** → Opens `/scenarios/steps/S1.html`
2. **Page loads GitHub content** → Fetches issue #123 (S1 step)
3. **Displays linked components** → Shows U1, U2, T1, T2 with status
4. **User clicks UX button** → Goes to `/uxui/index.html#s1` 
5. **User clicks GitHub button** → Opens GitHub issue #123

This creates a **seamless integration** where:
- 📝 All content lives in GitHub (single source of truth)
- 🌐 Web pages provide beautiful, navigable interface  
- 🔄 Real-time sync between GitHub issues and documentation
- 🎯 Smart component sharing across multiple steps

**Ready to implement this approach?**