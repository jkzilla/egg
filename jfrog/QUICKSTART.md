# JFrog NPM Repositories - Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### 1. Set Your Credentials

```bash
export JFROG_URL="https://your-instance.jfrog.io/artifactory"
export JFROG_USER="your-username"
export JFROG_TOKEN="your-token"
```

### 2. Create Repositories

```bash
cd jfrog
./setup-npm-repos.sh
```

### 3. Configure npm

```bash
# Copy template
cp jfrog/.npmrc.template ~/.npmrc

# Edit with your credentials
# Replace:
#   - your-instance.jfrog.io with your actual JFrog instance
#   - YOUR_JFROG_TOKEN with your actual token
```

### 4. Test It

```bash
cd frontend
npm install
```

✅ Done! Your npm is now using JFrog Artifactory.

---

## 📦 Repository Overview

| Repository | Type | Purpose | URL |
|------------|------|---------|-----|
| **npm** | Virtual | Main endpoint (use this!) | `/api/npm/npm/` |
| **npm-dev-local** | Local | Your internal packages | `/api/npm/npm-dev-local/` |
| **npmjs-remote** | Remote | Cached npmjs.org packages | `/api/npm/npmjs-remote/` |

---

## 💡 Common Commands

### Install packages (uses virtual repo)
```bash
npm install
npm install react
```

### Publish to local repo
```bash
npm publish --registry https://your-instance.jfrog.io/artifactory/api/npm/npm-dev-local/
```

### Check current registry
```bash
npm config get registry
```

### Clear cache
```bash
npm cache clean --force
```

---

## 🔧 Troubleshooting

### "401 Unauthorized"
- Check your token is correct
- Verify token hasn't expired
- Ensure `always-auth=true` in .npmrc

### "404 Not Found"
- Package might not exist in npmjs.org
- Check repository permissions
- Verify registry URL is correct

### Packages installing slowly
- First install caches packages (slower)
- Subsequent installs are fast (cached)
- Check network connection to JFrog

---

## 📚 Need More Help?

See [README.md](./README.md) for detailed documentation.
