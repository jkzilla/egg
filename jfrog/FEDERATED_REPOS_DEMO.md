# JFrog Federated Repositories Demo

## Overview

This demo showcases JFrog's **Federated Repositories** feature, which enables multi-site repository replication and synchronization across geographically distributed JFrog instances.

## What are Federated Repositories?

Federated repositories allow you to:
- **Replicate artifacts** across multiple JFrog instances in real-time
- **Distribute workloads** geographically for better performance
- **Enable disaster recovery** with automatic failover
- **Maintain consistency** across development sites worldwide
- **Reduce latency** by serving artifacts from the nearest location

## Architecture

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
│ San Francisco│      │  New York    │      │  London      │
└──────────────┘      └──────────────┘      └──────────────┘
```

## Use Cases

### 1. Global Development Teams
- **Scenario**: Teams in US, Europe, and Asia working on the same project
- **Benefit**: Each team pulls from their nearest instance, reducing latency
- **Example**: Frontend team in London, Backend team in San Francisco, QA in Singapore

### 2. Disaster Recovery
- **Scenario**: Primary datacenter goes down
- **Benefit**: Automatic failover to secondary instance
- **Example**: US-WEST fails → traffic routes to US-EAST

### 3. Compliance & Data Sovereignty
- **Scenario**: EU data must stay in EU, US data in US
- **Benefit**: Federated repos with regional restrictions
- **Example**: GDPR-compliant artifact storage

### 4. Build Performance
- **Scenario**: CI/CD pipelines in multiple regions
- **Benefit**: Faster builds by accessing local artifact cache
- **Example**: CircleCI in US-EAST, GitHub Actions in EU-WEST

## Setup Instructions

### Prerequisites

1. **Multiple JFrog Instances** (minimum 2)
   - Cloud instances: `instance1.jfrog.io`, `instance2.jfrog.io`
   - Or self-hosted instances in different regions

2. **Admin Access** to all instances

3. **Network Connectivity** between instances
   - Ports: 443 (HTTPS), 8081 (Artifactory)
   - Firewall rules allowing inter-instance communication

4. **JFrog Platform Pro/Enterprise License**
   - Federated repositories require Pro or Enterprise tier

### Step 1: Create Federated Repository on Primary Instance

```bash
# Set environment variables
export PRIMARY_URL="https://instance1.jfrog.io"
export PRIMARY_TOKEN="your-primary-token"

# Create federated repository
cd /Users/johanna/src/haileysgarden/egg/jfrog
./setup-federated-repos.sh
```

### Step 2: Configure Federation Members

```bash
# Add secondary instance as federation member
curl -X POST "${PRIMARY_URL}/artifactory/api/federation/npm-federated/member" \
  -H "Authorization: Bearer ${PRIMARY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://instance2.jfrog.io/artifactory/npm-federated",
    "enabled": true
  }'
```

### Step 3: Verify Federation Status

```bash
# Check federation status
curl -X GET "${PRIMARY_URL}/artifactory/api/federation/npm-federated" \
  -H "Authorization: Bearer ${PRIMARY_TOKEN}"
```

## Demo Scenarios

### Scenario 1: Publish Once, Available Everywhere

**Goal**: Publish a package to US-WEST, verify it's replicated to US-EAST and EU-WEST

```bash
# 1. Publish to US-WEST (primary)
cd /Users/johanna/src/haileysgarden/egg/packages/team-a-service
npm config set registry https://us-west.jfrog.io/artifactory/api/npm/npm-federated/
npm publish

# 2. Wait for replication (typically < 5 seconds)
sleep 5

# 3. Verify on US-EAST
curl -H "Authorization: Bearer ${US_EAST_TOKEN}" \
  https://us-east.jfrog.io/artifactory/npm-federated/@team-a/my-service/-/my-service-1.0.0.tgz

# 4. Verify on EU-WEST
curl -H "Authorization: Bearer ${EU_WEST_TOKEN}" \
  https://eu-west.jfrog.io/artifactory/npm-federated/@team-a/my-service/-/my-service-1.0.0.tgz
