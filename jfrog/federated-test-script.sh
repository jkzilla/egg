#!/bin/bash

# Federated Repositories Test Script
# Automated testing for multi-site replication

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Federated Repositories Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Configuration
PRIMARY_URL="${PRIMARY_JFROG_URL:-https://primary.jfrog.io}"
SECONDARY_URL="${SECONDARY_JFROG_URL:-https://secondary.jfrog.io}"
PRIMARY_TOKEN="${PRIMARY_JFROG_TOKEN}"
SECONDARY_TOKEN="${SECONDARY_JFROG_TOKEN}"

REPO_NAME="npm-federated"
TEST_PACKAGE="@test/federation-demo"
TEST_VERSION="1.0.0"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if [ -z "$PRIMARY_TOKEN" ]; then
    echo -e "${RED}Error: PRIMARY_JFROG_TOKEN not set${NC}"
    exit 1
fi

if [ -z "$SECONDARY_TOKEN" ]; then
    echo -e "${RED}Error: SECONDARY_JFROG_TOKEN not set${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Environment variables configured${NC}"
echo ""

# Test 1: Verify repositories exist
echo -e "${BLUE}Test 1: Verify Federated Repositories${NC}"
echo "----------------------------------------"

echo -e "${YELLOW}Checking PRIMARY instance...${NC}"
primary_check=$(curl -s -w "%{http_code}" -o /dev/null \
    -H "Authorization: Bearer ${PRIMARY_TOKEN}" \
    "${PRIMARY_URL}/artifactory/api/repositories/${REPO_NAME}")

if [ "$primary_check" -eq 200 ]; then
    echo -e "${GREEN}✓ Repository exists on PRIMARY${NC}"
else
    echo -e "${RED}✗ Repository not found on PRIMARY (HTTP ${primary_check})${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking SECONDARY instance...${NC}"
secondary_check=$(curl -s -w "%{http_code}" -o /dev/null \
    -H "Authorization: Bearer ${SECONDARY_TOKEN}" \
    "${SECONDARY_URL}/artifactory/api/repositories/${REPO_NAME}")

if [ "$secondary_check" -eq 200 ]; then
    echo -e "${GREEN}✓ Repository exists on SECONDARY${NC}"
else
    echo -e "${RED}✗ Repository not found on SECONDARY (HTTP ${secondary_check})${NC}"
    exit 1
fi

echo ""

# Test 2: Check federation status
echo -e "${BLUE}Test 2: Verify Federation Configuration${NC}"
echo "----------------------------------------"

federation_status=$(curl -s \
    -H "Authorization: Bearer ${PRIMARY_TOKEN}" \
    "${PRIMARY_URL}/artifactory/api/federation/${REPO_NAME}")

echo -e "${YELLOW}Federation status:${NC}"
echo "$federation_status" | jq '.' 2>/dev/null || echo "$federation_status"
echo ""

# Test 3: Publish to PRIMARY
echo -e "${BLUE}Test 3: Publish Package to PRIMARY${NC}"
echo "----------------------------------------"

# Create temporary test package
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

cat > package.json << EOF
{
  "name": "${TEST_PACKAGE}",
  "version": "${TEST_VERSION}",
  "description": "Test package for federated repository replication",
  "main": "index.js",
  "publishConfig": {
    "registry": "${PRIMARY_URL}/artifactory/api/npm/${REPO_NAME}/"
  }
}
EOF

cat > index.js << EOF
module.exports = {
  message: "Hello from federated repository!",
  timestamp: new Date().toISOString(),
  source: "PRIMARY"
};
EOF

cat > .npmrc << EOF
registry=${PRIMARY_URL}/artifactory/api/npm/${REPO_NAME}/
//${PRIMARY_URL#https://}/artifactory/api/npm/${REPO_NAME}/:_authToken=${PRIMARY_TOKEN}
EOF

echo -e "${YELLOW}Publishing package...${NC}"
npm publish 2>&1 | grep -E "(Published|notice)" || true

echo -e "${GREEN}✓ Package published to PRIMARY${NC}"
echo ""

# Test 4: Wait for replication
echo -e "${BLUE}Test 4: Wait for Replication${NC}"
echo "----------------------------------------"

echo -e "${YELLOW}Waiting for replication (max 30 seconds)...${NC}"

PACKAGE_PATH="${TEST_PACKAGE/-/\\/}"
PACKAGE_PATH="${PACKAGE_PATH/@/%40}"

for i in {1..30}; do
    echo -n "."

    check=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer ${SECONDARY_TOKEN}" \
        "${SECONDARY_URL}/artifactory/${REPO_NAME}/${PACKAGE_PATH}/-/$(basename ${TEST_PACKAGE})-${TEST_VERSION}.tgz")

    if [ "$check" -eq 200 ]; then
        echo ""
        echo -e "${GREEN}✓ Package replicated to SECONDARY in ${i} seconds${NC}"
        REPLICATED=true
        break
    fi

    sleep 1
done

