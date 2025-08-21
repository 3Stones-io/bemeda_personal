# Content Migration Guide

## 🚀 Getting Started with the New Structure

The documentation has been reorganized into a unified feature-based structure. Here's how to migrate your existing content:

### **1. Identify Your Content**

- **Nicole (Business)**: Look in `docs/site/participants/scenarios/` and `docs/oldsite/`
- **Oghogho (Design)**: Look in `docs/site/participants/ux-ui/` and `docs/site/design-system/`
- **Dejan (Testing)**: Look in `docs/site/participants/testing/`
- **Almir (Technical)**: Look in `docs/site/participants/features/` and `docs/site/assets/`

### **2. Map Content to Features**

Use this mapping to organize your content:

- **Job Search & Discovery** (`features/job-search-discovery/`):
  - Search functionality, filters, location search, salary info
  
- **User Profiles** (`features/user-profiles/`):
  - Profile creation, resume builder, portfolio management
  
- **Application Management** (`features/application-management/`):
  - Application process, status tracking, cover letters
  
- **Communication** (`features/communication/`):
  - Chat, messaging, notifications, multi-language
  
- **Job Posting Tools** (`features/job-posting-tools/`):
  - Job creation, employer tools, candidate management
  
- **Contract Management** (`features/contract-management/`):
  - Job offers, contracts, digital signatures
  
- **Platform Infrastructure** (`features/platform-infrastructure/`):
  - Multi-language, ratings, media, background processing

### **3. Migration Steps**

1. **Copy Content**: Move relevant files to the appropriate feature directory
2. **Update Links**: Fix any broken internal links
3. **Update Navigation**: Ensure back-links work correctly
4. **Test**: Verify all content is accessible

### **4. File Organization**

For each feature, organize content like this:

```
features/job-search-discovery/
├── business/
│   ├── scenarios.html          # Business scenarios
│   ├── user-stories.html       # User stories
│   └── use-cases.html          # Use cases
├── design/
│   ├── mockups.html            # Design mockups
│   ├── components.html         # UI components
│   └── user-flows.html         # User experience flows
├── testing/
│   ├── test-cases.html         # Test scenarios
│   ├── acceptance-criteria.html # Acceptance criteria
│   └── bug-reports.html        # Known issues
└── technical/
    ├── specifications.html      # Technical specs
    ├── api-docs.html           # API documentation
    └── database-schema.html    # Database design
```

### **5. Update Cross-References**

- Update the unified table (`unified-table/index.html`) with actual progress
- Fix any broken links between features
- Ensure participant domain links still work

### **6. Validation Checklist**

- [ ] All content is accessible from the unified table
- [ ] Feature pages show correct progress status
- [ ] Cross-references between features work
- [ ] Participant domain links remain functional
- [ ] No broken internal links

## 📞 Need Help?

- Check the main README for structure details
- Review the unified table for feature status
- Use the feature page templates as examples
- Contact the team for clarification on content mapping

---

*Happy migrating! 🎉*
