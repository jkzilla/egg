# Docker Local Development

Local Docker configurations for testing TruffleHog and other services.

## TruffleHog Testing

### Option 1: Docker Compose (Recommended)

#### Scan GitHub Repository

```bash
cd docker

# Set GitHub token
export GITHUB_TOKEN=ghp_your_token_here

# Run scan
docker-compose -f docker-compose-trufflehog.yaml up trufflehog

# View results
cat results/scan-results.json
```

#### Scan Local Filesystem

```bash
cd docker

# Scan the entire egg repository
docker-compose -f docker-compose-trufflehog.yaml up trufflehog-filesystem

# Results will be in ./results/
```

### Option 2: Kubernetes Manifest (Minikube/Kind)

```bash
# Start minikube
minikube start

# Apply manifest
kubectl apply -f trufflehog-deployment.yaml

# Check status
kubectl get pods -l app=trufflehog

# View logs
kubectl logs -f deployment/trufflehog

# Cleanup
kubectl delete -f trufflehog-deployment.yaml
```

### Option 3: Docker Run (Quick Test)

```bash
# Scan GitHub repo
docker run --rm \
  -e GITHUB_TOKEN=ghp_your_token \
  trufflesecurity/trufflehog:latest \
  github --repo=https://github.com/jkzilla/egg

# Scan local directory
docker run --rm \
  -v $(pwd)/..:/scan:ro \
  trufflesecurity/trufflehog:latest \
  filesystem /scan

# Scan with JSON output
docker run --rm \
  -v $(pwd)/results:/results \
  trufflesecurity/trufflehog:latest \
  github --repo=https://github.com/jkzilla/egg \
  --json > results/scan.json
```

## Configuration

### Environment Variables

Create `.env` file:

```bash
# GitHub token for API access
GITHUB_TOKEN=ghp_your_github_token_here

# TruffleHog API key (optional)
TRUFFLEHOG_API_KEY=your_api_key_here
```

### Custom Scan Options

Edit `docker-compose-trufflehog.yaml`:

```yaml
command: >
  trufflehog github
  --repo=https://github.com/jkzilla/egg
  --since-commit=HEAD~10
  --branch=main
  --json
  --only-verified
  --fail
```

## Common Commands

### Scan Specific Repository

```bash
docker run --rm \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  trufflesecurity/trufflehog:latest \
  github --org=jkzilla --repo=egg
```

### Scan All Repos in Organization

```bash
docker run --rm \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  trufflesecurity/trufflehog:latest \
  github --org=jkzilla
```

### Scan Git History

```bash
docker run --rm \
  -v $(pwd)/..:/repo:ro \
  trufflesecurity/trufflehog:latest \
  git file:///repo --since-commit=HEAD~100
```

### Scan with Specific Detectors

```bash
docker run --rm \
  trufflesecurity/trufflehog:latest \
  github --repo=https://github.com/jkzilla/egg \
  --detector=aws,github,slack
```

## Output Formats

### JSON Output

```bash
docker run --rm \
  trufflesecurity/trufflehog:latest \
  github --repo=https://github.com/jkzilla/egg \
  --json > scan-results.json
```

### Pretty Print

```bash
docker run --rm \
  trufflesecurity/trufflehog:latest \
  github --repo=https://github.com/jkzilla/egg \
  --json | jq '.'
```

### Filter Verified Only

```bash
docker run --rm \
  trufflesecurity/trufflehog:latest \
  github --repo=https://github.com/jkzilla/egg \
  --only-verified
```

## Troubleshooting

### GitHub Rate Limiting

```bash
# Check rate limit
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/rate_limit

# Use multiple tokens
docker run --rm \
  -e GITHUB_TOKEN=$GITHUB_TOKEN1,$GITHUB_TOKEN2 \
  trufflesecurity/trufflehog:latest \
  github --org=jkzilla
```

### Memory Issues

Increase memory limit in docker-compose:

```yaml
mem_limit: 512m  # Increase from 256m
```

### Slow Scans

```bash
# Scan recent commits only
docker run --rm \
  trufflesecurity/trufflehog:latest \
  github --repo=https://github.com/jkzilla/egg \
  --since-commit=HEAD~10
```

## Integration with CI/CD

### Test Before Pushing

```bash
# Add to pre-commit hook
docker run --rm \
  -v $(pwd):/scan:ro \
  trufflesecurity/trufflehog:latest \
  filesystem /scan --fail
```

### GitHub Actions

```yaml
- name: TruffleHog Scan
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: main
    head: HEAD
```

## Cleanup

```bash
# Stop all containers
docker-compose -f docker-compose-trufflehog.yaml down

# Remove volumes
docker-compose -f docker-compose-trufflehog.yaml down -v

# Remove images
docker rmi trufflesecurity/trufflehog:latest
```

## Resources

- TruffleHog Docs: https://github.com/trufflesecurity/trufflehog
- Docker Hub: https://hub.docker.com/r/trufflesecurity/trufflehog
- Examples: https://github.com/trufflesecurity/trufflehog/tree/main/examples
