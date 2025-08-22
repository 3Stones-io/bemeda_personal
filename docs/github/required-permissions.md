# ✅ Required GitHub Token Permissions

For the Bemeda Platform project, you need these **specific permissions**:

## 🎯 Essential Permissions (Select These):

```
✅ repo                    - Full control of private repositories (REQUIRED)
   ✅ repo:status         - Access commit status
   ✅ repo_deployment     - Access deployment status  
   ✅ public_repo         - Access public repositories
   ✅ repo:invite         - Access repository invitations
   
✅ workflow                - Update GitHub Action workflows

✅ write:org               - Read and write org and team membership, org projects
   
✅ project                 - Full control of projects (REQUIRED)
   ✅ read:project        - Read access of projects

✅ user                    - Update ALL user data
   ✅ read:user           - Read ALL user profile data
```

## 🚀 Quick Setup:

1. **Go to:** https://github.com/settings/tokens/new

2. **Token Settings:**
   - **Note:** `Bemeda Platform Full Access`
   - **Expiration:** 90 days (recommended)

3. **Select Scopes:**
   ```
   ✅ repo (this will auto-select all sub-permissions)
   ✅ workflow  
   ✅ write:org
   ✅ project
   ✅ user
   ```

4. **Click:** "Generate token"

5. **Copy** the token (starts with `ghp_`)

6. **Update GitHub CLI:**
   ```bash
   # Logout current session
   gh auth logout
   
   # Login with new token
   echo "ghp_YOUR_NEW_TOKEN_HERE" | gh auth login --with-token
   
   # Verify it worked
   gh auth status
   ```

## 🧪 Test Your Permissions:

```bash
# Test 1: Create a test issue
gh issue create --title "[TEST] Permission Check" --body "Testing permissions" --label "platform"

# Test 2: List projects  
gh project list --owner 3Stones-io

# Test 3: View your user info
gh api user

# If all tests pass, delete the test issue
gh issue list --limit 1
# Note the issue number, then:
gh issue close [NUMBER]
```

## ✨ After Setup:

Run the automated issue creation:
```bash
./docs/github/create-all-issues.sh
```

This will create all 18 platform components automatically!

## 📝 Notes:

- **repo** permission is essential for creating/managing issues
- **project** permission is needed to manage GitHub Projects
- **write:org** allows project operations at organization level
- **workflow** enables future GitHub Actions automation
- **user** ensures proper authentication and assignee operations

## 🔒 Security Tips:

1. Set expiration to 90 days
2. Store token in password manager
3. Revoke old tokens after creating new one
4. Use minimum required permissions only
5. Consider using GitHub App for production