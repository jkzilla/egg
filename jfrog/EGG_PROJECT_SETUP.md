# JFrog Artifactory - Egg Project Setup

Single project setup with two backend developers using a shared npm repository.

## 🏗️ Architecture

### Repository Structure
```
npm (Virtual) ← Single URL for everything
├── npm-shared-local (Local)
│   └── All packages for egg project
└── npmjs-remote (Remote) ← Cached public npm packages
```

### Team Structure
- **dev-backend**: Backend developers (web-dev-backend1, web-dev-backend2)
- **managers**: Project managers with full access

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
- ✅ `dev-backend` group with web-dev-backend1 and web-dev-backend2
- ✅ `managers` group
- ✅ Permission targets for both groups

### 2️⃣ Add Users to Egg Project

**Via JFrog UI:**
1. Go to: https://trialghxmjl.jfrog.io/ui/admin/projects/members?projectKey=egg
2. Add users to the egg project:
   - **web-dev-backend1** → Add to `dev-backend` group
   - **web-dev-backend2** → Add to `dev-backend` group
   - **Manager users** → Add to `managers` group

### 3️⃣ Configure Developer Machines

Both backend developers should run:

```bash
# Set registry
npm config set registry https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/

# Set auth token
npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<YOUR_TOKEN>
```

**To get your token:**
1. Log in to: https://trialghxmjl.jfrog.io
2. Go to: User Profile → Generate Token
3. Copy the token

---

## 🔐 Permissions

### Backend Developers (`dev-backend`)
- ✅ **Read/Write/Delete**: All packages in `npm-shared-local`
- ✅ **Read**: Public packages from `npmjs-remote`
- ✅ **Publish**: Any npm package to the shared repository

### Managers (`managers`)
- ✅ **Full Access**: All repositories and packages
- ✅ **Manage**: Permissions and user access
- ✅ **Admin**: Can add/remove users from groups

---

## 📦 Publishing Packages

### Example package.json

```json
{
  "name": "@egg/my-package",
  "version": "1.0.0",
  "publishConfig": {
    "registry": "https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/"
  }
}
```

### Publish

```bash
npm run build
npm publish
```

The package will be stored in `npm-shared-local` and available to both backend developers.

---

## 👥 Team Members

### Backend Developers
- **web-dev-backend1**: Full access to npm-shared-local
- **web-dev-backend2**: Full access to npm-shared-local

### Managers
- Full administrative access
- Can add/remove users
- Can manage permissions

---

## 🔑 Authentication

### For Developers

```bash
# Configure npm
npm config set registry https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/

# Add your personal access token
npm set //trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=<YOUR_TOKEN>
```

### For CI/CD

Add to `.npmrc` in your project:

```
registry=https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/
//trialghxmjl.jfrog.io/artifactory/api/npm/npm/:_authToken=${NPM_TOKEN}
```

Then set `NPM_TOKEN` as an environment variable in your CI/CD system.

---

## 🎯 Common Tasks

### Install a Package

```bash
npm install <package-name>
```

Packages are resolved from:
1. `npm-shared-local` (your private packages)
2. `npmjs-remote` (public packages, cached)

### Publish a Package

```bash
cd your-package
npm publish
```

Package goes to `npm-shared-local` automatically.

### View Published Packages

**Via JFrog UI:**
1. Go to: https://trialghxmjl.jfrog.io
2. Navigate to: Artifactory → Artifacts → npm-shared-local

**Via API:**
```bash
curl -H "Authorization: Bearer <TOKEN>" \
  https://trialghxmjl.jfrog.io/artifactory/api/storage/npm-shared-local
```

---

## 🆘 Troubleshooting

### Authentication Failed

**Error:** `401 Unauthorized` or `403 Forbidden`

**Solution:**
1. Verify your token is valid
2. Regenerate token if expired
3. Check you're in the correct group (`dev-backend`)

### Cannot Publish Package

**Error:** `You do not have permission to publish`

**Solution:**
1. Verify you're in the `dev-backend` group
2. Check your `.npmrc` has the correct registry
3. Ensure your token has write permissions

### Package Not Found

**Error:** `404 Not Found` when installing

**Solution:**
1. Check package name spelling
2. Verify package exists in `npm-shared-local`
3. Check if it's a public package (should be cached from npmjs.org)

---

## 📞 Support

- **JFrog UI**: https://trialghxmjl.jfrog.io
- **Project Page**: https://trialghxmjl.jfrog.io/ui/admin/projects/members?projectKey=egg
- **Registry URL**: https://trialghxmjl.jfrog.io/artifactory/api/npm/npm/

For access issues, contact your project manager.
