# CircleCI Configuration

This directory contains the CircleCI pipeline configuration for the Egg Shop project.

## Pipeline Overview

The CI/CD pipeline includes the following stages:

### 1. **Security Scan** 🔒
- Runs TruffleHog to detect secrets and credentials
- Scans both incremental changes and full repository
- Stores scan results as artifacts
- **Runs first** to catch security issues early

### 2. **Backend Build & Test** 🐹
- Downloads Go dependencies with caching
- Runs unit tests with race detection
- Generates code coverage reports
- Runs `go vet` for static analysis
- Checks code formatting with `gofmt`
- Builds the Go binary

### 3. **Frontend Build & Test** ⚛️
- Installs npm dependencies with caching
- Runs ESLint for code quality
- Builds production frontend bundle
- Validates build output
- Stores build artifacts

### 4. **Integration Tests** 🧪
- Starts the backend server
- Tests GraphQL endpoints
- Validates API responses
- Ensures frontend/backend compatibility

### 5. **Docker Build & Push** 🐳
- Builds multi-stage Docker image
- Tests the Docker container
- Pushes to Docker Hub (main/master/develop only)
- Tags with commit SHA and `latest`

### 6. **Nightly Security Scan** 🌙
- Runs daily at 2 AM
- Full repository security scan
- Monitors for new vulnerabilities

## Workflow Diagram

```
security-scan
     ├─> backend-build-test ─┐
     └─> frontend-build-test ─┤
                              ├─> integration-test ─> docker-build
```

## Setup Instructions

### 1. Enable CircleCI

1. Go to [CircleCI](https://circleci.com/)
2. Sign in with GitHub
3. Select your repository: `jkzilla/egg`
4. Click "Set Up Project"
5. CircleCI will automatically detect `.circleci/config.yml`

### 2. Configure Environment Variables

Add these environment variables in CircleCI project settings:

**For Docker Hub (optional):**
- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_PASSWORD` - Your Docker Hub password or access token

**Alternative: Use Context**
Create a context named `docker-hub-creds` with the above variables.

### 3. Enable Docker Layer Caching (Optional)

For faster builds, enable Docker Layer Caching:
1. Go to Project Settings → Advanced
2. Enable "Docker Layer Caching"
3. Note: This requires a paid CircleCI plan

## Running Locally

Test the configuration locally using CircleCI CLI:

```bash
# Install CircleCI CLI
brew install circleci

# Validate config
circleci config validate

# Run a job locally
circleci local execute --job backend-build-test
```

## Caching Strategy

### Go Dependencies
- **Cache Key**: Go version + `go.sum` checksum
- **Cached Paths**: `~/go/pkg/mod`
- **Invalidation**: When `go.sum` changes

### npm Dependencies
- **Cache Key**: `frontend/package.json` checksum
- **Cached Paths**: `frontend/node_modules`
- **Invalidation**: When `package.json` changes

### Docker Layers
- **Enabled**: When Docker Layer Caching is active
- **Benefit**: Faster Docker builds by reusing unchanged layers

## Artifacts

The pipeline stores the following artifacts:

1. **Security Scan Results** (`trufflehog-results.json`)
2. **Code Coverage Report** (`coverage.html`)
3. **Frontend Build** (`frontend/dist`)

Access artifacts from the CircleCI job page under the "Artifacts" tab.

## Branch Policies

### All Branches
- Security scan
- Backend build & test
- Frontend build & test
- Integration tests

### Protected Branches (main/master/develop)
- All of the above
- Docker build & push

## Status Badge

Add this badge to your README to show build status:

```markdown
[![CircleCI](https://circleci.com/gh/jkzilla/egg.svg?style=svg)](https://circleci.com/gh/jkzilla/egg)
```

## Troubleshooting

### Build Fails on `go test`
- Check test output in the job logs
- Run tests locally: `go test -v ./...`

### Frontend Build Fails
- Verify `package.json` dependencies
- Run locally: `cd frontend && npm install && npm run build`

### Docker Build Fails
- Check Dockerfile syntax
- Ensure frontend builds successfully first
- Test locally: `docker build -t egg-test .`

### TruffleHog Fails
- Review detected secrets in artifacts
- Add false positives to `.trufflehog.yaml` exclusions
- Rotate any exposed credentials immediately

## Performance Optimization

Current build times (approximate):
- Security Scan: ~30 seconds
- Backend Build: ~2 minutes
- Frontend Build: ~3 minutes
- Integration Tests: ~1 minute
- Docker Build: ~5 minutes

**Total Pipeline Time**: ~8-10 minutes

### Tips to Speed Up Builds
1. Enable Docker Layer Caching
2. Use larger resource classes (paid plans)
3. Optimize Docker image layers
4. Minimize npm dependencies

## Support

For CircleCI-specific issues:
- [CircleCI Documentation](https://circleci.com/docs/)
- [CircleCI Community Forum](https://discuss.circleci.com/)
- [CircleCI Support](https://support.circleci.com/)
