# Federated Repositories - Quick Start Guide

## 5-Minute Demo Setup

### Prerequisites
- JFrog Pro or Enterprise license
- Access to 2+ JFrog instances (or trial accounts)
- Admin permissions on all instances

### Quick Setup

```bash
# 1. Set environment variables for PRIMARY instance
export JFROG_URL="https://your-primary.jfrog.io"
export JFROG_TOKEN="your-primary-token"

# 2. Run setup script
cd /Users/johanna/src/haileysgarden/egg/jfrog
chmod +x setup-federated-repos.sh
./setup-federated-repos.sh

# 3. Create same repository on SECONDARY instance
export SECONDARY_URL="https://your-secondary.jfrog.io"
export SECONDARY_TOKEN="your-secondary-token"

# Create repository on secondary
curl -X PUT \
  -H "Authorization: Bearer ${SECONDARY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @repositories/npm-federated-local.json \
  "${SECONDARY_URL}/artifactory/api/repositories/npm-federated"

# 4. Link instances (from primary)
curl -X POST \
  -H "Authorization: Bearer ${JFROG_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"url\": \"${SECONDARY_URL}/artifactory/npm-federated\", \"enabled\": true}" \
  "${JFROG_URL}/artifactory/api/federation/npm-federated/member"
```

### Test Replication

```bash
# 1. Publish to PRIMARY
cd /Users/johanna/src/haileysgarden/egg/packages/team-a-service
npm config set registry ${JFROG_URL}/artifactory/api/npm/npm-federated/
npm publish

# 2. Wait 5 seconds for replication
sleep 5

# 3. Verify on SECONDARY
curl -H "Authorization: Bearer ${SECONDARY_TOKEN}" \
  "${SECONDARY_URL}/artifactory/npm-federated/@team-a/my-service/-/my-service-1.0.0.tgz"
```

**Expected**: HTTP 200 with package content ✅

### Visual Demo

```bash
# Terminal 1: Watch PRIMARY logs
tail -f $JFROG_HOME/var/log/artifactory/artifactory-service.log | grep -i federation

# Terminal 2: Publish package
npm publish

# Terminal 3: Check SECONDARY
watch -n 1 "curl -s ${SECONDARY_URL}/artifactory/api/storage/npm-federated/@team-a/my-service | jq '.'"
```

You'll see the package appear on the secondary instance within seconds!

## Common Issues

### Issue: "Federation not supported"
**Solution**: Upgrade to Pro or Enterprise license

### Issue: "Cannot connect to member"
**Solution**: Check firewall rules, ensure port 443 is open between instances

### Issue: "Replication lag > 30 seconds"
**Solution**: Check network bandwidth, review replication queue

## Next Steps

1. Read full documentation: `FEDERATED_REPOS_DEMO.md`
2. Set up monitoring for replication lag
3. Configure geographic routing for clients
4. Test failover scenarios
5. Implement cleanup policies

## Resources

- [JFrog Federation Docs](https://www.jfrog.com/confluence/display/JFROG/Federated+Repositories)
- [Multi-Site Architecture](https://www.jfrog.com/confluence/display/JFROG/Multi-site+Deployment)
- [Replication API](https://www.jfrog.com/confluence/display/JFROG/Artifactory+REST+API#ArtifactoryRESTAPI-Federation)
