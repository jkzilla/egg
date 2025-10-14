# TruffleHog Enterprise On-Premise Deployment

This Helm chart includes TruffleHog Enterprise for continuous secret scanning of your codebase with S3 integration.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │   Hailey's   │    │  TruffleHog  │    │  PostgreSQL  │ │
│  │    Garden    │    │  Enterprise  │◄───┤   Database   │ │
│  │     App      │    │   + S3 Scan  │    │              │ │
│  └──────────────┘    └──────┬───────┘    └──────┬───────┘ │
│         │                    │                    │         │
│         │                    │                    │         │
│  ┌──────▼────────────────────▼────────────────────▼─────┐  │
│  │            NGINX Ingress Controller                   │  │
│  └───────────────────────────────────────────────────────┘  │
│         │                    │                              │
└─────────┼────────────────────┼──────────────────────────────┘
          │                    │
          ▼                    ▼
  haileysgarden.com    trufflehog.haileysgarden.com
          │                    │
          │                    ▼
          │            ┌───────────────┐
          │            │  AWS S3       │
          │            ├───────────────┤
          │            │ • Scan Logs   │
          │            │ • Scan Backups│
          └───────────▶│ • Results     │
                       │ • DB Backups  │
                       └───────────────┘
```

## Features

- **Continuous Scanning**: Automatically scans GitHub repositories every hour
- **S3 Bucket Scanning**: Scans S3 buckets for exposed secrets
- **Secret Detection**: Detects AWS keys, GitHub tokens, Slack webhooks, and more
- **Slack Notifications**: Alerts team when secrets are found
- **S3 Results Storage**: Store scan results in S3 for long-term retention
- **Automated Backups**: Daily PostgreSQL backups to S3
- **Web Dashboard**: Access at `trufflehog.haileysgarden.com`
- **PostgreSQL Backend**: Persistent storage for scan results
- **Kubernetes Native**: Fully integrated with your existing infrastructure

## Configuration

### 1. Enable TruffleHog Enterprise

In `values.yaml`:

```yaml
trufflehog:
  enabled: true  # Set to false to disable
  replicaCount: 1
```

### 2. Configure Database

PostgreSQL is automatically deployed:

```yaml
postgresql:
  enabled: true
  auth:
    username: trufflehog
    password: changeme  # CHANGE THIS IN PRODUCTION
    database: trufflehog
```

### 3. GitHub Integration

```yaml
trufflehog:
  config:
    github:
      enabled: true
      org: jkzilla  # Your GitHub organization
```

You'll need to create a GitHub token:
1. Go to https://github.com/settings/tokens
2. Generate new token (classic)
3. Select scopes: `repo`, `read:org`
4. Copy the token

### 4. Slack Notifications

```yaml
trufflehog:
  config:
    slack:
      enabled: true
```

Create a Slack webhook:
1. Go to https://api.slack.com/apps
2. Create new app
3. Enable Incoming Webhooks
4. Add webhook to workspace
5. Copy webhook URL

### 5. Update Secrets

Edit `templates/trufflehog-secret.yaml` or create a separate secret:

```bash
kubectl create secret generic haileys-garden-trufflehog-secret \
  --from-literal=database-password='your-secure-password' \
  --from-literal=github-token='ghp_your_github_token' \
  --from-literal=slack-webhook='https://hooks.slack.com/services/YOUR/WEBHOOK/URL' \
  -n haileys-garden
```

## Deployment

### Install with TruffleHog Enabled

```bash
helm install haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --create-namespace \
  --set trufflehog.enabled=true \
  --set postgresql.auth.password=your-secure-password
```

### Upgrade Existing Installation

```bash
helm upgrade haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --set trufflehog.enabled=true
```

### Disable TruffleHog

```bash
helm upgrade haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --set trufflehog.enabled=false
```

## Accessing TruffleHog Dashboard

### 1. Add DNS Record

Point `trufflehog.haileysgarden.com` to your load balancer:

```bash
# Get load balancer IP
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

Add A record in Route53 or your DNS provider.

### 2. Access Dashboard

Open https://trufflehog.haileysgarden.com in your browser.

### 3. Port Forward (Development)

```bash
kubectl port-forward svc/haileys-garden-trufflehog 8080:8080 -n haileys-garden
```

