#!/bin/bash

# JFrog Federated Repositories Setup Script
# This script creates federated repositories for multi-site replication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}JFrog Federated Repositories Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check for required environment variables
if [ -z "$JFROG_URL" ]; then
    echo -e "${RED}Error: JFROG_URL environment variable is not set${NC}"
    echo "Usage: export JFROG_URL='https://your-instance.jfrog.io'"
    exit 1
fi

if [ -z "$JFROG_TOKEN" ]; then
    echo -e "${RED}Error: JFROG_TOKEN environment variable is not set${NC}"
    echo "Usage: export JFROG_TOKEN='your-access-token'"
    exit 1
fi

# Remove trailing slash from URL if present
JFROG_URL=${JFROG_URL%/}
ARTIFACTORY_URL="${JFROG_URL}/artifactory"

echo -e "${YELLOW}Using JFrog instance: ${JFROG_URL}${NC}"
echo ""

# Function to create repository
create_repository() {
    local repo_file=$1
    local repo_name=$(basename "$repo_file" .json)

    echo -e "${YELLOW}Creating federated repository: ${repo_name}${NC}"

    # Update the repository JSON with actual instance URL
    local temp_file=$(mktemp)
    sed "s|https://us-west.jfrog.io|${JFROG_URL}|g" "$repo_file" > "$temp_file"

    response=$(curl -s -w "\n%{http_code}" \
        -X PUT \
        -H "Authorization: Bearer ${JFROG_TOKEN}" \
        -H "Content-Type: application/json" \
        -d @"$temp_file" \
        "${ARTIFACTORY_URL}/api/repositories/${repo_name}")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    rm "$temp_file"

    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        echo -e "${GREEN}✓ Successfully created: ${repo_name}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create: ${repo_name}${NC}"
        echo -e "${RED}HTTP Status: ${http_code}${NC}"
        echo -e "${RED}Response: ${body}${NC}"
        return 1
    fi
}

# Function to add federation member
add_federation_member() {
    local repo_name=$1
    local member_url=$2

    echo -e "${YELLOW}Adding federation member: ${member_url}${NC}"

    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: Bearer ${JFROG_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"url\": \"${member_url}\", \"enabled\": true}" \
        "${ARTIFACTORY_URL}/api/federation/${repo_name}/member")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        echo -e "${GREEN}✓ Successfully added federation member${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Could not add federation member (may require manual configuration)${NC}"
        echo -e "${YELLOW}HTTP Status: ${http_code}${NC}"
        return 1
    fi
}

# Function to verify federation status
verify_federation() {
    local repo_name=$1

    echo -e "${YELLOW}Verifying federation status for: ${repo_name}${NC}"

    response=$(curl -s -w "\n%{http_code}" \
        -X GET \
        -H "Authorization: Bearer ${JFROG_TOKEN}" \
        "${ARTIFACTORY_URL}/api/federation/${repo_name}")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Federation is configured${NC}"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        return 0
    else
        echo -e "${YELLOW}⚠ Could not verify federation status${NC}"
        return 1
    fi
}

# Main execution
echo -e "${GREEN}Step 1: Creating Federated Repository${NC}"
echo "----------------------------------------"

# Create federated repository
if [ -f "repositories/npm-federated-local.json" ]; then
    create_repository "repositories/npm-federated-local.json"
else
    echo -e "${RED}Error: repositories/npm-federated-local.json not found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Step 2: Federation Member Configuration${NC}"
echo "----------------------------------------"
echo -e "${YELLOW}Note: Adding federation members requires:${NC}"
echo "  1. Multiple JFrog instances (Pro/Enterprise license)"
echo "  2. Network connectivity between instances"
echo "  3. Same repository name on all instances"
echo ""
echo -e "${YELLOW}To manually add federation members:${NC}"
echo "  1. Create the same repository on secondary instances"
echo "  2. Use the JFrog UI: Repositories → npm-federated → Federation"
echo "  3. Or use the API to add members"
echo ""

# Optional: Try to add federation members if secondary URLs are provided
if [ ! -z "$SECONDARY_JFROG_URL" ]; then
    echo -e "${YELLOW}Attempting to add secondary instance: ${SECONDARY_JFROG_URL}${NC}"
    add_federation_member "npm-federated" "${SECONDARY_JFROG_URL}/artifactory/npm-federated"
fi

echo ""
echo -e "${GREEN}Step 3: Verification${NC}"
echo "----------------------------------------"
verify_federation "npm-federated"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Configure secondary instances with the same repository"
echo "  2. Add federation members via UI or API"
echo "  3. Test replication by publishing a package"
echo "  4. Verify package appears on all federated instances"
echo ""
echo -e "${YELLOW}Usage Example:${NC}"
echo "  npm config set registry ${ARTIFACTORY_URL}/api/npm/npm-federated/"
echo "  npm publish"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo "  See FEDERATED_REPOS_DEMO.md for complete setup and testing guide"
echo ""
