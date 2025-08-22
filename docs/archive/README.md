# Archive - Legacy Documentation Structure

This folder contains the legacy documentation structure that was reorganized on 2024-01-21.

## Contents

### 📁 sitemap/
Original scenario structure with detailed user stories:
- `job/s1/` - Original S001 content (now in `/scenarios/S001/`)
- `tmp/` - Temporary staffing scenarios (S002, S003, etc.)
- `admin/` - Platform administration scenarios (S004-S007)
- `table/` - Table view implementations

### 📁 features/
Feature-specific detailed content organized by domain:
- Each feature has business/design/technical/testing subfolders
- Detailed implementation specifications
- Cross-domain collaboration templates

### 📁 design-system/
Original UI/UX design system:
- `components/` - Individual UI component specifications
- `mockups/` - Interface mockups and wireframes
- Component templates and design standards

### 📁 assets/
Supporting assets and resources:
- `features/` - Individual feature HTML files
- `translations/` - Multi-language content
- `users/` - User persona documentation
- `ui-elements/` - UI component library

### 📁 templates/
Legacy content templates:
- Various component and page templates
- Navigation and process step templates
- Content structure guidelines

## Migration Notes

**Migrated to New Structure:**
- S001 scenarios → `/scenarios/S001/`
- UI components → `/ux-ui/components/`
- Technical features → `/technical/features/`
- Test cases → `/testing/test-cases/`

**New Structure Benefits:**
- Domain-based organization (Business/UX-UI/Technical/Testing)
- Global component registry with unique IDs
- Cross-reference tracking and relationships
- Unified view across all domains
- Scalable template system

**Archive Access:**
This content is preserved for reference and can be:
1. Migrated piece-by-piece to new structure as needed
2. Used as source material for populating new templates
3. Referenced for historical context and evolution tracking

Last Updated: 2024-01-21
New Structure: `/docs/scenarios/`, `/docs/ux-ui/`, `/docs/technical/`, `/docs/testing/`, `/docs/unified-view/`