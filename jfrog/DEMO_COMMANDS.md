# JFrog Demo - Working Commands

## 🚀 Step-by-Step Demo Commands

### Step 1: Publish Team A Package

```bash
# Navigate to team-a-service package
cd /Users/johanna/src/haileysgarden/egg/packages/team-a-service

# Publish as Team A member (or as manager)
npm publish
```

**Expected Output:**
```
npm notice Publishing to https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/
+ @team-a/my-service@1.0.0
```

**What happens:**
- Package is stored in `npm-shared-local/@team-a/my-service`
- Only Team A members and managers can access it

---

### Step 2: Install Team A Package (As Team A Member)

```bash
# Create a test directory
mkdir -p /tmp/team-a-test
cd /tmp/team-a-test

# Initialize npm project
npm init -y

# Configure registry (if not already done)
npm config set registry https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/

# Install the package
npm install @team-a/my-service
```

**Expected Output:**
```
added 1 package in 2s
```

**Test it works:**
```bash
node -e "const svc = require('@team-a/my-service'); console.log(svc.greet('Demo'));"
```

**Expected Output:**
```
Hello from Team A Service, Demo!
```

---

### Step 3: Try to Install as Team B Member (Should Fail)

```bash
# Login as Team B member (user-ios1 or user-ios2)
# Set their auth token
npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<TEAM_B_USER_TOKEN>

# Try to install Team A package
npm install @team-a/my-service
```

**Expected Output (Failure - This is correct!):**
```
npm ERR! code E403
npm ERR! 403 Forbidden - GET https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/@team-a%2fmy-service
npm ERR! 403 Forbidden: @team-a/my-service@latest
```

**This proves isolation is working!** ✅

---

### Step 4: Install Shared Package (Works for Both Teams)

```bash
# Navigate to shared package
cd /Users/johanna/src/haileysgarden/egg/packages/common-utils

# Build and publish
npm run build
npm publish
```

**Expected Output:**
```
+ @shared/common-utils@1.0.0
```

**Install as Team A:**
```bash
cd /tmp/team-a-test
npm install @shared/common-utils
```

**Expected Output:**
```
added 1 package in 2s
```

**Install as Team B:**
```bash
cd /tmp/team-b-test
npm install @shared/common-utils
```

**Expected Output:**
```
added 1 package in 2s
```

**Both teams can access shared packages!** ✅

---

## 📋 Quick Reference Commands

### Publish Package
```bash
# Team A package
cd packages/team-a-service
npm publish

# Team B package
cd packages/team-b-component
npm publish

# Shared package
cd packages/common-utils
npm publish
```

### Install Package
```bash
# Install Team A package (only works for Team A + managers)
npm install @team-a/my-service

# Install Team B package (only works for Team B + managers)
npm install @team-b/my-component

# Install shared package (works for everyone)
npm install @shared/common-utils

# Install public package (works for everyone)
npm install lodash
```

### View Published Packages
```bash
# Via API - Team A packages
curl -H "Authorization: Bearer <TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/storage/npm-shared-local/@team-a

# Via API - Team B packages
curl -H "Authorization: Bearer <TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/storage/npm-shared-local/@team-b

# Via API - Shared packages
curl -H "Authorization: Bearer <TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/storage/npm-shared-local/@shared
```

---

## 🎯 Complete Demo Script

### Setup (One-time)

```bash
# 1. Run setup script to create groups and permissions
cd /Users/johanna/src/haileysgarden/egg/jfrog
./setup-teams.sh https://trialghxmjl.jfrog.io <AUTH_TOKEN>

# 2. Configure npm registry
npm config set registry https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/
npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<YOUR_TOKEN>
```

### Demo Flow

```bash
# 1. Publish Team A package
cd /Users/johanna/src/haileysgarden/egg/packages/team-a-service
npm publish

# 2. Install as Team A (works)
cd /tmp/demo-team-a
npm init -y
npm install @team-a/my-service
node -e "console.log(require('@team-a/my-service').getTeamInfo())"

# 3. Try to install as Team B (fails - shows isolation)
# Switch to Team B token
npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<TEAM_B_TOKEN>
npm install @team-a/my-service  # Gets 403 Forbidden ✅

# 4. Publish and install shared package (works for both)
cd /Users/johanna/src/haileysgarden/egg/packages/common-utils
npm run build
npm publish

# Both teams can install
npm install @shared/common-utils  # Works! ✅
```

---

## 🧪 Testing Checklist

- [ ] **Team A publishes** `@team-a/my-service` - Success
- [ ] **Team A installs** `@team-a/my-service` - Success
- [ ] **Team B installs** `@team-a/my-service` - 403 Forbidden (Expected!)
- [ ] **Team B publishes** `@team-b/my-component` - Success
- [ ] **Team B installs** `@team-b/my-component` - Success
- [ ] **Team A installs** `@team-b/my-component` - 403 Forbidden (Expected!)
- [ ] **Team A publishes** `@shared/common-utils` - Success
- [ ] **Team A installs** `@shared/common-utils` - Success
- [ ] **Team B installs** `@shared/common-utils` - Success
- [ ] **Both teams install** `lodash` (public) - Success

---

## 🔑 User Tokens

Generate tokens for each user:

1. Log in to JFrog as each user
2. Go to: User Profile → Generate Token
3. Copy the token
4. Set in npm config:
   ```bash
   npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<TOKEN>
   ```

**Users:**
- `user-webdev1` (Team A)
- `user-webdev2` (Team A)
- `user-ios1` (Team B)
- `user-ios2` (Team B)
- `johanna@haileysgarden.com` (Manager - can access all)

---

## 📊 Expected Results Matrix

| Action | Team A | Team B | Manager |
|--------|--------|--------|---------|
| Publish to @team-a/* | ✅ | ❌ | ✅ |
| Install from @team-a/* | ✅ | ❌ | ✅ |
| Publish to @team-b/* | ❌ | ✅ | ✅ |
| Install from @team-b/* | ❌ | ✅ | ✅ |
| Publish to @shared/* | ✅ | ✅ | ✅ |
| Install from @shared/* | ✅ | ✅ | ✅ |
| Install public packages | ✅ | ✅ | ✅ |

---

## 🎬 Live Demo One-Liner

```bash
# Complete demo in one command block
cd /Users/johanna/src/haileysgarden/egg/packages/team-a-service && \
npm publish && \
echo "✅ Published @team-a/my-service" && \
cd /tmp && mkdir -p demo-test && cd demo-test && \
npm init -y && \
npm install @team-a/my-service && \
echo "✅ Installed successfully" && \
node -e "console.log(require('@team-a/my-service').getTeamInfo())"
```

This will:
1. Publish the Team A package
2. Create a test directory
3. Install the package
4. Run it to show it works

**Expected final output:**
```json
{
  team: 'team-a',
  service: 'my-service',
  version: '1.0.0',
  description: 'This package is only accessible to Team A members'
}
```
