# JFrog Artifactory Configuration

This directory contains JFrog Artifactory repository configurations and setup scripts for Hailey's Garden.

## Repository Architecture

```
┌─────────────────────────────────────────────────────┐
│                  npm (virtual)                      │
│  Primary endpoint for all npm operations            │
│  URL: /artifactory/api/npm/npm/                     │
└──────────────┬──────────────────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌─────────────┐  ┌──────────────┐
│npm-dev-local│  │npmjs-remote  │
│             │  │              │
│Local repo   │  │Proxy to      │
│for internal │  │npmjs.org     │
│packages     │  │              │
└─────────────┘  └──────────────┘
```

### Repository Descriptions

1. **npm-dev-local** (Local Repository)
   - Type: Local
   - Purpose: Store internally developed npm packages
   - Use cases:
     - Custom libraries and components
     - Private packages
     - Build artifacts
     - Forked packages with modifications

2. **npmjs-remote** (Remote Repository)
   - Type: Remote (Proxy)
   - Purpose: Cache packages from npmjs.org
   - Benefits:
     - Faster downloads (cached locally)
     - Reliability (works even if npmjs.org is down)
     - Bandwidth savings
     - Security scanning with Xray (if enabled)

3. **npm** (Virtual Repository)
   - Type: Virtual
   - Purpose: Unified endpoint aggregating local and remote repos
   - Default deployment: npm-dev-local
   - Resolution order: npm-dev-local → npmjs-remote

## Setup Instructions

### Prerequisites

1. JFrog Artifactory instance (Cloud or Self-hosted)
2. Admin or repository management permissions
3. JFrog access token or credentials

### Step 1: Get Your JFrog Token

1. Log in to JFrog Artifactory UI
2. Click your profile icon → "Edit Profile"
3. Generate an access token or use existing one
4. Copy the token

### Step 2: Set Environment Variables

```bash
export JFROG_URL="https://your-instance.jfrog.io/artifactory"
export JFROG_USER="your-username"
export JFROG_TOKEN="your-token"
```

### Step 3: Run Setup Script

```bash
cd jfrog
chmod +x setup-npm-repos.sh
./setup-npm-repos.sh
```

### Step 4: Configure npm

#### Option A: User-level Configuration

```bash
# Set registry
npm config set registry https://your-instance.jfrog.io/artifactory/api/npm/npm/

# Set authentication (replace with your credentials)
npm config set //your-instance.jfrog.io/artifactory/api/npm/npm/:_authToken YOUR_TOKEN
```

#### Option B: Project-level Configuration

Copy the template and configure:

```bash
cp jfrog/.npmrc.template .npmrc
# Edit .npmrc with your credentials
```

**Important:** Add `.npmrc` to `.gitignore` to avoid committing credentials!

### Step 5: Verify Setup

```bash
# Test authentication
npm ping --registry https://your-instance.jfrog.io/artifactory/api/npm/npm/

# Install a package
cd frontend
npm install

# Check where packages are coming from
npm config get registry
```

## Usage

### Installing Packages

Packages will automatically be resolved through the virtual repository:

```bash
npm install react
# Downloads from npmjs-remote (cached from npmjs.org)

npm install @haileys-garden/custom-component
# Downloads from npm-dev-local (if published there)
```

### Publishing Packages

To publish to your local repository:

```bash
# In your package directory
npm publish --registry https://your-instance.jfrog.io/artifactory/api/npm/npm-dev-local/
```

Or configure in `package.json`:

```json
{
  "publishConfig": {
    "registry": "https://your-instance.jfrog.io/artifactory/api/npm/npm-dev-local/"
  }
}
```

### Using Scoped Packages

Configure scoped packages to always use your registry:

```bash
npm config set @haileys-garden:registry https://your-instance.jfrog.io/artifactory/api/npm/npm/
```

## CI/CD Integration

### CircleCI

Add to `.circleci/config.yml`:

```yaml
version: 2.1

jobs:
  build:
    docker:
      - image: cimg/node:18.0
    steps:
      - checkout
      - run:
          name: Configure npm registry
          command: |
            echo "registry=https://your-instance.jfrog.io/artifactory/api/npm/npm/" > ~/.npmrc
            echo "//your-instance.jfrog.io/artifactory/api/npm/npm/:_authToken=${JFROG_TOKEN}" >> ~/.npmrc
      - run:
          name: Install dependencies
          command: cd frontend && npm install
```

Set `JFROG_TOKEN` in CircleCI environment variables.

### GitHub Actions

Add to `.github/workflows/build.yml`:

```yaml
- name: Configure npm registry
  run: |
    echo "registry=https://your-instance.jfrog.io/artifactory/api/npm/npm/" > ~/.npmrc
    echo "//your-instance.jfrog.io/artifactory/api/npm/npm/:_authToken=${{ secrets.JFROG_TOKEN }}" >> ~/.npmrc

- name: Install dependencies
  run: cd frontend && npm install
```

## Troubleshooting

### Authentication Errors

```bash
# Verify token is set
npm config get //your-instance.jfrog.io/artifactory/api/npm/npm/:_authToken

# Test with curl
curl -u username:token https://your-instance.jfrog.io/artifactory/api/npm/npm/
```

### Package Not Found

1. Check if package exists in npmjs.org
2. Verify remote repository is configured correctly
3. Check repository permissions
4. Try clearing npm cache: `npm cache clean --force`

### SSL Certificate Errors

For self-signed certificates (development only):

```bash
npm config set strict-ssl false
```

**Warning:** Don't use this in production!

## Repository Management

### View Repository Status

```bash
# List all repositories
curl -u username:token https://your-instance.jfrog.io/artifactory/api/repositories

# Get specific repository info
curl -u username:token https://your-instance.jfrog.io/artifactory/api/repositories/npm-dev-local
```

### Update Repository Configuration

Edit the JSON files in `repositories/` and re-run:

```bash
./setup-npm-repos.sh
```

### Delete Repositories

```bash
curl -u username:token -X DELETE \
  https://your-instance.jfrog.io/artifactory/api/repositories/npm-dev-local
```

## Security Best Practices

1. **Never commit credentials** - Always use environment variables or secrets management
2. **Use access tokens** - Prefer tokens over passwords
3. **Rotate tokens regularly** - Set expiration dates on tokens
4. **Limit permissions** - Use principle of least privilege
5. **Enable Xray scanning** - Scan for vulnerabilities (if available)
6. **Use HTTPS** - Always use secure connections
7. **Audit access logs** - Monitor who's accessing repositories

## Additional Resources

- [JFrog NPM Registry Documentation](https://www.jfrog.com/confluence/display/JFROG/npm+Registry)
- [npm Configuration Documentation](https://docs.npmjs.com/cli/v9/configuring-npm/npmrc)
- [JFrog REST API](https://www.jfrog.com/confluence/display/JFROG/Artifactory+REST+API)

## Support

For issues or questions:
1. Check JFrog Artifactory logs
2. Review npm debug logs: `npm install --loglevel verbose`
3. Contact your JFrog administrator
