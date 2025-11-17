# Federated Repositories Demo - Complete Guide

## What You'll Learn

This demo teaches you how to set up and use JFrog's **Federated Repositories** for multi-site artifact replication and global distribution.

## Demo Files

| File | Purpose |
|------|---------|
| `FEDERATED_REPOS_DEMO.md` | Complete documentation with architecture, use cases, and best practices |
| `FEDERATED_DEMO_QUICKSTART.md` | 5-minute quick start guide |
| `repositories/npm-federated-local.json` | Repository configuration file |
| `setup-federated-repos.sh` | Automated setup script |
| `federated-test-script.sh` | Automated testing script |

## Quick Start (5 Minutes)

### 1. Setup Primary Instance
```bash
export JFROG_URL="https://your-primary.jfrog.io"
export JFROG_TOKEN="your-token"

cd /Users/johanna/src/haileysgarden/egg/jfrog
./setup-federated-repos.sh
```

### 2. Setup Secondary Instance
```bash
export SECONDARY_JFROG_URL="https://your-secondary.jfrog.io"
export SECONDARY_JFROG_TOKEN="your-secondary-token"

# Create repository on secondary
curl -X PUT \
  -H "Authorization: Bearer ${SECONDARY_JFROG_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @repositories/npm-federated-local.json \
  "${SECONDARY_JFROG_URL}/artifactory/api/repositories/npm-federated"
```

### 3. Link Instances
```bash
# From primary, add secondary as federation member
curl -X POST \
  -H "Authorization: Bearer ${JFROG_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"url\": \"${SECONDARY_JFROG_URL}/artifactory/npm-federated\", \"enabled\": true}" \
  "${JFROG_URL}/artifactory/api/federation/npm-federated/member"
```

### 4. Test Replication
```bash
# Publish to primary
cd packages/team-a-service
npm config set registry ${JFROG_URL}/artifactory/api/npm/npm-federated/
npm publish

# Verify on secondary (wait 5 seconds)
sleep 5
curl -H "Authorization: Bearer ${SECONDARY_JFROG_TOKEN}" \
  "${SECONDARY_JFROG_URL}/artifactory/npm-federated/@team-a/my-service/-/my-service-1.0.0.tgz"
```

## Automated Testing

Run the complete test suite:

```bash
export PRIMARY_JFROG_URL="https://primary.jfrog.io"
export PRIMARY_JFROG_TOKEN="token1"
export SECONDARY_JFROG_URL="https://secondary.jfrog.io"
export SECONDARY_JFROG_TOKEN="token2"

./federated-test-script.sh
```

This will:
- ✅ Verify repositories exist on both instances
- ✅ Check federation configuration
- ✅ Publish test package to primary
- ✅ Verify replication to secondary
- ✅ Test bi-directional sync
- ✅ Clean up test artifacts

## Key Concepts

### Federated Repository
A repository type that automatically replicates artifacts across multiple JFrog instances in real-time.

### Federation Members
The JFrog instances participating in the federation. Each member maintains a full copy of artifacts.

### Replication
The process of synchronizing artifacts between federation members. Typically completes in < 5 seconds.

### Use Cases
1. **Global Teams** - Developers worldwide access artifacts from nearest instance
2. **Disaster Recovery** - Automatic failover if primary instance fails
3. **Performance** - Reduced latency by serving from local cache
4. **Compliance** - Keep data in specific geographic regions

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Federated Repository                      │
│                      npm-federated                           │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  US-WEST     │◄────►│   US-EAST    │◄────►│   EU-WEST    │
│  (Primary)   │      │  (Mirror)    │      │  (Mirror)    │
│              │      │              │      │              │
│ Developers:  │      │ Developers:  │      │ Developers:  │
│ - Team A     │      │ - Team B     │      │ - Team C     │
│ - CI/CD      │      │ - CI/CD      │      │ - CI/CD      │
└──────────────┘      └──────────────┘      └──────────────┘
      ↓                     ↓                     ↓
  50ms latency         60ms latency          70ms latency
  (local cache)        (local cache)         (local cache)

Without Federation: All teams → US-WEST → 150-500ms latency
With Federation: Each team → Local instance → 50-70ms latency
```

## Performance Benefits

| Metric | Without Federation | With Federation | Improvement |
|--------|-------------------|-----------------|-------------|
| US-WEST to US-WEST | 50ms | 50ms | Baseline |
| US-EAST to US-WEST | 150ms | 60ms | **60% faster** |
| EU-WEST to US-WEST | 300ms | 70ms | **77% faster** |
| APAC to US-WEST | 500ms | 80ms | **84% faster** |

## Requirements

### License
- JFrog Platform **Pro** or **Enterprise**
- Standard/Free tier does NOT support federation

### Infrastructure
- Minimum 2 JFrog instances (cloud or self-hosted)
- Network connectivity between instances (HTTPS/443)
- Sufficient storage on all instances

### Permissions
- Admin access to create repositories
- API access to configure federation
- Network firewall rules allowing inter-instance communication

## Common Scenarios

### Scenario 1: US + EU Development Teams
```
US Team (San Francisco) → us-west.jfrog.io
EU Team (London) → eu-west.jfrog.io

Both teams publish and consume from their local instance.
Artifacts automatically replicate between instances.
```

### Scenario 2: Disaster Recovery
```
Primary: us-west.jfrog.io (active)
Secondary: us-east.jfrog.io (standby)

If primary fails → clients failover to secondary
No data loss, minimal downtime
```

### Scenario 3: CI/CD Performance
```
CircleCI (US-EAST) → us-east.jfrog.io
GitHub Actions (EU-WEST) → eu-west.jfrog.io
Jenkins (US-WEST) → us-west.jfrog.io

Each CI system uses nearest instance for faster builds
```

## Troubleshooting

### Replication Not Working
1. Check federation status: `GET /api/federation/{repo}`
2. Verify network connectivity between instances
3. Review Artifactory logs for federation errors
4. Ensure same repository name on all instances

### Slow Replication
1. Check network bandwidth between instances
2. Review replication queue size
3. Consider artifact size (large files take longer)
4. Verify no firewall throttling

### Authentication Issues
1. Verify tokens are valid on all instances
2. Check user permissions on each instance
3. Ensure federation service account has proper rights

## Next Steps

1. ✅ Read `FEDERATED_REPOS_DEMO.md` for complete documentation
2. ✅ Try `FEDERATED_DEMO_QUICKSTART.md` for hands-on setup
3. ✅ Run `federated-test-script.sh` to verify configuration
4. ✅ Configure geographic routing for production
5. ✅ Set up monitoring and alerts for replication lag
6. ✅ Implement cleanup policies to manage storage

## Resources

- [JFrog Federation Documentation](https://www.jfrog.com/confluence/display/JFROG/Federated+Repositories)
- [Multi-Site Deployment Guide](https://www.jfrog.com/confluence/display/JFROG/Multi-site+Deployment)
- [Federation REST API](https://www.jfrog.com/confluence/display/JFROG/Artifactory+REST+API#ArtifactoryRESTAPI-Federation)
- [JFrog Support Portal](https://support.jfrog.com/)

## Support

For questions or issues:
1. Review the troubleshooting section above
2. Check JFrog Artifactory logs on all instances
3. Verify federation configuration via API
4. Contact JFrog support with replication logs
