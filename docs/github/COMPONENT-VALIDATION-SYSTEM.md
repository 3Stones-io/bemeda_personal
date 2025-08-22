# 🛡️ Component Validation & Auto-Labeling System

## 🚨 Problem Solved

**Before**: Users could create component issues without proper labels → Components not indexed → Broken automation

**After**: Enforced templates + automatic validation + auto-labeling → All components properly indexed

## 🔧 How It Works

### **1. Enforced Issue Template**

**File**: `.github/ISSUE_TEMPLATE/component-definition.yml`

**Features**:
- ✅ **Required fields** marked with `*` (Component ID, Type, Domain, Title, Description)
- ✅ **Dropdown validation** - Users must select from predefined options
- ✅ **Naming convention guidance** - Shows examples like "US001, TC001"
- ✅ **Auto-generated JSON** metadata section
- ✅ **Validation checklist** - Users must confirm they understand requirements

**Template enforces**:
```yaml
Component ID: US001 (required, validated pattern)
Component Type: user-story (dropdown, required)  
Domain: scenarios (dropdown, required)
Priority: high (dropdown, optional)
Status: planning (dropdown, optional)
```

### **2. Automatic Validation & Labeling**

**File**: `.github/workflows/auto-label-components.yml`

**Triggered on**: Issue created or edited

**What it does**:
1. **Detects component issues** (by `[COMPONENT]` title or existing `component` label)
2. **Parses issue template data** from the form fields
3. **Auto-adds labels**:
   - `component` (always)
   - `component:user-story` (from type)
   - `domain:scenarios` (from domain)
   - `participant:organisation` (from participant)
   - `priority:high` (from priority)
   - `status:planning` (from status)
4. **Updates JSON metadata** in the issue body with parsed information
5. **Validates requirements** and posts error/warning comments
6. **Adds `needs-fixes` label** if validation fails

### **3. Smart Edit Button Integration**

**Updated JavaScript** (`github-edit-buttons.js`) now:
- ✅ **Forces template use** for new components
- ✅ **Pre-fills component ID** in template URL
- ✅ **Shows "auto-labeled" in button text** to indicate it will be properly indexed

## 📊 Validation Rules

### **✅ Automatic Success**
- Issue title includes `[COMPONENT]`
- Component ID follows pattern: `US001`, `TC001`, `UI001`, etc.
- Required fields (ID, Type, Domain, Title, Description) are filled
- Uses issue template form structure

### **⚠️ Warnings (will be flagged but not blocked)**
- Component ID doesn't follow naming convention
- Missing optional fields like Participant or Priority

### **❌ Errors (will be blocked with `needs-fixes` label)**
- Missing `[COMPONENT]` in title
- No Component ID specified
- Missing required fields (Type, Domain, Title, Description)

## 🎯 Labels Applied Automatically

### **Always Applied**
- `component` - Marks as component for indexing

### **Based on Form Input**
- `component:{type}` - e.g., `component:user-story`, `component:technical-component`
- `domain:{domain}` - e.g., `domain:scenarios`, `domain:technical`
- `participant:{participant}` - e.g., `participant:organisation`, `participant:jobseeker`
- `priority:{priority}` - e.g., `priority:high`, `priority:medium`
- `status:{status}` - e.g., `status:planning`, `status:in-progress`

### **Validation Labels**
- `needs-fixes` - Added when validation fails, removed when fixed

## 🔄 Complete Workflow

### **1. User Clicks "Create Component"**
```
Edit Button → GitHub Template → Enforced Form → Proper Labels
```

### **2. Automatic Processing**
```
Issue Created → Auto-Validation → Labels Added → JSON Updated → Indexed by Sync
```

### **3. Failed Validation Recovery**
```
Validation Fails → Comment Posted → User Fixes → Re-validates → Success
```

## 📋 Example Workflow

### **Step 1: User creates component via template**
- Clicks "➕ Create US019 (auto-labeled)" button
- Gets redirected to GitHub with pre-filled template
- Fills out required form fields

### **Step 2: GitHub Action processes**
```yaml
Issue #217 created with title: "[COMPONENT] US019 - New Feature"
↓
Auto-validation detects component issue
↓
Parses form data:
  - ID: US019
  - Type: user-story  
  - Domain: scenarios
  - Priority: medium
↓
Adds labels: component, component:user-story, domain:scenarios, priority:medium
↓
Updates JSON metadata in issue body
↓
Posts validation success (or errors if any)
```

### **Step 3: Component indexed**
- Sync workflow picks up labeled issue
- Adds to MASTER-REGISTRY.json
- Generates documentation
- Deploys to GitHub Pages

## 🛡️ Validation Examples

### **✅ Valid Component Issue**
```
Title: [COMPONENT] US019 - User Authentication
Labels: component, component:user-story, domain:technical, priority:high
Status: ✅ Automatically indexed
```

### **❌ Invalid Component Issue (old way)**
```
Title: Add user authentication
Labels: enhancement
Status: ❌ Not indexed, needs manual fixing
```

### **🔧 Auto-Fixed Component Issue**
```
Title: [COMPONENT] US019 - User Authentication  
Labels: enhancement (old) → component, component:user-story, domain:technical (auto-added)
Status: ✅ Fixed and indexed automatically
```

## 🚀 Benefits

1. **Zero Manual Labor** - No more manually adding labels
2. **Guaranteed Indexing** - All components follow same structure
3. **Validation Feedback** - Users get immediate feedback on errors
4. **Consistent Naming** - Enforced conventions prevent confusion
5. **Automatic Recovery** - Failed validation can be easily fixed

## 📊 Monitoring

### **Check Validation Status**
- Issues with `needs-fixes` label need attention
- Validation comments show specific errors
- GitHub Actions tab shows processing logs

### **Verify Proper Labeling**
```bash
# All properly labeled components
gh issue list --label "component" 

# Components needing fixes
gh issue list --label "needs-fixes"

# Components by type
gh issue list --label "component:user-story"
```

This system ensures **100% proper labeling** and **automatic indexing** of all components!