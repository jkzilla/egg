# Current JFrog Setup Status

## ✅ Groups Created

### team-a
- **Description**: Team A developers in egg project
- **Members**:
  - user-webdev1
  - user-webdev2
- **Status**: ✅ Created

### team-b
- **Description**: Team B developers in egg project
- **Members**:
  - user-ios1
  - user-ios2
- **Status**: ✅ Created

### managers
- **Description**: Team managers who can add/remove users and modify permissions
- **Members**:
  - johanna@haileysgarden.com
- **Status**: ✅ Created

---

## 👥 All Users in JFrog

| Username | Type | Assigned Group |
|----------|------|----------------|
| johanna@haileysgarden.com | Admin/Manager | managers |
| user-webdev1 | Developer | team-a |
| user-webdev2 | Developer | team-a |
| user-ios1 | Developer | team-b |
| user-ios2 | Developer | team-b |
| trialadmin | System Admin | - |
| anonymous | Anonymous | - |

---

## 📦 Repository Mapping

### Team A (user-webdev1, user-webdev2)
- **Can access**: `@team-a/**`, `@shared/**`
- **Cannot access**: `@team-b/**`
- **Example packages**:
  - `@team-a/auth-service`
  - `@team-a/api-gateway`
  - `@shared/common-utils` ✅

### Team B (user-ios1, user-ios2)
- **Can access**: `@team-b/**`, `@shared/**`
- **Cannot access**: `@team-a/**`
- **Example packages**:
  - `@team-b/mobile-app`
  - `@team-b/native-bridge`
  - `@shared/common-utils` ✅

### Managers (johanna@haileysgarden.com)
- **Can access**: All scopes (`@team-a/**`, `@team-b/**`, `@shared/**`)
- **Can manage**: Users, permissions, packages

---

## 🔄 Next Steps

### 1. Create Permission Targets

Run the permission creation commands:

```bash
cd /Users/johanna/src/haileysgarden/egg/jfrog

# Create team-a permissions
curl -H "Authorization: Bearer <TOKEN>" -X PUT \
  -H "Content-Type: application/json" \
  https://trialghxmjl.jfrog.io/artifactory/api/v2/security/permissions/perm-team-a \
  -d @permissions/perm-team-a.json

# Create team-b permissions
curl -H "Authorization: Bearer <TOKEN>" -X PUT \
  -H "Content-Type: application/json" \
  https://trialghxmjl.jfrog.io/artifactory/api/v2/security/permissions/perm-team-b \
  -d @permissions/perm-team-b.json

# Create manager permissions
curl -H "Authorization: Bearer <TOKEN>" -X PUT \
  -H "Content-Type: application/json" \
  https://trialghxmjl.jfrog.io/artifactory/api/v2/security/permissions/perm-manager \
  -d @permissions/perm-manager.json
```

Or run the full setup script:
```bash
./setup-teams.sh https://trialghxmjl.jfrog.io <AUTH_TOKEN>
```

### 2. Configure Developer Machines

Each developer should run:

**Team A (user-webdev1, user-webdev2):**
```bash
npm config set registry https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/
npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<THEIR_TOKEN>
```

**Team B (user-ios1, user-ios2):**
```bash
npm config set registry https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/
npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<THEIR_TOKEN>
```

### 3. Test Isolation

**Team A publishes:**
```bash
# As user-webdev1 or user-webdev2
cd my-package
npm publish  # Should go to @team-a/*
```

**Team B tries to access:**
```bash
# As user-ios1 or user-ios2
npm install @team-a/my-package  # Should get 403 Forbidden ✅
```

**Both teams access shared:**
```bash
# Both teams
npm install @shared/common-utils  # Should work for both ✅
```

---

## 🎯 Demo Scenario

### Scenario 1: Team A Publishes Private Package
```bash
# user-webdev1 logs in
npm login --registry=https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/

# Publishes to @team-a scope
cd packages/team-a-service
npm publish

# Result: Package stored in npm-shared-local/@team-a/team-a-service
```

### Scenario 2: Team B Cannot Access Team A Package
```bash
# user-ios1 logs in
npm login --registry=https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/

# Tries to install Team A package
npm install @team-a/team-a-service

# Result: 403 Forbidden - Isolation working! ✅
```

### Scenario 3: Both Teams Use Shared Package
```bash
# Team A publishes shared utility
cd packages/common-utils
npm publish  # Goes to @shared/common-utils

# Team B installs it
npm install @shared/common-utils  # ✅ Works!

# Team A also installs it
npm install @shared/common-utils  # ✅ Works!
```

### Scenario 4: Manager Manages Users
```bash
# johanna@haileysgarden.com logs into JFrog UI
# Goes to: https://trialghxmjl.jfrog.io/ui/admin/projects/members?projectKey=egg

# Adds new developer to team-a
# Removes developer from team-b
# Views all packages across all scopes
```

---

## 📊 Verification Checklist

- [x] **Groups Created**: team-a, team-b, managers
- [x] **Users Assigned**: All 4 developers + 1 manager
- [ ] **Permissions Created**: Need to run setup script
- [ ] **Repositories Configured**: npm-shared-local, npm virtual, npmjs-remote
- [x] **Shared Package Ready**: @shared/common-utils configured
- [ ] **Isolation Tested**: Need to test after permissions are created

---

## 🔗 Quick Links

- **JFrog UI**: https://trialghxmjl.jfrog.io
- **Project Members**: https://trialghxmjl.jfrog.io/ui/admin/projects/members?projectKey=egg
- **npm Registry**: https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/

---

## 📝 Notes

- Old groups (web-dev-team, ios-team, web-dev) still exist but are not used
- Can be cleaned up after new setup is verified
- All users are in the "internal" realm
- Manager (johanna@haileysgarden.com) needs Project Admin role for full user management
