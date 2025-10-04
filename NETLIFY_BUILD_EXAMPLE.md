# Netlify Build Example - Step by Step

This guide shows you exactly how to test and deploy your Egg Shop to Netlify.

## Prerequisites

```bash
# Verify you have the required tools
node --version   # Should be 20.x
npm --version    # Should be 10.x
```

## Step 1: Test Build Locally

### Option A: Test with Local Backend

```bash
# Terminal 1: Start the backend
cd /Users/johanna/src/haileysgarden/egg
go run .

# Terminal 2: Build and test frontend
cd frontend
npm install
npm run build

# Preview the production build
npm run preview
# Visit: http://localhost:4173
```

### Option B: Test with Production Backend URL

```bash
cd frontend

# Set the backend URL (replace with your actual backend)
export VITE_GRAPHQL_ENDPOINT="https://your-backend.onrender.com/graphql"

# Build
npm run build

# Preview
npm run preview
```

### Verify Build Output

```bash
cd frontend
ls -la dist/

# You should see:
# dist/
#   ├── index.html
#   ├── assets/
#   │   ├── index-[hash].js
#   │   ├── index-[hash].css
#   └── vite.svg
```

## Step 2: Deploy to Netlify via CLI

### Install Netlify CLI

```bash
npm install -g netlify-cli

# Verify installation
netlify --version
```

### Login to Netlify

```bash
netlify login
# Opens browser for authentication
```

### Initialize Your Site

```bash
# From project root
cd /Users/johanna/src/haileysgarden/egg

netlify init
```

**Follow the prompts:**
```
? What would you like to do?
  ❯ Create & configure a new site

? Team:
  ❯ Your Team Name

? Site name (optional):
  ❯ egg-shop-haileys-garden

? Your build command (hugo build/yarn run build/etc):
  ❯ npm run build

? Directory to deploy (blank for current dir):
  ❯ frontend/dist

? Netlify config file:
  ❯ Yes, use existing netlify.toml
```

### Set Environment Variable

```bash
# Replace with your actual backend URL
netlify env:set VITE_GRAPHQL_ENDPOINT "https://egg-api.onrender.com/graphql"

# Verify it was set
netlify env:list
```

### Deploy to Preview

```bash
# Deploy a draft/preview first
netlify deploy

# Review the deploy preview URL
# Example: https://deploy-preview-123--egg-shop.netlify.app
```

### Deploy to Production

```bash
# If preview looks good, deploy to production
netlify deploy --prod

# Your site is now live!
# Example: https://egg-shop-haileys-garden.netlify.app
```

## Step 3: Deploy via Netlify UI

### Connect Repository

1. Go to https://app.netlify.com/
2. Click **"Add new site"** → **"Import an existing project"**
3. Choose **GitHub**
4. Select repository: `jkzilla/egg`
5. Click **"Deploy site"**

### Configure Build Settings

Netlify auto-detects from `netlify.toml`, but verify:

```
Base directory:    frontend
Build command:     npm run build
Publish directory: frontend/dist
```

### Set Environment Variables

1. Go to **Site settings** → **Environment variables**
2. Click **"Add a variable"**
3. Add:
   - **Key**: `VITE_GRAPHQL_ENDPOINT`
   - **Value**: `https://your-backend.onrender.com/graphql`
4. Click **"Save"**

### Trigger Deploy

1. Go to **Deploys** tab
2. Click **"Trigger deploy"** → **"Deploy site"**
3. Wait 2-3 minutes for build to complete

## Example Build Commands

### Local Development Build

```bash
cd frontend

# Development mode (with HMR)
npm run dev
# Visit: http://localhost:5173
```

### Production Build (Local)

```bash
cd frontend

# Clean previous build
rm -rf dist

# Build for production
npm run build

# Output:
# vite v5.4.10 building for production...
# ✓ 234 modules transformed.
# dist/index.html                   0.38 kB │ gzip:  0.26 kB
# dist/assets/index-abc123.css      4.56 kB │ gzip:  1.23 kB
# dist/assets/index-def456.js     142.34 kB │ gzip: 45.67 kB
# ✓ built in 2.34s
```

### Production Build (Netlify)

Netlify runs this automatically:

```bash
# Netlify's build process:
cd frontend
npm ci                    # Install dependencies
npm run build            # Build production bundle
# Deploys frontend/dist/ to CDN
```

## Example .env Files

### Local Development (.env.local)

```bash
# frontend/.env.local
VITE_GRAPHQL_ENDPOINT=http://localhost:8080/graphql
```

### Production (Netlify Environment Variables)

Set in Netlify UI or CLI:
```bash
VITE_GRAPHQL_ENDPOINT=https://egg-api.onrender.com/graphql
```

