#!/usr/bin/env python3
"""
Fix navigation issues on all HTML pages in the sitemap directory.
- Updates relative paths to absolute paths
- Ensures dropdown CSS styles are present
- Fixes overflow issues for dropdown visibility
"""

import os
import re
from pathlib import Path

def fix_navigation_paths(content):
    """Replace relative navigation paths with absolute paths."""
    # Define the navigation link replacements
    replacements = [
        # Index link - always absolute
        (r'href="[^"]*(?:\/)?index\.html"([^>]*nav\.index)', r'href="/index.html"\1'),
        
        # JOB link variations
        (r'href="\.\.\/\.\.\/\.\.\/\.\.\/job\/index\.html"', r'href="/site/sitemap/job/index.html"'),
        (r'href="\.\.\/\.\.\/\.\.\/job\/index\.html"', r'href="/site/sitemap/job/index.html"'),
        (r'href="\.\.\/\.\.\/job\/index\.html"', r'href="/site/sitemap/job/index.html"'),
        (r'href="\.\.\/job\/index\.html"', r'href="/site/sitemap/job/index.html"'),
        (r'href="job\/index\.html"', r'href="/site/sitemap/job/index.html"'),
        (r'href="\.\/job\/index\.html"', r'href="/site/sitemap/job/index.html"'),
        
        # TMP main link variations
        (r'href="\.\.\/\.\.\/\.\.\/tmp\/index\.html"', r'href="/site/sitemap/tmp/index.html"'),
        (r'href="\.\.\/\.\.\/tmp\/index\.html"', r'href="/site/sitemap/tmp/index.html"'),
        (r'href="\.\.\/tmp\/index\.html"', r'href="/site/sitemap/tmp/index.html"'),
        (r'href="tmp\/index\.html"', r'href="/site/sitemap/tmp/index.html"'),
        (r'href="\.\/tmp\/index\.html"', r'href="/site/sitemap/tmp/index.html"'),
        (r'href="\.\.\/\.\.\/index\.html"([^>]*nav\.tmp)', r'href="/site/sitemap/tmp/index.html"\1'),
        (r'href="\.\.\/index\.html"([^>]*nav\.tmp)', r'href="/site/sitemap/tmp/index.html"\1'),
        
        # TMP dropdown links
        (r'href="\.\.\/\.\.\/\.\.\/tmp\/temporary\/index\.html"', r'href="/site/sitemap/tmp/temporary/index.html"'),
        (r'href="\.\.\/\.\.\/tmp\/temporary\/index\.html"', r'href="/site/sitemap/tmp/temporary/index.html"'),
        (r'href="\.\.\/tmp\/temporary\/index\.html"', r'href="/site/sitemap/tmp/temporary/index.html"'),
        (r'href="\.\.\/temporary\/index\.html"', r'href="/site/sitemap/tmp/temporary/index.html"'),
        (r'href="\.\.\/\.\.\/temporary\/index\.html"', r'href="/site/sitemap/tmp/temporary/index.html"'),
        (r'href="tmp\/temporary\/index\.html"', r'href="/site/sitemap/tmp/temporary/index.html"'),
        (r'href="\.\/tmp\/temporary\/index\.html"', r'href="/site/sitemap/tmp/temporary/index.html"'),
        
        (r'href="\.\.\/\.\.\/\.\.\/tmp\/tryhire\/index\.html"', r'href="/site/sitemap/tmp/tryhire/index.html"'),
        (r'href="\.\.\/\.\.\/tmp\/tryhire\/index\.html"', r'href="/site/sitemap/tmp/tryhire/index.html"'),
        (r'href="\.\.\/tmp\/tryhire\/index\.html"', r'href="/site/sitemap/tmp/tryhire/index.html"'),
        (r'href="\.\.\/tryhire\/index\.html"', r'href="/site/sitemap/tmp/tryhire/index.html"'),
        (r'href="\.\.\/\.\.\/tryhire\/index\.html"', r'href="/site/sitemap/tmp/tryhire/index.html"'),
        (r'href="tmp\/tryhire\/index\.html"', r'href="/site/sitemap/tmp/tryhire/index.html"'),
        (r'href="\.\/tmp\/tryhire\/index\.html"', r'href="/site/sitemap/tmp/tryhire/index.html"'),
        
        (r'href="\.\.\/\.\.\/\.\.\/tmp\/pool\/index\.html"', r'href="/site/sitemap/tmp/pool/index.html"'),
        (r'href="\.\.\/\.\.\/tmp\/pool\/index\.html"', r'href="/site/sitemap/tmp/pool/index.html"'),
        (r'href="\.\.\/tmp\/pool\/index\.html"', r'href="/site/sitemap/tmp/pool/index.html"'),
        (r'href="\.\.\/pool\/index\.html"', r'href="/site/sitemap/tmp/pool/index.html"'),
        (r'href="\.\.\/\.\.\/pool\/index\.html"', r'href="/site/sitemap/tmp/pool/index.html"'),
        (r'href="tmp\/pool\/index\.html"', r'href="/site/sitemap/tmp/pool/index.html"'),
        (r'href="\.\/tmp\/pool\/index\.html"', r'href="/site/sitemap/tmp/pool/index.html"'),
        
        # Table link variations
        (r'href="\.\.\/\.\.\/\.\.\/\.\.\/table\/index\.html"', r'href="/site/sitemap/table/index.html"'),
        (r'href="\.\.\/\.\.\/\.\.\/table\/index\.html"', r'href="/site/sitemap/table/index.html"'),
        (r'href="\.\.\/\.\.\/table\/index\.html"', r'href="/site/sitemap/table/index.html"'),
        (r'href="\.\.\/table\/index\.html"', r'href="/site/sitemap/table/index.html"'),
        (r'href="table\/index\.html"', r'href="/site/sitemap/table/index.html"'),
        (r'href="\.\/table\/index\.html"', r'href="/site/sitemap/table/index.html"'),
        
        # Table dropdown links
        (r'href="\.\.\/\.\.\/\.\.\/table\/team\/index\.html"', r'href="/site/sitemap/table/team/index.html"'),
        (r'href="\.\.\/\.\.\/table\/team\/index\.html"', r'href="/site/sitemap/table/team/index.html"'),
        (r'href="\.\.\/table\/team\/index\.html"', r'href="/site/sitemap/table/team/index.html"'),
        (r'href="table\/team\/index\.html"', r'href="/site/sitemap/table/team/index.html"'),
        (r'href="team\/index\.html"', r'href="/site/sitemap/table/team/index.html"'),
        
        (r'href="\.\.\/\.\.\/\.\.\/table\/projectmanagement\/index\.html"', r'href="/site/sitemap/table/projectmanagement/index.html"'),
        (r'href="\.\.\/\.\.\/table\/projectmanagement\/index\.html"', r'href="/site/sitemap/table/projectmanagement/index.html"'),
        (r'href="\.\.\/table\/projectmanagement\/index\.html"', r'href="/site/sitemap/table/projectmanagement/index.html"'),
        (r'href="table\/projectmanagement\/index\.html"', r'href="/site/sitemap/table/projectmanagement/index.html"'),
        (r'href="projectmanagement\/index\.html"', r'href="/site/sitemap/table/projectmanagement/index.html"'),
    ]
    
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
    
    return content

