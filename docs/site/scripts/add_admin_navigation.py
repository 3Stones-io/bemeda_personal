#!/usr/bin/env python3
"""
Add Admin navigation to all existing pages that have navigation.
"""

import os
import re
from pathlib import Path

def add_admin_navigation(content):
    """Add Admin dropdown to navigation."""
    
    # Pattern to find the Table nav item and add Admin after it
    pattern = r'(<li class="nav-item">\s*<a href="[^"]*table[^"]*" class="nav-link"[^>]*>Table</a>\s*</li>)'
    
    admin_nav = '''<li class="nav-item dropdown">
                    <a href="/site/sitemap/admin/index.html" class="nav-link" data-i18n="nav.admin">Admin</a>
                    <div class="dropdown-content">
                        <a href="/site/sitemap/admin/s1/index.html" data-i18n="nav.admin-dashboard">Platform Dashboard</a>
                        <a href="/site/sitemap/admin/s2/index.html" data-i18n="nav.admin-support">User Support</a>
                        <a href="/site/sitemap/admin/s3/index.html" data-i18n="nav.admin-content">Content Management</a>
                        <a href="/site/sitemap/admin/s4/index.html" data-i18n="nav.admin-settings">System Settings</a>
                    </div>
                </li>'''
    
    # Add admin navigation after Table if not already present and Table exists
    if 'nav.admin' not in content and 'Table</a>' in content:
        content = re.sub(pattern, r'\1\n                ' + admin_nav, content)
    
    return content

def process_file(filepath):
    """Process a single HTML file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Skip if no navigation or admin already exists
        if 'nav-list' not in content or 'nav.admin' in content:
            return False
        
        original_content = content
        content = add_admin_navigation(content)
        
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        
        return False
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    """Update all sitemap HTML files with admin navigation."""
    sitemap_dir = Path("/Users/spitexbemeda/Documents/Bemeda Personal Page/docs/site/sitemap")
    
    # Find all HTML files except admin (we'll create those separately)
    html_files = []
    for section in ['job', 'tmp', 'table']:
        section_path = sitemap_dir / section
        if section_path.exists():
            html_files.extend(list(section_path.rglob("*.html")))
    
    print(f"Found {len(html_files)} HTML files to update")
    
    updated_count = 0
    for filepath in html_files:
        if process_file(filepath):
            updated_count += 1
            print(f"Updated: {filepath.relative_to(sitemap_dir)}")
    
    print(f"\nCompleted! Updated {updated_count} files with admin navigation.")

if __name__ == "__main__":
    main()