Then access http://localhost:8080

## Monitoring

### Check TruffleHog Logs

```bash
kubectl logs -f deployment/haileys-garden-trufflehog -n haileys-garden
```

### Check PostgreSQL

```bash
kubectl exec -it statefulset/haileys-garden-postgres -n haileys-garden -- psql -U trufflehog -d trufflehog
```

### View Scan Results

```sql
SELECT * FROM scans ORDER BY created_at DESC LIMIT 10;
SELECT * FROM findings WHERE verified = true;
```

## Resource Requirements

### Minimum

- **TruffleHog**: 250m CPU, 512Mi RAM
- **PostgreSQL**: 100m CPU, 256Mi RAM
- **Storage**: 18Gi total (10Gi TruffleHog + 8Gi PostgreSQL)

### Recommended for Production

- **TruffleHog**: 1000m CPU, 2Gi RAM
- **PostgreSQL**: 500m CPU, 512Mi RAM
- **Storage**: 50Gi+ for large codebases

## Configuration Options

### Scan Interval

```yaml
trufflehog:
  config:
    scanInterval: "1h"  # Options: 15m, 30m, 1h, 6h, 24h
```

### Log Level

```yaml
trufflehog:
  config:
    logLevel: info  # Options: debug, info, warn, error
```

### Persistence

```yaml
trufflehog:
  persistence:
    enabled: true
    size: 10Gi
    storageClass: "gp3"  # AWS EBS gp3
```

## Security Best Practices

1. **Change Default Passwords**
   ```yaml
   postgresql:
     auth:
       password: "use-a-strong-random-password"
   ```

2. **Use Kubernetes Secrets**
   ```bash
   kubectl create secret generic trufflehog-secrets \
     --from-file=github-token=./github-token.txt \
     --from-file=slack-webhook=./slack-webhook.txt
   ```

3. **Enable RBAC**
   ```yaml
   rbac:
     create: true
   ```

4. **Network Policies**
   ```yaml
   networkPolicy:
     enabled: true
     policyTypes:
       - Ingress
       - Egress
   ```

## Troubleshooting

### TruffleHog Pod Not Starting

```bash
# Check pod status
kubectl get pods -n haileys-garden | grep trufflehog

# View logs
kubectl logs deployment/haileys-garden-trufflehog -n haileys-garden

# Describe pod
kubectl describe pod <trufflehog-pod-name> -n haileys-garden
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
kubectl run -it --rm psql-test --image=postgres:15-alpine --restart=Never -- \
  psql -h postgres -U trufflehog -d trufflehog
```

### GitHub API Rate Limiting

TruffleHog respects GitHub API rate limits. If you hit limits:

1. Use a GitHub App instead of personal token
2. Increase scan interval
3. Use multiple tokens (load balancing)

### Ingress Not Working

```bash
# Check ingress
kubectl get ingress -n haileys-garden

# Check NGINX logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## Upgrading

### Backup Database

```bash
kubectl exec statefulset/haileys-garden-postgres -n haileys-garden -- \
  pg_dump -U trufflehog trufflehog > trufflehog-backup.sql
```

### Upgrade Helm Chart

```bash
helm upgrade haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --reuse-values
```

## Uninstalling

### Remove TruffleHog Only

```bash
helm upgrade haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --set trufflehog.enabled=false
```

### Complete Removal

```bash
# Backup first!
kubectl exec statefulset/haileys-garden-postgres -n haileys-garden -- \
  pg_dump -U trufflehog trufflehog > backup.sql

# Delete resources
kubectl delete deployment haileys-garden-trufflehog -n haileys-garden
kubectl delete statefulset haileys-garden-postgres -n haileys-garden
kubectl delete pvc -l app.kubernetes.io/component=trufflehog -n haileys-garden
kubectl delete pvc -l app.kubernetes.io/component=postgresql -n haileys-garden
```

## Support

- **TruffleHog Docs**: https://trufflesecurity.com/docs
- **GitHub Issues**: https://github.com/trufflesecurity/trufflehog/issues
- **Slack Community**: https://join.slack.com/t/trufflehog-community/shared_invite/...

## License

TruffleHog Enterprise requires a commercial license. Contact TruffleHog Security for pricing.

For open-source version, see: https://github.com/trufflesecurity/trufflehog