def fix_dropdown_styles(content):
    """Ensure dropdown CSS styles are present and overflow is visible."""
    # Check if dropdown styles already exist
    if '.dropdown-content {' in content:
        # Fix overflow if it's hidden
        content = re.sub(
            r'(\.top-nav\s*{[^}]*overflow:\s*)hidden',
            r'\1visible',
            content
        )
        return content
    
    # Find where to insert dropdown styles (after .nav-item:last-child .nav-link)
    insert_pattern = r'(\.nav-item:last-child \.nav-link\s*{[^}]*}\s*)'
    
    dropdown_styles = """
        /* Dropdown Styles */
        .dropdown {
            position: relative;
        }
        
        .dropdown-content {
            display: none;
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            background: white;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            border-radius: 0 0 8px 8px;
            z-index: 1000;
            min-width: 200px;
        }
        
        .dropdown:hover .dropdown-content {
            display: block;
        }
        
        .dropdown-content a {
            display: block;
            padding: 12px 20px;
            text-decoration: none;
            color: #666;
            border-bottom: 1px solid #eee;
            transition: background 0.2s;
            white-space: nowrap;
        }
        
        .dropdown-content a:last-child {
            border-bottom: none;
        }
        
        .dropdown-content a:hover {
            background: #f8f9fa;
            color: #0066cc;
        }
        """
    
    # Try to insert after nav-item:last-child
    if re.search(insert_pattern, content):
        content = re.sub(insert_pattern, r'\1' + dropdown_styles, content)
    else:
        # If not found, try to insert before /* Step Header */ or similar
        alt_pattern = r'(\s*)(\/\*[^*]*(?:Step|Section|Main|Content)[^*]*\*\/)'
        if re.search(alt_pattern, content):
            content = re.sub(alt_pattern, dropdown_styles + r'\1\2', content, count=1)
    
    # Also fix overflow hidden to visible
    content = re.sub(
        r'(\.top-nav\s*{[^}]*overflow:\s*)hidden',
        r'\1visible',
        content
    )
    
    return content

def process_file(filepath):
    """Process a single HTML file to fix navigation issues."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Skip if file doesn't have navigation
        if 'nav-list' not in content:
            return False
        
        original_content = content
        
        # Fix navigation paths
        content = fix_navigation_paths(content)
        
        # Fix dropdown styles
        content = fix_dropdown_styles(content)
        
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
    sitemap_dir = Path("/Users/spitexbemeda/Documents/Bemeda Personal Page/docs/site/sitemap")
    
    # Find all HTML files
    html_files = list(sitemap_dir.rglob("*.html"))
    
    print(f"Found {len(html_files)} HTML files to process")
    
    updated_count = 0
    for filepath in html_files:
        if process_file(filepath):
            updated_count += 1
            print(f"Updated: {filepath.relative_to(sitemap_dir)}")
    
    print(f"\nCompleted! Updated {updated_count} files out of {len(html_files)} total files.")

if __name__ == "__main__":
    main()