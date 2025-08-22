# 🔧 Naming Consistency Solution for Bemeda Platform

## 🚨 Current Problems

### 1. **Multiple Sources of "Truth"**
- `/docs/registry/components.json` - Says US001 = "Cold call from Bemeda"
- `/docs/metadata/components/US001.json` - Says US001 = "Organisation Posts Job"  
- `/docs/scenarios/S001/US001.html` - Says US001 = "Organisation Receives Cold Call"
- GitHub issues - We almost created US001 = "User Registration System"

### 2. **Inconsistent Naming Patterns**
- UI components: `UI-001` vs `C001`
- Some use hyphens, some don't
- Different prefixes for same component types

### 3. **No Version Control for Changes**
- When a component changes, old references remain
- No audit trail of naming changes

## 🎯 Proposed Solution: Single Source of Truth System

### **1. Master Component Registry (Database)**

Create a **master JSON database** that is THE single source of truth:

```json
// /docs/metadata/MASTER-REGISTRY.json
{
  "version": "2.0.0",
  "last_updated": "2024-01-22T10:00:00Z",
  "components": {
    "US001": {
      "id": "US001",
      "title": "Organisation Receives Cold Call",
      "description": "Organisation receives cold call from Bemeda sales representative",
      "type": "user-story",
      "domain": "scenarios",
      "participant": "Organisation",
      "status": "active",
      "created": "2024-01-01",
      "modified": "2024-01-22",
      "aliases": ["ORG-COLD-CALL"],
      "replaces": null,
      "github_issue": null,
      "urls": {
        "spec": "https://3stones-io.github.io/bemeda_personal/docs/scenarios/S001/US001.html",
        "metadata": "https://github.com/3Stones-io/bemeda_personal/blob/gh-pages/docs/metadata/components/US001.json"
      }
    }
  },
  "naming_rules": {
    "user_story": "US[0-9]{3}",
    "ui_component": "UI[0-9]{3}",
    "technical": "TC[0-9]{3}",
    "feature": "F[0-9]{3}"
  }
}
```

### **2. Automated Sync System**

Create scripts that:
- **Generate** all other files FROM the master registry
- **Validate** that all references match the registry
- **Update** GitHub issues when registry changes

```bash
# /docs/scripts/sync-components.js
// 1. Read MASTER-REGISTRY.json
// 2. Generate/update all component files
// 3. Update GitHub issues via API
// 4. Create change log
```

### **3. GitHub as Workflow Manager (Not Source)**

GitHub becomes the **workflow tool**, not the source of truth:
- Issues reference the master registry
- Labels match registry domains
- Custom fields pull from registry

### **4. For Claude (AI) Integration**

Create a **context file** that loads on every session:

```markdown
# /CLAUDE.md

## Component Naming Rules
ALWAYS check MASTER-REGISTRY.json for component names and IDs.
NEVER assume component names from context.

## Current Component Mapping
Last updated: 2024-01-22

US001 = Organisation Receives Cold Call (NOT User Registration)
US002 = Discuss Staffing Needs
... 

## When Creating Issues
1. Check MASTER-REGISTRY.json first
2. Use exact titles from registry
3. Include registry URLs in issue body
```

### **5. Version Control for Changes**

Add versioning to track changes:

```json
// /docs/metadata/registry-changelog.json
{
  "changes": [
    {
      "date": "2024-01-22",
      "version": "2.0.0",
      "changes": [
        {
          "component": "US001",
          "field": "title",
          "old": "Organisation Posts Job",
          "new": "Organisation Receives Cold Call",
          "reason": "Corrected to match actual scenario flow"
        }
      ]
    }
  ]
}
```

## 🚀 Implementation Plan

### **Phase 1: Audit & Document (Immediate)**
1. Create complete component inventory
2. Document all naming conflicts
3. Decide on correct names for each component

### **Phase 2: Create Master Registry (This Week)**
1. Build MASTER-REGISTRY.json with ALL components
2. Include all metadata in one place
3. Version it properly

### **Phase 3: Build Sync Tools (Next Week)**
```javascript
// sync-tools needed:
- registry-to-html.js      // Generate HTML from registry
- registry-to-github.js    // Sync with GitHub issues
- validate-references.js   // Check all cross-references
- registry-changelog.js    // Track all changes
```

### **Phase 4: GitHub Integration (Week 3)**
1. Update all GitHub issues to match registry
2. Create GitHub Action to validate PRs against registry
3. Auto-update issues when registry changes

## 🔄 Workflow After Implementation

### **For Developers:**
1. Check MASTER-REGISTRY.json
2. Make changes to registry if needed
3. Run sync script
4. All files auto-update

### **For Claude/AI:**
1. Load CLAUDE.md at start
2. Always check registry for current names
3. Flag inconsistencies found

### **For GitHub:**
1. Issues auto-created from registry
2. Webhooks update when registry changes
3. Labels stay in sync

## 📊 Benefits

1. **Single Source of Truth** - No more conflicts
2. **Automated Updates** - Change once, update everywhere
3. **Version History** - Track what changed and why
4. **AI-Friendly** - Clear context for Claude
5. **GitHub Integration** - Issues stay synchronized
6. **Validation** - Catch errors before they spread

## 🛠️ Quick Fixes for Now

Until full implementation:

1. **Create a simple mapping file:**
```json
// /docs/COMPONENT-MAP.json
{
  "US001": {
    "correct_title": "Organisation Receives Cold Call",
    "participant": "Organisation",
    "scenario": "S001"
  }
}
```

2. **Update CLAUDE.md** with current mappings

3. **Add validation** to issue creation script:
```bash
# Check component exists in map before creating issue
if ! grep -q "$component_id" COMPONENT-MAP.json; then
  echo "ERROR: Component $component_id not found in map"
  exit 1
fi
```

## 🎯 Decision Needed

**Which naming convention do we standardize on?**
- `US001` or `US-001`?
- `UI001` or `UI-001` or `C001`?
- Descriptive suffixes (`UI-001-dashboard`) or just IDs?

**What is the canonical source?**
- Make MASTER-REGISTRY.json the single source
- Everything else generates from it
- GitHub syncs with it, not vice versa

This approach ensures consistency across all systems and users!