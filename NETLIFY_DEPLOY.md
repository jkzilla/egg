# Netlify Deployment Guide

This guide walks you through deploying the Egg Shop frontend to Netlify.

## Prerequisites

- A [Netlify account](https://app.netlify.com/signup) (free tier works)
- Your backend API deployed and accessible (e.g., on Render, Railway, or Fly.io)
- Git repository pushed to GitHub

## Deployment Options

### Option 1: Deploy via Netlify UI (Recommended for First Time)

#### Step 1: Connect Repository

1. Log in to [Netlify](https://app.netlify.com/)
2. Click **"Add new site"** → **"Import an existing project"**
3. Choose **GitHub** and authorize Netlify
4. Select your `egg` repository

#### Step 2: Configure Build Settings

Netlify should auto-detect the settings from `netlify.toml`, but verify:

- **Base directory**: `frontend`
- **Build command**: `npm run build`
- **Publish directory**: `frontend/dist`
- **Node version**: 20

#### Step 3: Set Environment Variables

Before deploying, add your backend API URL:

1. Go to **Site settings** → **Environment variables**
2. Click **Add a variable**
3. Add:
   - **Key**: `VITE_GRAPHQL_ENDPOINT`
   - **Value**: `https://your-backend-url.com/graphql`

   Example: `https://egg-api.onrender.com/graphql`

#### Step 4: Deploy

1. Click **"Deploy site"**
2. Wait for the build to complete (~2-3 minutes)
3. Your site will be live at `https://random-name-123.netlify.app`

#### Step 5: Custom Domain (Optional)

1. Go to **Domain settings**
2. Click **"Add custom domain"**
3. Follow instructions to configure DNS

---

### Option 2: Deploy via Netlify CLI

#### Install Netlify CLI

```bash
npm install -g netlify-cli
```

#### Login to Netlify

```bash
netlify login
```

#### Initialize Site

From the project root:

```bash
netlify init
```

Follow the prompts:
- **Create & configure a new site**
- Choose your team
- Site name: `egg-shop` (or your preferred name)
- Build command: `npm run build`
- Directory to deploy: `frontend/dist`
- Netlify config: Yes (use existing `netlify.toml`)

#### Set Environment Variable

```bash
netlify env:set VITE_GRAPHQL_ENDPOINT "https://your-backend-url.com/graphql"
```

#### Deploy

```bash
# Deploy to production
netlify deploy --prod

# Or deploy a preview first
netlify deploy
```

---

### Option 3: Continuous Deployment (Automatic)

Once connected via Option 1 or 2, Netlify automatically deploys on every push to your main branch.

**Configure branch deploys:**
1. Go to **Site settings** → **Build & deploy** → **Continuous deployment**
2. Set **Production branch**: `main` or `master`
3. Enable **Deploy previews** for pull requests

---

## Testing Before Deploy

### Local Production Build

Test the production build locally:

```bash
cd frontend

# Set environment variable for testing
export VITE_GRAPHQL_ENDPOINT=https://your-backend-url.com/graphql

# Build
npm run build

# Preview
npm run preview
```

Visit `http://localhost:4173` to test the production build.

---

## Backend Deployment Options

You need to deploy the Go backend first. Here are recommended options:

### Option A: Render (Recommended - Free Tier Available)

1. Go to [Render](https://render.com/)
2. Create a **New Web Service**
3. Connect your GitHub repo
4. Configure:
   - **Build Command**: `go build -o egg .`
   - **Start Command**: `./egg`
   - **Port**: `8080`
5. Deploy and copy the URL

### Option B: Railway

1. Go to [Railway](https://railway.app/)
2. **New Project** → **Deploy from GitHub**
3. Select your repo
4. Railway auto-detects Go and deploys
5. Copy the public URL

### Option C: Fly.io

```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

# Login
flyctl auth login

# Launch app
flyctl launch

# Deploy
flyctl deploy
```

### Option D: Docker on Any Platform

Use the existing `Dockerfile`:

```bash
docker build -t egg-shop .
docker run -p 8080:8080 egg-shop
```

Deploy to: DigitalOcean App Platform, Google Cloud Run, AWS ECS, etc.

---

## CORS Configuration

Your backend must allow requests from your Netlify domain.

Update `server.go` CORS settings:

```go
c := cors.New(cors.Options{
    AllowedOrigins: []string{
        "http://localhost:5173",
        "http://localhost:8080",
        "https://your-site.netlify.app",  // Add your Netlify URL
    },
    AllowCredentials: true,
})
```

Or allow all origins (less secure):

```go
AllowedOrigins: []string{"*"},
```

---

## Example Deployment Flow

### 1. Deploy Backend to Render

```bash
# Push your code to GitHub
git push origin main

# On Render dashboard:
# - Create Web Service
# - Connect GitHub repo
# - Build: go build -o egg .
# - Start: ./egg
# - Port: 8080
```

**Result**: `https://egg-api.onrender.com`

### 2. Deploy Frontend to Netlify

```bash
# Set environment variable on Netlify
netlify env:set VITE_GRAPHQL_ENDPOINT "https://egg-api.onrender.com/graphql"

# Deploy
netlify deploy --prod
```

**Result**: `https://egg-shop.netlify.app`

### 3. Update Backend CORS

Update `server.go`:

```go
AllowedOrigins: []string{
    "http://localhost:5173",
    "https://egg-shop.netlify.app",
},
```

Redeploy backend.

---

## Troubleshooting

### Build Fails on Netlify

**Check build logs:**
1. Go to **Deploys** tab
2. Click the failed deploy
3. View build log

**Common issues:**
- Missing `package-lock.json` → Commit it to repo
- Wrong Node version → Set `NODE_VERSION=20` in environment
- Build command fails → Test locally with `npm run build`

### GraphQL Errors in Production

**Symptoms:** Frontend loads but no data appears

**Solutions:**
1. Check browser console for CORS errors
2. Verify `VITE_GRAPHQL_ENDPOINT` is set correctly
3. Test backend URL directly: `curl https://your-backend/graphql`
4. Update backend CORS to allow Netlify domain

### Environment Variable Not Working

**Check:**
```bash
# View all env vars
netlify env:list

# Test build locally with env var
VITE_GRAPHQL_ENDPOINT=https://test.com/graphql npm run build
```

**Note:** Environment variables starting with `VITE_` are embedded at build time, not runtime.

---

## Monitoring & Analytics

### Enable Netlify Analytics

1. Go to **Site settings** → **Analytics**
2. Enable **Netlify Analytics** ($9/month)
3. View traffic, performance, and errors

### Free Alternatives

- **Google Analytics**: Add tracking code to `index.html`
- **Plausible**: Privacy-friendly analytics
- **Vercel Analytics**: If you switch to Vercel

---

## Cost Estimates

### Netlify (Frontend)
- **Free tier**: 100GB bandwidth, 300 build minutes/month
- **Pro**: $19/month (unlimited builds, more bandwidth)

### Render (Backend)
- **Free tier**: 750 hours/month (sleeps after 15 min inactivity)
- **Starter**: $7/month (always on)

### Total for Small Project
- **Free**: $0 (with limitations)
- **Paid**: ~$26/month (Netlify Pro + Render Starter)

---

## Next Steps

1. ✅ Deploy backend to Render/Railway/Fly.io
2. ✅ Get backend URL
3. ✅ Set `VITE_GRAPHQL_ENDPOINT` on Netlify
4. ✅ Deploy frontend to Netlify
5. ✅ Update backend CORS settings
6. ✅ Test the live site
7. ✅ Set up custom domain (optional)
8. ✅ Enable continuous deployment

---

## Additional Resources

- [Netlify Documentation](https://docs.netlify.com/)
- [Vite Environment Variables](https://vitejs.dev/guide/env-and-mode.html)
- [Render Go Deployment](https://render.com/docs/deploy-go)
- [Railway Documentation](https://docs.railway.app/)

---

## Support

If you encounter issues:
1. Check Netlify build logs
2. Test production build locally
3. Verify environment variables
4. Check backend CORS configuration
5. Review browser console for errors

Happy deploying! 🚀