```

**Expected Result**: Package available on all instances ✅

### Scenario 2: Geographic Load Distribution

**Goal**: Show how clients automatically use nearest instance

```bash
# US developer (uses US-WEST)
export JFROG_URL="https://us-west.jfrog.io"
npm install @team-a/my-service
# Downloads from us-west.jfrog.io

# EU developer (uses EU-WEST)
export JFROG_URL="https://eu-west.jfrog.io"
npm install @team-a/my-service
# Downloads from eu-west.jfrog.io (replicated copy)
```

**Expected Result**: Same package, different sources, faster downloads ✅

### Scenario 3: Failover Testing

**Goal**: Demonstrate automatic failover when primary is unavailable

```bash
# 1. Configure npm with failover URLs
cat > ~/.npmrc << EOF
registry=https://us-west.jfrog.io/artifactory/api/npm/npm-federated/
@haileys-garden:registry=https://us-east.jfrog.io/artifactory/api/npm/npm-federated/
EOF

# 2. Simulate primary failure (disable us-west in /etc/hosts or firewall)
# sudo echo "127.0.0.1 us-west.jfrog.io" >> /etc/hosts

# 3. Try to install - should fail over to us-east
npm install @team-a/my-service
```

**Expected Result**: Installation succeeds using secondary instance ✅

### Scenario 4: Bi-directional Sync

**Goal**: Publish to secondary, verify it syncs back to primary

```bash
# 1. Publish to EU-WEST (secondary)
npm config set registry https://eu-west.jfrog.io/artifactory/api/npm/npm-federated/
cd /Users/johanna/src/haileysgarden/egg/packages/team-b-component
npm publish

# 2. Wait for replication
sleep 5

# 3. Verify on US-WEST (primary)
curl -H "Authorization: Bearer ${US_WEST_TOKEN}" \
  https://us-west.jfrog.io/artifactory/npm-federated/@team-b/my-component/-/my-component-1.0.0.tgz
```

**Expected Result**: Package published to secondary is available on primary ✅

## Configuration Files

### Federated Local Repository

File: `repositories/npm-federated-local.json`

```json
{
  "key": "npm-federated",
  "rclass": "federated",
  "packageType": "npm",
  "description": "Federated npm repository with multi-site replication",
  "repoLayoutRef": "npm-default",
  "members": [
    {
      "url": "https://us-west.jfrog.io/artifactory/npm-federated",
      "enabled": true
    },
    {
      "url": "https://us-east.jfrog.io/artifactory/npm-federated",
      "enabled": true
    },
    {
      "url": "https://eu-west.jfrog.io/artifactory/npm-federated",
      "enabled": true
    }
  ]
}
```

## Monitoring & Troubleshooting

### Check Replication Status

```bash
# Get replication statistics
curl -X GET "${PRIMARY_URL}/artifactory/api/federation/npm-federated/stats" \
  -H "Authorization: Bearer ${PRIMARY_TOKEN}"
