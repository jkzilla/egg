# JFrog Artifactory - Egg Project with Two Teams

Setup for the egg project with two isolated teams sharing a single npm repository with scope-based permissions.

## 🏗️ Architecture

### Repository Structure
```
npm (Virtual) ← Single URL for everything
├── npm-shared-local (Local)
│   ├── @team-a/**      ← Team A private packages
│   ├── @team-b/**      ← Team B private packages
│   └── @shared/**      ← Shared packages (both teams)
└── npmjs-remote (Remote) ← Cached public npm packages
```

### Team Structure
- **team-a**: First development team with isolated scope
- **team-b**: Second development team with isolated scope
- **managers**: Project managers with full access to all scopes

### Project
- **Project Key**: `egg`
- **Project URL**: https://trialghxmjl.jfrog.io/ui/admin/projects/members?projectKey=egg

---

## 📋 Setup Instructions

### 1️⃣ Run Setup Script

```bash
cd /Users/johanna/src/haileysgarden/egg/jfrog
./setup-teams.sh https://trialghxmjl.jfrog.io <AUTH_TOKEN>
```

This creates:
- ✅ `npm-shared-local` repository
- ✅ `npm` virtual repository
- ✅ `team-a` group
- ✅ `team-b` group
- ✅ `managers` group
- ✅ Permission targets with scope-based isolation

### 2️⃣ Add Users to Teams

**Via JFrog UI:**
1. Go to: https://trialghxmjl.jfrog.io/ui/admin/projects/members?projectKey=egg
2. Add users to groups:
   - **Team A members** → Add to `team-a` group
   - **Team B members** → Add to `team-b` group
   - **Managers** → Add to `managers` group

### 3️⃣ Configure Developer Machines

All developers use the same registry:

```bash
# Set registry
npm config set registry https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/

# Set auth token (each developer gets their own)
npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<YOUR_TOKEN>
```

---

## 🔐 Permissions & Isolation

### Team A (`team-a`)
- ✅ **Read/Write**: `@team-a/**`, `@shared/**`
- ❌ **No Access**: `@team-b/**`
- ✅ **Read**: Public packages from `npmjs-remote`

### Team B (`team-b`)
- ✅ **Read/Write**: `@team-b/**`, `@shared/**`
- ❌ **No Access**: `@team-a/**`
- ✅ **Read**: Public packages from `npmjs-remote`

### Managers (`managers`)
- ✅ **Full Access**: All scopes (`@team-a/**`, `@team-b/**`, `@shared/**`)
- ✅ **Manage**: Permissions and user access
- ✅ **Admin**: Can add/remove users from teams

---

## 📦 Publishing Packages

### Team A Example

**package.json:**
```json
{
  "name": "@team-a/my-service",
  "version": "1.0.0",
  "publishConfig": {
    "registry": "https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/"
  }
}
```

**Publish:**
```bash
npm publish
```

### Team B Example

**package.json:**
```json
{
  "name": "@team-b/my-component",
  "version": "1.0.0",
  "publishConfig": {
    "registry": "https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/"
  }
}
```

**Publish:**
```bash
npm publish
```

### Shared Package Example

**package.json:**
```json
{
  "name": "@shared/common-utils",
  "version": "1.0.0",
  "description": "Utilities shared between Team A and Team B",
  "publishConfig": {
    "registry": "https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/"
  }
}
```

Both teams can publish and consume `@shared/*` packages.

---

## 🎯 Use Cases

### 1. Team A Private Package
```bash
# Team A publishes internal service
cd packages/team-a-service
npm publish  # Goes to @team-a/team-a-service
```

### 2. Team B Private Package
```bash
# Team B publishes internal component
cd packages/team-b-component
npm publish  # Goes to @team-b/team-b-component
```

### 3. Shared Package (Both Teams)
```bash
# Either team publishes shared utilities
cd packages/shared-utils
npm publish  # Goes to @shared/shared-utils

# Both teams can install it
npm install @shared/shared-utils
```

### 4. Public Package (Cached)
```bash
# Both teams can install public packages
npm install react  # Cached from npmjs-remote
```

---

## 👨‍💼 Manager Capabilities

Managers can:
- ✅ View all packages in all scopes
- ✅ Add/remove users from team-a and team-b groups
- ✅ Publish/delete packages in any scope
- ✅ Manage repository permissions
- ✅ Monitor team activity

**To grant manager permissions:**
```bash
./setup-manager-admin.sh https://trialghxmjl.jfrog.io <AUTH_TOKEN> <MANAGER_USERNAME>
```

---

## 🔑 Authentication

### For Developers

```bash
# Configure npm
npm config set registry https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/

# Add your personal access token
npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<YOUR_TOKEN>
```

**To get your token:**
1. Log in to: https://trialghxmjl.jfrog.io
2. Go to: User Profile → Generate Token
3. Copy and use the token

---

## 🆘 Troubleshooting

### Cannot Access Team B Packages (Team A member)

**Error:** `403 Forbidden` when trying to install `@team-b/*` package

**Expected Behavior:** This is correct! Team A cannot access Team B's private packages.

**Solution:** If the package should be shared, republish it under `@shared/*` scope.

### Cannot Publish to @shared

**Error:** `403 Forbidden` when publishing to `@shared/*`

**Solution:** Both teams have write access to `@shared/*`. Check:
1. You're authenticated with a valid token
2. You're in either `team-a` or `team-b` group
3. Package name starts with `@shared/`

### Package Conflict

**Error:** Package already exists with different scope

**Solution:**
1. Check which team owns the package
2. Either:
   - Rename your package
   - Move to `@shared/*` if both teams need it
   - Contact manager to resolve

---

## 📊 Summary

| Requirement | Solution |
|------------|----------|
| Single repository | `npm-shared-local` with scope-based organization |
| Two isolated teams | `team-a` and `team-b` groups with path permissions |
| Shared collaboration | `@shared/*` scope accessible to both teams |
| Manager can manage users | `managers` group with full permissions |
| Single URL | `npm` virtual repository for all operations |
| Fetch from npmjs.org | `npmjs-remote` proxy with caching |

**Single URL for everything:**
```
https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/
```

**Project Management:**
```
https://trialghxmjl.jfrog.io/ui/admin/projects/members?projectKey=egg
```
