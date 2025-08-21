#!/usr/bin/env python3
"""
Content Migration Script for Bemeda Platform Documentation

This script helps migrate existing content from the old structure to the new unified feature-based structure.
It creates placeholder files and directories to maintain the new organization.

Usage: python3 migrate-content.py
"""

import os
import shutil
from pathlib import Path

def create_directory_structure():
    """Create the complete directory structure for all features"""
    
    # Base features directory
    features_dir = Path("features")
    features_dir.mkdir(exist_ok=True)
    
    # Feature definitions with their participant subdirectories
    features = {
        "job-search-discovery": {
            "description": "Advanced job search with filtering, location search, salary information, and email notifications",
            "participants": ["business", "design", "testing", "technical"]
        },
        "user-profiles": {
            "description": "Complete profile creation with medical specialty selection, resume builder, and portfolio management",
            "participants": ["business", "design", "testing", "technical"]
        },
        "application-management": {
            "description": "Streamlined application process with custom cover letters, video applications, and status tracking",
            "participants": ["business", "design", "testing", "technical"]
        },
        "communication": {
            "description": "Real-time chat, document sharing, message history, and multi-language support",
            "participants": ["business", "design", "testing", "technical"]
        },
        "job-posting-tools": {
            "description": "Detailed job builder, video integration, candidate management, and rating system",
            "participants": ["business", "design", "testing", "technical"]
        },
        "contract-management": {
            "description": "Digital job offers, contract templates, variable processing, and digital signatures",
            "participants": ["business", "design", "testing", "technical"]
        },
        "platform-infrastructure": {
            "description": "Multi-language support, rating system, media management, and background processing",
            "participants": ["business", "design", "testing", "technical"]
        }
    }
    
    print("🏗️  Creating feature directory structure...")
    
    for feature_name, feature_info in features.items():
        feature_path = features_dir / feature_name
        feature_path.mkdir(exist_ok=True)
        
        print(f"  📁 Creating {feature_name}/")
        
        # Create participant subdirectories
        for participant in feature_info["participants"]:
            participant_path = feature_path / participant
            participant_path.mkdir(exist_ok=True)
            
            # Create placeholder index.html for each participant section
            create_participant_index(participant_path, feature_name, participant)
        
        # Create main feature index.html
        create_feature_index(feature_path, feature_name, feature_info["description"])
    
    print("✅ Feature directory structure created successfully!")

def create_participant_index(participant_path, feature_name, participant):
    """Create a placeholder index.html for participant sections"""
    
    participant_titles = {
        "business": "Business Analysis",
        "design": "UX/UI Design", 
        "testing": "Testing & QA",
        "technical": "Technical Implementation"
    }
    
    participant_owners = {
        "business": "Nicole",
        "design": "Oghogho",
        "testing": "Dejan", 
        "technical": "Almir"
    }
    
    participant_icons = {
        "business": "📋",
        "design": "🎨",
        "testing": "🐛",
        "technical": "⚙️"
    }
    
    content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{participant_titles[participant]} - {feature_name.title()} | Bemeda Platform</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f5f5f7;
            margin: 0;
            padding: 40px 20px;
        }}
        .container {{
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }}
        .header {{
            text-align: center;
            margin-bottom: 40px;
        }}
        .icon {{
            font-size: 4rem;
            margin-bottom: 20px;
        }}
        .title {{
            font-size: 2rem;
            color: #1a1a1a;
            margin-bottom: 16px;
        }}
        .subtitle {{
            color: #666;
            font-size: 1.1rem;
            margin-bottom: 8px;
        }}
        .owner {{
            color: #0066cc;
            font-weight: 600;
        }}
        .description {{
            color: #666;
            line-height: 1.6;
            margin-bottom: 30px;
        }}
        .back-link {{
            display: inline-block;
            color: #0066cc;
            text-decoration: none;
            font-weight: 500;
            margin-bottom: 20px;
        }}
        .back-link:hover {{
            text-decoration: underline;
        }}
        .placeholder {{
            background: #f8f9fa;
            border: 2px dashed #ddd;
            border-radius: 8px;
            padding: 30px;
            text-align: center;
            color: #666;
        }}
    </style>
</head>
<body>
    <div class="container">
        <a href="../index.html" class="back-link">← Back to {feature_name.title()}</a>
        
        <div class="header">
            <div class="icon">{participant_icons[participant]}</div>
            <h1 class="title">{participant_titles[participant]}</h1>
            <p class="subtitle">Feature: {feature_name.replace('-', ' ').title()}</p>
            <p class="owner">Owner: {participant_owners[participant]}</p>
        </div>
        
        <p class="description">
            This section contains {participant_titles[participant].lower()} documentation for the 
            {feature_name.replace('-', ' ').title()} feature. Content will be migrated here from the 
            existing participant directories.
        </p>
        
        <div class="placeholder">
            <h3>🚧 Content Migration in Progress</h3>
            <p>This section is being populated with content from the existing documentation structure.</p>
            <p>Check back soon for complete documentation!</p>
        </div>
    </div>
</body>
</html>"""
    
    with open(participant_path / "index.html", "w") as f:
        f.write(content)

def create_feature_index(feature_path, feature_name, description):
    """Create the main feature index.html"""
    
    # This is already created, so we'll skip it
    pass

def create_migration_guide():
    """Create a migration guide for content owners"""
    
    guide_content = """# Content Migration Guide

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
"""
    
    with open("MIGRATION-GUIDE.md", "w") as f:
        f.write(guide_content)
    
    print("📋 Migration guide created: MIGRATION-GUIDE.md")

def main():
    """Main migration function"""
    print("🚀 Bemeda Platform Documentation Migration Script")
    print("=" * 50)
    
    # Change to the script's directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Create the new structure
    create_directory_structure()
    
    # Create migration guide
    create_migration_guide()
    
    print("\n🎉 Migration setup complete!")
    print("\nNext steps:")
    print("1. Review the new directory structure")
    print("2. Read the MIGRATION-GUIDE.md for detailed instructions")
    print("3. Start migrating content from existing directories")
    print("4. Update the unified table with actual progress")
    print("\nGood luck with the migration! 🚀")

if __name__ == "__main__":
    main()
