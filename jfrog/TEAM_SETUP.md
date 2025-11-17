# JFrog Artifactory - Two Team Setup

This setup provides **isolated team workspaces** with a **shared collaboration area** using a **single URL** for both teams.

## 🏗️ Architecture

### Repository Structure
```
npm (Virtual) ← Single URL for everything
├── npm-shared-local (Local)
│   ├── @web-dev/**      ← Web team private packages
│   ├── @ios/**          ← iOS team private packages
│   └── @shared/**       ← Shared packages (both teams)
└── npmjs-remote (Remote) ← Cached public npm packages
```

### Teams
- **web-dev-team**: Uses `egg` GitHub repo, publishes to `@web-dev/*` scope
- **ios-team**: Uses `egg-ios` GitHub repo, publishes to `@ios/*` scope
- **managers**: Can manage both teams, add/remove users, and modify permissions
- **Shared**: Both teams can publish/consume `@shared/*` packages

---

## 📋 Setup Instructions

### 1️⃣ Admin Setup (One-time)

Run the setup script to create repositories, groups, and permissions:

```bash
cd /Users/johanna/src/haileysgarden/egg/jfrog
./setup-teams.sh https://trialghxmjl.jfrog.io <ADMIN_USER> <ADMIN_PASSWORD>
```

This creates:
- ✅ `npm-shared-local` repository
- ✅ Updated `npm` virtual repository
- ✅ `web-dev-team`, `ios-team`, and `managers` groups
- ✅ Permission targets with path-based isolation
- ✅ Manager permissions for full repository access

### 2️⃣ Add Users to Teams

**Via UI:**
1. Go to: `Admin → Security → Groups`
2. Click `web-dev-team` → Add developers
3. Click `ios-team` → Add developers
4. Click `managers` → Add managers

**Via REST API:**
```bash
# Add user to web-dev-team
curl -u admin:password -X POST \
  https://trialghxmjl.jfrog.io/artifactory/api/security/groups/web-dev-team \
  -H "Content-Type: application/json" \
  -d '{"name": "web-dev-team", "userNames": ["dev1", "dev2"]}'
```

### 3️⃣ Setup Manager Permissions

Grant a manager the ability to manage teams:

```bash
./setup-manager-admin.sh https://trialghxmjl.jfrog.io <AUTH_TOKEN> <MANAGER_USERNAME>
```

**Manager capabilities:**
- ✅ View all repositories
- ✅ Read/write/delete packages in all scopes
- ✅ Manage permissions for repositories
- ✅ Add/remove users from teams (via JFrog Projects or Platform Admin)

### 4️⃣ Developer Machine Setup

**Web Development Team:**
```bash
./team-setup-web-dev.sh
```

**iOS Team:**
```bash
./team-setup-ios.sh
```

Both scripts configure npm to use the single virtual repository URL:
```
https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/
```

---

## 🔐 Permissions & Isolation

### Web Team (`web-dev-team`)
- ✅ **Read/Write**: `@web-dev/**`, `@shared/**`
- ❌ **No Access**: `@ios/**`
- ✅ **Read**: Public packages from `npmjs-remote`

### iOS Team (`ios-team`)
- ✅ **Read/Write**: `@ios/**`, `@shared/**`
- ❌ **No Access**: `@web-dev/**`
- ✅ **Read**: Public packages from `npmjs-remote`

### Managers (`managers`)
- ✅ **Read/Write/Delete**: All scopes (`@web-dev/**`, `@ios/**`, `@shared/**`)
- ✅ **Manage**: Repository permissions
- ✅ **Read**: All repositories (`npm-shared-local`, `npmjs-remote`)
- ✅ **Admin**: Can add/remove users from teams (with proper setup)

---

## 📦 Publishing Packages

### Web Team Example

