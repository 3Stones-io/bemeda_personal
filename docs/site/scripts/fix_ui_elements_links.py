#!/usr/bin/env python3
"""
Fix UI Elements links in Quick Links sections across all HTML pages.
Updates relative paths to the correct absolute path.
"""

import os
import re
from pathlib import Path

def fix_ui_elements_links(content):
    """Replace relative UI Elements paths with the correct absolute path."""
    # Pattern to match various relative paths to ui-elements/index.html
    patterns = [
        # Match any relative path ending with assets/ui-elements/index.html
        (r'href="[\.\.\/]*assets/ui-elements/index\.html"', r'href="/site/assets/ui-elements/index.html"'),
        # Match paths that might have sitemap in them
        (r'href="[\.\.\/]*sitemap/assets/ui-elements/index\.html"', r'href="/site/assets/ui-elements/index.html"'),
        # Match any path with ui-elements/index.html
        (r'href="[^"]*ui-elements/index\.html"', r'href="/site/assets/ui-elements/index.html"'),
    ]
    
    for pattern, replacement in patterns:
        content = re.sub(pattern, replacement, content)
    
    return content

def process_file(filepath):
    """Process a single HTML file to fix UI Elements links."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Skip if file doesn't have ui-elements link
        if 'ui-elements/index.html' not in content:
            return False
        
        original_content = content
        
        # Fix UI Elements links
        content = fix_ui_elements_links(content)
        
        # Only write if changes were made
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        
        return False
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    """Main function to process all HTML files."""
    docs_dir = Path("/Users/spitexbemeda/Documents/Bemeda Personal Page/docs")
    
    # Find all HTML files
    html_files = list(docs_dir.rglob("*.html"))
    
    print(f"Found {len(html_files)} HTML files to check")
    
    updated_count = 0
    for filepath in html_files:
        if process_file(filepath):
            updated_count += 1
            print(f"Updated: {filepath.relative_to(docs_dir)}")
    
    print(f"\nCompleted! Updated {updated_count} files.")

if __name__ == "__main__":
    main()