# Setting Up Comments System

## Overview
Your documentation now includes a GitHub-based comments system using Utterances. It provides:
- **No database required**: Comments stored as GitHub issues
- **No login system**: Users authenticate with GitHub
- **Zero maintenance**: Fully managed by GitHub
- **Spam protection**: GitHub's built-in protections

## Setup Steps

### 1. Enable GitHub Issues
Make sure your GitHub repository has Issues enabled:
- Go to your repository on GitHub
- Click "Settings" tab
- Scroll to "Features" section
- Ensure "Issues" is checked

### 2. Install Utterances App
- Go to: https://github.com/apps/utterances
- Click "Install"
- Select your repository (`your-username/bemeda_personal`)

### 3. Update Repository Reference
Edit `/docs/index.html` and find this line (around line 859):
```javascript
script.setAttribute('repo', 'YOUR_GITHUB_USERNAME/bemeda_personal');
```

Replace with your actual GitHub details:
```javascript
script.setAttribute('repo', 'your-actual-username/your-actual-repo-name');
```

### 4. Deploy
Commit and push your changes:
```bash
git add docs/
git commit -m "Add comments system with utterances"
git push origin gh-pages
```

## Features

### Visual Design
- **Sidebar Layout**: Comments appear in a clean sidebar
- **Responsive**: On mobile, comments appear below content
- **Toggle Button**: Floating button to show/hide comments
- **Themed**: Matches your documentation design

### User Experience
- Comments are scoped per documentation page
- Each page gets its own GitHub issue
- Users can subscribe to notifications
- Full markdown support in comments
- Reactions and threading supported

### Issue Naming
Issues are created with format: `docs: [Page Title] - [file path]`
Example: `docs: Vision - strategic-foundation/vision.md`

## Customization Options

### Theme Options
Current theme: `github-light`
Other options: `github-dark`, `preferred-color-scheme`, `github-dark-orange`, etc.

### Issue Naming
Current format: `docs: ${title} - ${path}`
Can be changed in the `issue-term` attribute

## Privacy & Security
- No personal data stored on your servers
- GitHub handles all authentication
- Comments are public (linked to GitHub issues)
- Users need GitHub accounts to comment

## Maintenance
- Zero maintenance required
- Comments automatically appear
- Spam handled by GitHub's systems
- Can moderate via GitHub Issues interface

---

*The comments system is now ready! Just update the repository reference and deploy.*