**package.json:**
```json
{
  "name": "@web-dev/auth-service",
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

### iOS Team Example

**package.json:**
```json
{
  "name": "@ios/native-bridge",
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
  "name": "@shared/api-types",
  "version": "1.0.0",
  "description": "Shared TypeScript types for API contracts",
  "publishConfig": {
    "registry": "https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/"
  }
}
```

Both teams can publish and consume `@shared/*` packages.

---

## 🔑 Authentication

### Option 1: Access Token (Recommended)

1. Generate token: `https://trialghxmjl.jfrog.io/ui/admin/artifactory/user_profile`
2. Configure npm:
```bash
npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<YOUR_TOKEN>
```

### Option 2: npm login

```bash
npm login --registry=https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/
```

---

## 🎯 Use Cases

### 1. Web Team Private Package
```bash
# Web team publishes internal component
cd packages/web-components
npm publish  # Goes to @web-dev/web-components
```

### 2. iOS Team Private Package
```bash
# iOS team publishes native utilities
cd packages/ios-utils
npm publish  # Goes to @ios/ios-utils
```

### 3. Shared Package (Both Teams)
```bash
# Either team publishes shared GraphQL schema
cd packages/graphql-schema
npm publish  # Goes to @shared/graphql-schema

# Both teams can install it
npm install @shared/graphql-schema
```

### 4. Public Package (Cached)
```bash
# Both teams can install public packages
npm install react  # Cached from npmjs-remote
```

---

## 👨‍💼 Manager Capabilities

Managers have full control over team repositories and can perform administrative tasks:

### What Managers Can Do

✅ **Repository Management:**
- View all packages in `npm-shared-local` (all scopes)
- Read, write, and delete packages in `@web-dev/**`, `@ios/**`, `@shared/**`
- Manage repository permissions

✅ **Team Management (with proper setup):**
- Add/remove users from `web-dev-team` and `ios-team`
- Modify team permissions
- View team activity and package usage

✅ **Package Operations:**
- Publish packages to any scope
- Delete old or incorrect packages
- Move packages between scopes if needed

### Granting Team Management Rights

**Option 1: JFrog Projects (Recommended)**

1. Create a Project: `Admin → Projects → New Project`
2. Name it: `DevTeams`
3. Add repositories: `npm`, `npm-shared-local`, `npmjs-remote`
4. Add groups: `web-dev-team`, `ios-team`, `managers`
5. Make manager a **Project Admin**
6. Manager can now add/remove users without full platform admin access

**Option 2: Platform Admin (Full Access)**

1. Go to: `Admin → Security → Users → [Manager Username]`
2. Check **Platform Admin**
3. Manager gets full admin rights (use cautiously)

**Option 3: IdP/SCIM Integration (Automated)**

Sync groups from Okta/Azure AD:
- Manager controls group membership in IdP
- JFrog auto-syncs `web-dev-team` and `ios-team` groups
- No manual user management needed in JFrog

---

## 🧹 Maintenance

### Cleanup Old Builds
```bash
# Delete packages older than 30 days (except @shared/*)
# Set up via: Admin → Artifactory → Cleanup Policies
```

### View Team Artifacts
```bash
# Web team artifacts
curl -u user:token https://trialghxmjl.jfrog.io/artifactory/api/storage/npm-shared-local/@web-dev

# iOS team artifacts
curl -u user:token https://trialghxmjl.jfrog.io/artifactory/api/storage/npm-shared-local/@ios

# Shared artifacts
curl -u user:token https://trialghxmjl.jfrog.io/artifactory/api/storage/npm-shared-local/@shared
```

---

## 📊 Summary

| Requirement | Solution |
|------------|----------|
| Single repository for artifacts | `npm-shared-local` with scope-based organization |
| Manager can add/remove users | JFrog Projects (Project Admin role) or IdP sync |
| Fetch from npmjs.org | `npmjs-remote` proxy with caching |
| Team isolation | Repository Path Permissions on scopes |
| Shared collaboration area | `@shared/*` scope accessible to both teams |
| Single URL | `npm` virtual repository for all operations |

**Single URL for everything:**
```
https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/
```
