# 🚀 GitHub-First Component Management

## Overview

This implementation uses **GitHub Issues as the single source of truth** for all platform components, with automatic synchronization to the documentation site.

## 🏗️ Architecture

```
GitHub Issues (Source of Truth)
    ↓ (GitHub Actions)
Component Registry (Generated)
    ↓ (Auto-sync)
Documentation Site (GitHub Pages)
    ↓ (Edit Buttons)
Back to GitHub Issues
```

## 📋 What's Already Set Up

✅ **GitHub CLI authenticated** with proper permissions  
✅ **Component templates** created in `/integration/templates/`  
✅ **Documentation structure** with hierarchical naming  
✅ **Issue template** with enforced naming conventions  
✅ **GitHub Actions workflow** for automatic sync  
✅ **Helper scripts** for component management  

## 🚀 Quick Start

### 1. Commit the GitHub Infrastructure

```bash
git add .github/ scripts/
git commit -m "Setup GitHub-First component management"
git push
```

### 2. Create Initial Components

```bash
node scripts/create-initial-components.js
```

This will create 15 GitHub issues for all our component types:
- Business scenarios, user stories, user story steps
- UX scenarios, user flows, mockups, UI components  
- Technical scenarios, use cases, features, technical components
- Test scenarios, test cases, bug reports, acceptance criteria

### 3. Test the Workflow

1. Edit any component issue on GitHub
2. The GitHub Actions workflow will automatically:
   - Extract component metadata
   - Update `docs/MASTER-REGISTRY.json`
   - Generate `docs/COMPONENT-MAP.json`
   - Commit changes to the repository

## 📝 Creating New Components

### Option 1: GitHub Web Interface
1. Go to your repository on GitHub
2. Click "Issues" → "New issue"
3. Select "Component Definition" template
4. Fill in the required fields
5. Submit - automatic validation and labeling will occur

### Option 2: GitHub CLI
```bash
gh issue create --template component-definition.yml
```

### Option 3: Manual Issue Creation
```bash
gh issue create --title "[COMPONENT] B_S002_US001 - New User Story" \
  --body "Component details..." \
  --label "component"
```

## 🔄 Manual Scenario Creation Process

For new scenarios, we work together manually:

1. **Planning Session**: Define scenario scope and components
2. **Issue Creation**: Create all component issues using templates
3. **Validation**: Ensure proper labeling and relationships
4. **Documentation**: Generate initial documentation
5. **Review**: Team review and approval

## 📊 Component Naming Conventions

All components follow the hierarchical naming pattern:

- **Business**: `B_S###_US###_USS###`
- **UX/UI**: `U_S###_UX###_M###_C###`
- **Technical**: `T_S###_UC###_F###_TC###`
- **Testing**: `TEST_S###_T###_B###_AC###`

## 🔧 Files Created

### GitHub Infrastructure
- `.github/ISSUE_TEMPLATE/component-definition.yml` - Issue template with validation
- `.github/workflows/sync-components.yml` - Auto-sync workflow

### Helper Scripts
- `scripts/generate-component-map.js` - Generates component maps
- `scripts/update-documentation.js` - Updates documentation
- `scripts/create-initial-components.js` - Creates initial issues

### Generated Files (Auto-created)
- `docs/MASTER-REGISTRY.json` - Component registry from GitHub
- `docs/COMPONENT-MAP.json` - Hierarchical component map

## 🎯 Benefits

- **Single Source of Truth**: GitHub Issues are the authoritative source
- **Real-time Sync**: Changes appear in documentation within minutes
- **Enforced Consistency**: Templates ensure proper naming and structure
- **Team Collaboration**: Comments, assignments, mentions in GitHub
- **Version Control**: Full history of all component changes
- **No Infrastructure**: Everything runs on GitHub's platform

## 🔍 Monitoring

### Check Component Status
```bash
# List all component issues
gh issue list --label "component"

# Check specific component
gh issue view [ISSUE_NUMBER]

# View component registry
cat docs/MASTER-REGISTRY.json
```

### Manual Workflow Trigger
```bash
# Trigger sync workflow manually
gh workflow run "Sync Components from Issues"
```

## 🚨 Troubleshooting

### Issue Template Not Appearing
- Ensure `.github/ISSUE_TEMPLATE/` directory exists
- Check that `component-definition.yml` is properly formatted
- Verify the file is committed and pushed

### Workflow Not Triggering
- Check that the workflow file is in `.github/workflows/`
- Verify GitHub Actions are enabled for the repository
- Check workflow permissions in repository settings

### Component Not Syncing
- Verify the issue has the `component` label
- Check that the issue body follows the template format
- Review workflow logs in the Actions tab

## 📚 Next Steps

1. **Test the workflow** with the initial components
2. **Create a GitHub Project board** for visual management
3. **Add team members** and assign components
4. **Expand component details** with implementation notes
5. **Create additional scenarios** using the manual process

This setup gives us the perfect balance of automation and control, with GitHub as our collaborative hub and automatic documentation generation.