```

### View Replication Logs

```bash
# Check Artifactory logs for federation events
tail -f $JFROG_HOME/var/log/artifactory/artifactory-service.log | grep -i federation
```

### Common Issues

#### Issue: Replication Lag
**Symptom**: Package not immediately available on secondary instances
**Solution**:
- Check network connectivity between instances
- Verify federation members are enabled
- Review replication queue: `GET /api/federation/{repo}/queue`

#### Issue: Authentication Failures
**Symptom**: 401/403 errors when accessing federated repo
**Solution**:
- Verify access tokens are valid on all instances
- Check user permissions on each instance
- Ensure federation service account has proper rights

#### Issue: Partial Replication
**Symptom**: Some artifacts replicate, others don't
**Solution**:
- Check include/exclude patterns
- Verify storage quotas on secondary instances
- Review federation event logs

## Performance Metrics

### Expected Replication Times

| Artifact Size | Replication Time | Network |
|--------------|------------------|---------|
| < 1 MB       | < 2 seconds      | 100 Mbps |
| 1-10 MB      | 2-5 seconds      | 100 Mbps |
| 10-100 MB    | 5-30 seconds     | 100 Mbps |
| > 100 MB     | 30+ seconds      | 100 Mbps |

### Latency Improvements

| Region | Without Federation | With Federation | Improvement |
|--------|-------------------|-----------------|-------------|
| US-WEST | 50ms | 50ms | Baseline |
| US-EAST | 150ms | 60ms | 60% faster |
| EU-WEST | 300ms | 70ms | 77% faster |
| APAC | 500ms | 80ms | 84% faster |

## Best Practices

### 1. Repository Design
- ✅ Use federated repos for frequently accessed artifacts
- ✅ Keep critical dependencies in federated repos
- ❌ Don't federate temporary/build artifacts
- ❌ Avoid federating very large files (> 1GB)

### 2. Network Configuration
- ✅ Use dedicated network links between instances
- ✅ Enable compression for replication traffic
- ✅ Configure QoS for federation traffic
- ❌ Don't route federation over public internet without VPN

### 3. Security
- ✅ Use mutual TLS between instances
- ✅ Rotate federation service account tokens regularly
- ✅ Enable audit logging for federation events
- ❌ Don't use same admin credentials across instances

### 4. Monitoring
- ✅ Set up alerts for replication lag
- ✅ Monitor storage usage on all instances
- ✅ Track federation event metrics
- ❌ Don't ignore replication errors

## Advanced Features

### Selective Replication

Replicate only specific paths:

```json
{
  "includesPattern": "@team-a/**,@shared/**",
  "excludesPattern": "*.tmp,*.log"
}
```

### Replication Priorities

Set priority for critical artifacts:

```json
{
  "replicationPriority": "high",
  "replicationBandwidth": "10MB"
}
```

### Conflict Resolution

Configure how conflicts are resolved:

```json
{
  "conflictResolution": "source-wins"
}
```

## Testing Checklist

- [ ] **Create federated repository** on primary instance
- [ ] **Add federation members** (secondary instances)
- [ ] **Publish artifact** to primary
- [ ] **Verify replication** to all members (< 10 seconds)
- [ ] **Install from secondary** instance
- [ ] **Publish to secondary** instance
- [ ] **Verify bi-directional sync** back to primary
- [ ] **Test failover** by disabling primary
- [ ] **Monitor replication lag** and performance
- [ ] **Check audit logs** for federation events

## Cost Considerations

### Storage Costs
- Each federated instance stores full copy of artifacts
- 3 instances = 3x storage costs
- Use cleanup policies to manage storage

### Network Costs
- Replication traffic between instances
- Consider data transfer costs between regions
- Use compression to reduce bandwidth

### License Costs
- Federated repositories require Pro/Enterprise license
- Each instance needs appropriate license tier

## Migration from Non-Federated

### Step 1: Backup Current Repository
```bash
jf rt export npm-dev-local /tmp/backup/
```

### Step 2: Create Federated Repository
```bash
./setup-federated-repos.sh
```

### Step 3: Migrate Artifacts
```bash
jf rt copy npm-dev-local npm-federated --flat=false
```

### Step 4: Update Client Configurations
```bash
npm config set registry https://instance.jfrog.io/artifactory/api/npm/npm-federated/
```

### Step 5: Verify and Decommission Old Repo
```bash
# Verify all artifacts migrated
jf rt search npm-federated

# Delete old repository (after verification)
jf rt repo-delete npm-dev-local
```

## Resources

- [JFrog Federated Repositories Documentation](https://www.jfrog.com/confluence/display/JFROG/Federated+Repositories)
- [Federation REST API](https://www.jfrog.com/confluence/display/JFROG/Artifactory+REST+API#ArtifactoryRESTAPI-Federation)
- [Multi-Site Deployment Guide](https://www.jfrog.com/confluence/display/JFROG/Multi-site+Deployment)

## Support

For issues with federated repositories:
1. Check JFrog Platform logs on all instances
2. Verify network connectivity between instances
3. Review federation event queue
4. Contact JFrog support with replication logs
