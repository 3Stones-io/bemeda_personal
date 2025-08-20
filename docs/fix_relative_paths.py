#!/usr/bin/env python3
"""
Fix incorrect relative paths in site navigation
"""
import os
import re
from pathlib import Path

def get_correct_relative_path(from_file, to_file):
    """Calculate the correct relative path between two files"""
    # Convert to Path objects relative to docs directory
    docs_dir = Path('/Users/denis/Documents/bemeda_personal/docs')
    from_path = Path(from_file).relative_to(docs_dir)
    
    # For navigation within site/sitemap, we need to calculate correctly
    from_parts = from_path.parts
    
    # Count how many directories deep we are in site/sitemap
    if 'site' in from_parts and 'sitemap' in from_parts:
        # Find index of 'sitemap'
        sitemap_idx = from_parts.index('sitemap')
        # Count directories after sitemap (excluding the file itself)
        # We subtract 1 for the filename
        depth_after_sitemap = len(from_parts) - sitemap_idx - 2
        
        # For navigating to other sections in sitemap, calculate the number of ../ needed
        # Each directory level needs one ../
        if depth_after_sitemap == 0:
            # We're at sitemap/section/index.html level (e.g., sitemap/job/index.html)
            # Need to go up 1 level to sitemap/
            return "../"
        elif depth_after_sitemap == 1:
            # We're at sitemap/section/s1/index.html level (e.g., sitemap/job/s1/index.html)
            # Need to go up 2 levels to sitemap/
            return "../../"
        elif depth_after_sitemap == 2:
            # We're at sitemap/section/s1/p1/index.html level (e.g., sitemap/job/s1/p1/index.html)
            # Need to go up 3 levels to sitemap/
            return "../../../"
        elif depth_after_sitemap == 3:
            # We're at sitemap/section/s1/p1/p2/index.html level
            # Need to go up 4 levels to sitemap/
            return "../../../../"
        else:
            # Handle any deeper levels
            return "../" * (depth_after_sitemap + 1)
    
    return ""

def fix_navigation_links(filepath):
    """Fix navigation links in a single HTML file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except:
        return False
    
    # Get relative path from docs directory
    rel_path = os.path.relpath(filepath, '/Users/denis/Documents/bemeda_personal/docs')
    
    # Skip if not in site/sitemap
    if not rel_path.startswith('site/sitemap/'):
        return False
    
    # Calculate the correct prefix for this file
    prefix = get_correct_relative_path(filepath, "")
    
    # Fix patterns - these are the navigation links that need to be corrected
    replacements = [
        # Fix links to other sitemap sections
        (r'href="[\.\/]*site/sitemap/job/index\.html"', f'href="{prefix}job/index.html"'),
        (r'href="[\.\/]*site/sitemap/tmp/index\.html"', f'href="{prefix}tmp/index.html"'),
        (r'href="[\.\/]*site/sitemap/table/index\.html"', f'href="{prefix}table/index.html"'),
        (r'href="[\.\/]*site/sitemap/admin/index\.html"', f'href="{prefix}admin/index.html"'),
        
        # Fix dropdown links
        (r'href="[\.\/]*site/sitemap/tmp/temporary/index\.html"', f'href="{prefix}tmp/temporary/index.html"'),
        (r'href="[\.\/]*site/sitemap/tmp/tryhire/index\.html"', f'href="{prefix}tmp/tryhire/index.html"'),
        (r'href="[\.\/]*site/sitemap/tmp/pool/index\.html"', f'href="{prefix}tmp/pool/index.html"'),
        
        # Fix admin dropdown links
        (r'href="[\.\/]*site/sitemap/admin/s1/index\.html"', f'href="{prefix}admin/s1/index.html"'),
        (r'href="[\.\/]*site/sitemap/admin/s2/index\.html"', f'href="{prefix}admin/s2/index.html"'),
        (r'href="[\.\/]*site/sitemap/admin/s3/index\.html"', f'href="{prefix}admin/s3/index.html"'),
        (r'href="[\.\/]*site/sitemap/admin/s4/index\.html"', f'href="{prefix}admin/s4/index.html"'),
        
        # Fix back to index link (should go to root)
        (r'href="[\.\/]+index\.html"(.+?nav\.index)', f'href="{prefix}../../../index.html"\\1'),
    ]
    
    modified = False
    for pattern, replacement in replacements:
        new_content = re.sub(pattern, replacement, content)
        if new_content != content:
            modified = True
            content = new_content
    
    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed navigation in: {rel_path}")
        print(f"  Using prefix: {prefix}")
        return True
    return False

def main():
    docs_dir = '/Users/denis/Documents/bemeda_personal/docs'
    fixed_count = 0
    
    # Walk through all HTML files in site/sitemap
    for root, dirs, files in os.walk(os.path.join(docs_dir, 'site', 'sitemap')):
        for file in files:
            if file.endswith('.html'):
                filepath = os.path.join(root, file)
                if fix_navigation_links(filepath):
                    fixed_count += 1
    
    print(f"\nTotal files fixed: {fixed_count}")

if __name__ == "__main__":
    main()