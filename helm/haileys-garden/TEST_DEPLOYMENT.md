# Testing TruffleHog Enterprise Deployment

Quick guide to test TruffleHog Enterprise before deploying to production.

## Prerequisites

1. Kubernetes cluster (K3s, minikube, or cloud)
2. Helm 3 installed
3. kubectl configured
4. GitHub personal access token
5. Slack webhook URL (optional)

## Quick Test Deployment

### 1. Create Test Namespace

```bash
kubectl create namespace trufflehog-test
```

### 2. Create Secrets

```bash
# Create GitHub token secret
kubectl create secret generic trufflehog-github \
  --from-literal=token='ghp_YOUR_GITHUB_TOKEN' \
  -n trufflehog-test

# Create Slack webhook secret (optional)
kubectl create secret generic trufflehog-slack \
  --from-literal=webhook='https://hooks.slack.com/services/YOUR/WEBHOOK/URL' \
  -n trufflehog-test
```

### 3. Deploy with Test Values

```bash
helm install trufflehog-test ./helm/haileys-garden \
  --namespace trufflehog-test \
  --values ./helm/haileys-garden/values-trufflehog-test.yaml \
  --set postgresql.auth.password='secure-test-password'
```

### 4. Wait for Pods

```bash
kubectl get pods -n trufflehog-test -w
```

Expected output:
```
NAME                                    READY   STATUS    RESTARTS   AGE
haileys-garden-postgres-0               1/1     Running   0          2m
haileys-garden-trufflehog-xxxxx-yyyyy   1/1     Running   0          2m
```

### 5. Check Logs

```bash
# TruffleHog logs
kubectl logs -f deployment/haileys-garden-trufflehog -n trufflehog-test

# PostgreSQL logs
kubectl logs -f statefulset/haileys-garden-postgres -n trufflehog-test
```

### 6. Port Forward to Access Dashboard

```bash
kubectl port-forward svc/haileys-garden-trufflehog 8080:8080 -n trufflehog-test
```

Open http://localhost:8080 in your browser.

## Verify Functionality

### 1. Check Database Connection

```bash
kubectl exec -it statefulset/haileys-garden-postgres -n trufflehog-test -- \
  psql -U trufflehog -d trufflehog -c "\dt"
```

Expected: List of TruffleHog tables

### 2. Trigger Manual Scan

```bash
kubectl exec -it deployment/haileys-garden-trufflehog -n trufflehog-test -- \
  curl -X POST http://localhost:8080/api/scan
```

### 3. Check Scan Results

```bash
kubectl exec -it statefulset/haileys-garden-postgres -n trufflehog-test -- \
  psql -U trufflehog -d trufflehog -c "SELECT COUNT(*) FROM scans;"
```

### 4. View Recent Findings

```bash
kubectl exec -it statefulset/haileys-garden-postgres -n trufflehog-test -- \
  psql -U trufflehog -d trufflehog -c "SELECT * FROM findings LIMIT 5;"
```

## Test Scenarios

### Scenario 1: Detect Test Secrets

1. Create a test repository with secrets:
```bash
mkdir /tmp/test-repo
cd /tmp/test-repo
git init
echo "aws_access_key_id=AKIAIOSFODNN7EXAMPLE" > secrets.txt
git add .
git commit -m "Add test secrets"
git push origin main
```

2. Wait for TruffleHog to scan (15 minutes with test config)

3. Check findings:
```bash
kubectl exec -it statefulset/haileys-garden-postgres -n trufflehog-test -- \
  psql -U trufflehog -d trufflehog -c "SELECT * FROM findings WHERE verified=true;"
```

### Scenario 2: Slack Notifications

1. Add a secret to your repository
2. Wait for scan
3. Check Slack channel for notification

### Scenario 3: Resource Usage

Monitor resource consumption:

```bash
# CPU and Memory usage
kubectl top pods -n trufflehog-test

# Storage usage
kubectl get pvc -n trufflehog-test
```

## Troubleshooting

### Pod Not Starting

```bash
# Describe pod
kubectl describe pod -l app.kubernetes.io/component=trufflehog -n trufflehog-test

# Check events
kubectl get events -n trufflehog-test --sort-by='.lastTimestamp'
```

### Database Connection Failed

```bash
# Test PostgreSQL connectivity
kubectl run -it --rm psql-test --image=postgres:15-alpine --restart=Never -n trufflehog-test -- \
  psql -h postgres -U trufflehog -d trufflehog
```

### GitHub API Errors

Check logs for rate limiting:
```bash
kubectl logs deployment/haileys-garden-trufflehog -n trufflehog-test | grep -i "rate limit"
```

### Ingress Not Working

```bash
# Check ingress
kubectl get ingress -n trufflehog-test

# Test service directly
kubectl port-forward svc/haileys-garden-trufflehog 8080:8080 -n trufflehog-test
```

## Cleanup

### Remove Test Deployment

```bash
helm uninstall trufflehog-test -n trufflehog-test
```

### Delete Persistent Data

```bash
kubectl delete pvc -l app.kubernetes.io/instance=trufflehog-test -n trufflehog-test
```

### Delete Namespace

```bash
kubectl delete namespace trufflehog-test
```

## Production Deployment

Once testing is successful, deploy to production:

```bash
helm install haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --create-namespace \
  --set trufflehog.enabled=true \
  --set postgresql.auth.password='STRONG-PRODUCTION-PASSWORD'
```

See [TRUFFLEHOG_ENTERPRISE.md](TRUFFLEHOG_ENTERPRISE.md) for full production deployment guide.

## Performance Benchmarks

Expected performance on t3.small (2 vCPU, 2GB RAM):

- **Scan Duration**: 5-10 minutes for 100 repositories
- **Memory Usage**: 500-800 MB during scan
- **CPU Usage**: 30-50% during scan
- **Storage Growth**: ~100MB per 1000 repositories scanned

## Next Steps

1. ✅ Test deployment successful
2. ✅ Secrets detected correctly
3. ✅ Slack notifications working
4. ✅ Database persisting data
5. → Deploy to production
6. → Configure monitoring and alerts
7. → Set up backup strategy

## Support

- Check logs: `kubectl logs -f deployment/haileys-garden-trufflehog -n trufflehog-test`
- TruffleHog docs: https://trufflesecurity.com/docs
- GitHub issues: https://github.com/trufflesecurity/trufflehog/issues