## Complete Example Workflow

### Scenario: Deploy to Netlify with Render Backend

```bash
# 1. Deploy backend to Render first
# (Done via Render dashboard)
# Result: https://egg-api.onrender.com

# 2. Test backend is working
curl https://egg-api.onrender.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ eggs { id type price } }"}'

# 3. Test frontend build locally
cd frontend
export VITE_GRAPHQL_ENDPOINT="https://egg-api.onrender.com/graphql"
npm run build
npm run preview

# 4. Deploy to Netlify
cd ..
netlify login
netlify init
netlify env:set VITE_GRAPHQL_ENDPOINT "https://egg-api.onrender.com/graphql"
netlify deploy --prod

# 5. Test production site
curl https://egg-shop-haileys-garden.netlify.app
```

## Troubleshooting Build Issues

### Build Fails: "Cannot find module"

```bash
# Solution: Ensure package-lock.json is committed
cd frontend
npm install
git add package-lock.json
git commit -m "Add package-lock.json"
git push
```

### Build Fails: "VITE_GRAPHQL_ENDPOINT not set"

```bash
# Solution: Set environment variable
netlify env:set VITE_GRAPHQL_ENDPOINT "https://your-backend.com/graphql"

# Or in Netlify UI:
# Site settings → Environment variables → Add variable
```

### Build Succeeds but Site Shows Errors

```bash
# Check browser console for CORS errors
# Solution: Update backend CORS settings

# In server.go:
AllowedOrigins: []string{
    "http://localhost:5173",
    "https://egg-shop-haileys-garden.netlify.app",
},
```

### Build is Slow

```bash
# Check build time in Netlify logs
# Typical times:
# - npm ci: 30-60s
# - npm run build: 20-40s
# - Total: 1-2 minutes

# To speed up:
# 1. Enable Netlify build cache
# 2. Optimize dependencies
# 3. Use npm ci instead of npm install
```

## Build Output Example

### Successful Build Log

```
10:30:15 AM: Build ready to start
10:30:17 AM: build-image version: 12345
10:30:17 AM: buildbot version: abcdef
10:30:17 AM: Fetching cached dependencies
10:30:18 AM: Starting to download cache
10:30:20 AM: Finished downloading cache
10:30:20 AM: Starting build script
10:30:21 AM: Installing dependencies
10:30:21 AM: Python version set to 3.8
10:30:22 AM: Started restoring cached Node.js version
10:30:24 AM: Finished restoring cached Node.js version
10:30:25 AM: v20.18.0 is already installed
10:30:26 AM: Detected package-lock.json: Running npm ci
10:30:45 AM: npm ci completed
10:30:45 AM: Install dependencies script success
10:30:45 AM: Starting build script
10:30:45 AM: Detected 1 framework(s)
10:30:45 AM: "vite" at version "5.4.10"
10:30:46 AM: Running build command: npm run build
10:30:46 AM: > egg-shop-frontend@0.0.1 build
10:30:46 AM: > tsc && vite build
10:31:05 AM: vite v5.4.10 building for production...
10:31:05 AM: transforming...
10:31:15 AM: ✓ 234 modules transformed.
10:31:16 AM: rendering chunks...
10:31:17 AM: computing gzip size...
10:31:17 AM: dist/index.html                   0.38 kB │ gzip:  0.26 kB
10:31:17 AM: dist/assets/index-abc123.css      4.56 kB │ gzip:  1.23 kB
10:31:17 AM: dist/assets/index-def456.js     142.34 kB │ gzip: 45.67 kB
10:31:17 AM: ✓ built in 12.34s
10:31:18 AM: Build script success
10:31:18 AM: Deploying to CDN...
10:31:25 AM: Finished processing build request in 1m10s
10:31:26 AM: Site is live ✨
```

## Quick Reference Commands

```bash
# Install dependencies
npm install

# Build for production
npm run build

# Preview production build
npm run preview

# Deploy to Netlify (preview)
netlify deploy

# Deploy to Netlify (production)
netlify deploy --prod

# Set environment variable
netlify env:set VITE_GRAPHQL_ENDPOINT "https://backend.com/graphql"

# View environment variables
netlify env:list

# Open Netlify dashboard
netlify open

# View build logs
netlify logs
```

## Next Steps

1. ✅ Test build locally
2. ✅ Deploy to Netlify preview
3. ✅ Verify preview works
4. ✅ Deploy to production
5. ✅ Set up custom domain (optional)
6. ✅ Enable continuous deployment

For more details, see [NETLIFY_DEPLOY.md](./NETLIFY_DEPLOY.md)