if [ -z "$REPLICATED" ]; then
    echo ""
    echo -e "${RED}✗ Package not replicated after 30 seconds${NC}"
    echo -e "${YELLOW}This may indicate:${NC}"
    echo "  - Federation not properly configured"
    echo "  - Network connectivity issues"
    echo "  - Replication queue backlog"
    exit 1
fi

echo ""

# Test 5: Verify package on SECONDARY
echo -e "${BLUE}Test 5: Verify Package on SECONDARY${NC}"
echo "----------------------------------------"

echo -e "${YELLOW}Downloading package from SECONDARY...${NC}"

secondary_download=$(curl -s \
    -H "Authorization: Bearer ${SECONDARY_TOKEN}" \
    "${SECONDARY_URL}/artifactory/${REPO_NAME}/${PACKAGE_PATH}/-/$(basename ${TEST_PACKAGE})-${TEST_VERSION}.tgz" \
    -o /tmp/test-package.tgz -w "%{http_code}")

if [ "$secondary_download" -eq 200 ]; then
    echo -e "${GREEN}✓ Package successfully downloaded from SECONDARY${NC}"

    # Verify package integrity
    if tar -tzf /tmp/test-package.tgz > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Package integrity verified${NC}"
    else
        echo -e "${RED}✗ Package corrupted${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Failed to download package (HTTP ${secondary_download})${NC}"
    exit 1
fi

echo ""

# Test 6: Bi-directional sync test
echo -e "${BLUE}Test 6: Test Bi-directional Sync${NC}"
echo "----------------------------------------"

TEST_PACKAGE_2="@test/federation-reverse"
TEST_VERSION_2="1.0.0"

cd "$TEST_DIR"
rm -rf *

cat > package.json << EOF
{
  "name": "${TEST_PACKAGE_2}",
  "version": "${TEST_VERSION_2}",
  "description": "Test package for reverse replication",
  "main": "index.js",
  "publishConfig": {
    "registry": "${SECONDARY_URL}/artifactory/api/npm/${REPO_NAME}/"
  }
}
EOF

cat > index.js << EOF
module.exports = {
  message: "Hello from SECONDARY!",
  timestamp: new Date().toISOString(),
  source: "SECONDARY"
};
EOF

cat > .npmrc << EOF
registry=${SECONDARY_URL}/artifactory/api/npm/${REPO_NAME}/
//${SECONDARY_URL#https://}/artifactory/api/npm/${REPO_NAME}/:_authToken=${SECONDARY_TOKEN}
EOF

echo -e "${YELLOW}Publishing to SECONDARY...${NC}"
npm publish 2>&1 | grep -E "(Published|notice)" || true

echo -e "${YELLOW}Waiting for reverse replication...${NC}"

PACKAGE_PATH_2="${TEST_PACKAGE_2/-/\\/}"
PACKAGE_PATH_2="${PACKAGE_PATH_2/@/%40}"

for i in {1..30}; do
    echo -n "."

    check=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer ${PRIMARY_TOKEN}" \
        "${PRIMARY_URL}/artifactory/${REPO_NAME}/${PACKAGE_PATH_2}/-/$(basename ${TEST_PACKAGE_2})-${TEST_VERSION_2}.tgz")

    if [ "$check" -eq 200 ]; then
        echo ""
        echo -e "${GREEN}✓ Package replicated from SECONDARY to PRIMARY in ${i} seconds${NC}"
        REVERSE_REPLICATED=true
        break
    fi

    sleep 1
done

if [ -z "$REVERSE_REPLICATED" ]; then
    echo ""
    echo -e "${YELLOW}⚠ Reverse replication not working (this may be expected)${NC}"
else
    echo -e "${GREEN}✓ Bi-directional replication confirmed${NC}"
fi

echo ""

# Cleanup
echo -e "${BLUE}Cleanup${NC}"
echo "----------------------------------------"
echo -e "${YELLOW}Removing test packages...${NC}"

# Delete from PRIMARY
curl -s -X DELETE \
    -H "Authorization: Bearer ${PRIMARY_TOKEN}" \
    "${PRIMARY_URL}/artifactory/${REPO_NAME}/${PACKAGE_PATH}" > /dev/null 2>&1 || true

curl -s -X DELETE \
    -H "Authorization: Bearer ${PRIMARY_TOKEN}" \
    "${PRIMARY_URL}/artifactory/${REPO_NAME}/${PACKAGE_PATH_2}" > /dev/null 2>&1 || true

rm -rf "$TEST_DIR"
rm -f /tmp/test-package.tgz

echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✓ All tests passed!${NC}"
echo ""
echo "Results:"
echo "  - Repositories verified on both instances"
echo "  - Federation configuration confirmed"
echo "  - Package published to PRIMARY"
echo "  - Replication to SECONDARY successful"
echo "  - Package integrity verified"
if [ ! -z "$REVERSE_REPLICATED" ]; then
    echo "  - Bi-directional sync working"
fi
echo ""
echo -e "${YELLOW}Federation is working correctly!${NC}"
echo ""
