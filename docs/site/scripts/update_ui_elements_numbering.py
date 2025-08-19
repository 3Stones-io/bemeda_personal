#!/usr/bin/env python3
"""
Update JOB S1 scenario page with consistent UI element numbering and links.
"""

import re

# UI Element mapping from the component analysis
ui_elements_mapping = {
    # Organisation UI Elements
    "Dashboard": {"id": "UI-001", "file": "UI-001-dashboard-organisation.html"},
    "Job Form": {"id": "UI-002", "file": "UI-002-job-form.html"},
    "Candidate List": {"id": "UI-003", "file": "UI-003-candidate-list.html"},
    "Interview Tool": {"id": "UI-004", "file": "UI-004-interview-tool.html"},
    
    # JobSeeker UI Elements
    "Profile Form": {"id": "UI-005", "file": "UI-005-profile-form.html"},
    "Job Browser": {"id": "UI-006", "file": "UI-006-job-browser.html"},
    "Application": {"id": "UI-007", "file": "UI-007-application-interface.html"},
    "Messages": {"id": "UI-008", "file": "UI-008-messages-interface.html"},
    
    # Sales Team UI Elements
    "CRM Dashboard": {"id": "UI-009", "file": "UI-009-crm-dashboard.html"},
    "Lead Forms": {"id": "UI-010", "file": "UI-010-lead-forms.html"},
    "Analytics": {"id": "UI-011", "file": "UI-011-analytics-dashboard.html"},
    "Automation": {"id": "UI-012", "file": "UI-012-automation-tools.html"}
}

def update_ui_elements(content):
    """Update UI elements with numbering and links."""
    
    # Pattern to find UI element blocks
    pattern = r'(<div class="ui-element">\s*<div class="ui-element-name">)([^<]+)(</div>\s*<div class="ui-element-status">)([^<]+)(</div>\s*</div>)'
    
    def replace_ui_element(match):
        element_name = match.group(2).strip()
        status = match.group(4).strip()
        
        if element_name in ui_elements_mapping:
            ui_info = ui_elements_mapping[element_name]
            link_path = f"../../design-system/components/{ui_info['file']}"
            
            # Create linked UI element with ID
            return f'''<a href="{link_path}" class="ui-element" style="text-decoration: none; color: inherit;">
                            <div class="ui-element-id">{ui_info['id']}</div>
                            <div class="ui-element-name">{element_name}</div>
                            <div class="ui-element-status">{status}</div>
                        </a>'''
        else:
            # Keep original if not found in mapping
            return match.group(0)
    
    # Apply replacements
    updated_content = re.sub(pattern, replace_ui_element, content, flags=re.MULTILINE | re.DOTALL)
    
    # Add CSS for UI element IDs if not already present
    css_addition = """
        .ui-element-id {
            background: #0066cc;
            color: white;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.8rem;
            font-weight: 600;
            margin-bottom: 4px;
        }
        
        a.ui-element {
            display: block;
            text-decoration: none;
            color: inherit;
        }
        
        a.ui-element:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 8px rgba(0,102,204,0.2);
        }"""
    
    # Insert CSS before the closing </style> tag if not already present
    if "ui-element-id" not in updated_content:
        updated_content = updated_content.replace("</style>", css_addition + "\n    </style>")
    
    return updated_content

def main():
    """Update the JOB S1 scenario page."""
    file_path = "/Users/spitexbemeda/Documents/Bemeda Personal Page/docs/site/sitemap/job/s1/index.html"
    
    # Read current content
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update UI elements
    updated_content = update_ui_elements(content)
    
    # Write updated content
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(updated_content)
    
    print("Updated JOB S1 scenario page with numbered UI elements and links")
    print("UI Elements now link to their component documentation pages")

if __name__ == "__main__":
    main()