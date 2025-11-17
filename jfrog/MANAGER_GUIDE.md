# Manager Quick Reference Guide

This guide is for managers who need to add/remove users from teams and manage permissions.

## 🎯 Your Responsibilities

As a manager, you can:
- ✅ Add/remove developers from `web-dev-team` and `ios-team`
- ✅ View all packages across all scopes
- ✅ Manage repository permissions
- ✅ Delete or move packages when needed
- ✅ Monitor team activity and package usage

---

## 👥 Managing Team Members

### Add User to a Team

**Via JFrog UI:**
1. Log in to: `https://trialghxmjl.jfrog.io`
2. Go to: `Admin → Security → Groups`
3. Click on the team group (`web-dev-team` or `ios-team`)
4. Click **Add Users**
5. Select users and click **Save**

**Via REST API:**
```bash
# Add user to web-dev-team
curl -H "Authorization: Bearer <YOUR_TOKEN>" -X POST \
  https://trialghxmjl.jfrog.io/artifactory/api/security/groups/web-dev-team \
  -H "Content-Type: application/json" \
  -d '{
    "name": "web-dev-team",
    "userNames": ["existing-user1", "existing-user2", "new-user"]
  }'
```

### Remove User from a Team

**Via JFrog UI:**
1. Go to: `Admin → Security → Groups`
2. Click on the team group
3. Find the user in the members list
4. Click the **X** next to their name
5. Click **Save**

**Via REST API:**
```bash
# Remove user from ios-team (update with remaining users only)
curl -H "Authorization: Bearer <YOUR_TOKEN>" -X POST \
  https://trialghxmjl.jfrog.io/artifactory/api/security/groups/ios-team \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ios-team",
    "userNames": ["user1", "user2"]
  }'
```

---

## 📦 Managing Packages

### View Team Packages

**Web Team Packages:**
```bash
curl -H "Authorization: Bearer <YOUR_TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/storage/npm-shared-local/@web-dev
```

**iOS Team Packages:**
```bash
curl -H "Authorization: Bearer <YOUR_TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/storage/npm-shared-local/@ios
```

**Shared Packages:**
```bash
curl -H "Authorization: Bearer <YOUR_TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/storage/npm-shared-local/@shared
```

### Delete a Package

**Via JFrog UI:**
1. Go to: `Artifactory → Artifacts`
2. Navigate to: `npm-shared-local → @scope → package-name`
3. Right-click → **Delete**
4. Confirm deletion

**Via REST API:**
```bash
# Delete a specific version
curl -H "Authorization: Bearer <YOUR_TOKEN>" -X DELETE \
  https://trialghxmjl.jfrog.io/artifactory/npm-shared-local/@web-dev/package-name/-/package-name-1.0.0.tgz
```

### Move Package Between Scopes

1. Download the package:
   ```bash
   npm pack @web-dev/my-package
   ```

2. Update `package.json` to new scope:
   ```json
   {
     "name": "@shared/my-package"
   }
   ```

3. Publish to new scope:
   ```bash
   npm publish
   ```

4. Delete old package from original scope

---

## 🔐 Managing Permissions

### View Current Permissions

**Via JFrog UI:**
1. Go to: `Admin → Security → Permissions`
2. View `perm-web-dev`, `perm-ios`, or `perm-manager`

### Modify Team Permissions

**Via REST API:**
```bash
# Update web-dev-team permissions
curl -H "Authorization: Bearer <YOUR_TOKEN>" -X PUT \
  https://trialghxmjl.jfrog.io/artifactory/api/v2/security/permissions/perm-web-dev \
  -H "Content-Type: application/json" \
  -d @permissions/perm-web-dev.json
```

---

## 📊 Monitoring & Reports

### View Team Activity

**Via JFrog UI:**
1. Go to: `Application → Artifactory → Artifacts`
2. Filter by repository: `npm-shared-local`
3. Use search to filter by scope: `@web-dev` or `@ios`

### Generate Usage Reports

**Via JFrog UI:**
1. Go to: `Application → Reports`
2. Create custom report for:
   - Repository: `npm-shared-local`
   - Date range: Last 30 days
   - Filter by scope

---

## 🚨 Common Tasks

### Onboard New Developer

1. **Create user account** (if not exists):
   - `Admin → Security → Users → New User`

2. **Add to appropriate team**:
   - Web developer → `web-dev-team`
   - iOS developer → `ios-team`

3. **Send setup instructions**:
   - Web team: Share `team-setup-web-dev.sh`
   - iOS team: Share `team-setup-ios.sh`

4. **Generate access token** for the user:
   - User logs in → Profile → Generate Token

### Offboard Developer

1. **Remove from team group**:
   - `Admin → Security → Groups → [Team] → Remove User`

2. **Revoke access tokens**:
   - `Admin → Security → Users → [User] → Access Tokens → Revoke All`

3. **Optional: Disable account**:
   - `Admin → Security → Users → [User] → Disable`

### Handle Package Conflicts

If two teams accidentally publish to the same package name:

1. **Identify the conflict**:
   - Check package metadata and publisher

2. **Contact team leads**:
   - Determine which team should own the package

3. **Resolve**:
   - Option A: One team renames their package
   - Option B: Move to `@shared/*` if both teams need it
   - Option C: Delete incorrect version

---

## 🆘 Getting Help

### Support Contacts

- **JFrog Documentation**: https://jfrog.com/help/
- **Platform Admin**: [Your admin contact]
- **Team Leads**:
  - Web Team: [Lead contact]
  - iOS Team: [Lead contact]

### Useful Links

- **JFrog UI**: https://trialghxmjl.jfrog.io
- **npm Registry**: https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/
- **Setup Documentation**: See `TEAM_SETUP.md`

---

## 📝 Quick Commands

```bash
# List all groups
curl -H "Authorization: Bearer <TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/security/groups

# Get group details
curl -H "Authorization: Bearer <TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/security/groups/web-dev-team

# List all users
curl -H "Authorization: Bearer <TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/security/users

# Get user details
curl -H "Authorization: Bearer <TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/security/users/username

# Search packages
curl -H "Authorization: Bearer <TOKEN>" \
  "https://trialghxmjl.jfrog.io/artifactory/api/search/artifact?name=*&repos=npm-shared-local"
```
