# 🔧 Fix GitHub CLI Permissions

Your current token only has **read** permissions. To create issues and manage projects, you need **write** permissions.

## 🚀 Quick Fix Steps:

### Option 1: Create New Token with Full Permissions

1. **Go to:** https://github.com/settings/tokens/new

2. **Configure:**
   - **Note:** `Bemeda Platform CLI Access`
   - **Expiration:** 90 days (or your preference)
   
3. **Select ALL these scopes:**
   ```
   ✅ repo (Full control of private repositories)
       ✅ repo:status
       ✅ repo_deployment
       ✅ public_repo
       ✅ repo:invite
       ✅ security_events
   
   ✅ workflow (Update GitHub Action workflows)
   
   ✅ write:packages (Write packages to GitHub Package Registry)
       ✅ read:packages
   
   ✅ admin:org (Full control of orgs and teams)
       ✅ write:org
       ✅ read:org
   
   ✅ admin:public_key (Full control of user public keys)
       ✅ write:public_key
       ✅ read:public_key
   
   ✅ admin:repo_hook (Full control of repository hooks)
       ✅ write:repo_hook
       ✅ read:repo_hook
   
   ✅ admin:enterprise (Full control of enterprise)
   
   ✅ project (Full control of projects)
       ✅ read:project
   ```

4. **Click:** "Generate token"

5. **Copy the new token** (starts with `ghp_`)

6. **Update GitHub CLI:**
   ```bash
   # Logout first
   gh auth logout
   
   # Login with new token
   echo "YOUR_NEW_TOKEN_HERE" | gh auth login --with-token
   
   # Verify permissions
   gh auth status
   ```

### Option 2: Use GitHub App Instead (Better Security)

1. **Create GitHub App:** https://github.com/settings/apps/new
2. **Grant specific permissions** only for this project
3. **Install on your repo**
4. **Use app token** for CLI

### Option 3: Use Fine-grained Personal Access Token (Recommended)

1. **Go to:** https://github.com/settings/tokens?type=beta

2. **Click:** "Generate new token"

3. **Configure:**
   - **Token name:** `Bemeda Platform Full Access`
   - **Expiration:** 90 days
   - **Repository access:** Selected repositories → `3Stones-io/bemeda_personal`

4. **Repository permissions:**
   ```
   ✅ Actions: Read
   ✅ Administration: Write
   ✅ Checks: Write
   ✅ Codespaces: Write
   ✅ Contents: Write
   ✅ Deployments: Write
   ✅ Environments: Write
   ✅ Issues: Write
   ✅ Metadata: Read (mandatory)
   ✅ Pages: Write
   ✅ Pull requests: Write
   ✅ Repository security advisories: Write
   ✅ Webhooks: Write
   ```

5. **Account permissions:**
   ```
   ✅ Email addresses: Read
   ✅ Profile: Read
   ```

6. **Organization permissions:**
   ```
   ✅ Projects: Write
   ✅ Members: Read
   ```

7. **Generate and use token:**
   ```bash
   # Logout current session
   gh auth logout
   
   # Login with new token
   echo "github_pat_YOUR_NEW_TOKEN" | gh auth login --with-token
   
   # Test permissions
   gh issue create --title "Test Issue" --body "Testing permissions"
   ```

## 🧪 Test Your New Permissions:

```bash
# 1. Check auth status
gh auth status

# 2. Test issue creation
gh issue create --title "[TEST] Permission Check" --body "Testing write permissions" --label "platform"

# 3. Test project access
gh project list --owner 3Stones-io

# 4. If all works, delete test issue
gh issue list --limit 1
gh issue delete [ISSUE_NUMBER] --yes
```

## 🎯 After Fixing Permissions:

Run our automated issue creation script:
```bash
./docs/github/create-all-issues.sh
```

This will create all 18 component issues automatically!