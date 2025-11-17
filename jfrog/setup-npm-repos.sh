#!/bin/bash
set -e

# JFrog Artifactory NPM Repository Setup Script
# This script creates npm-dev-local, npmjs-remote, and npm (virtual) repositories

# Configuration
JFROG_URL="${JFROG_URL:-https://your-instance.jfrog.io/artifactory}"
JFROG_USER="${JFROG_USER}"
JFROG_TOKEN="${JFROG_TOKEN}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check required environment variables
if [ -z "$JFROG_TOKEN" ]; then
    echo -e "${RED}Error: JFROG_TOKEN environment variable is not set${NC}"
    echo "Please set it with: export JFROG_TOKEN='your-token'"
    exit 1
fi

if [ -z "$JFROG_USER" ]; then
    echo -e "${RED}Error: JFROG_USER environment variable is not set${NC}"
    echo "Please set it with: export JFROG_USER='your-username'"
    exit 1
fi

echo -e "${GREEN}Setting up NPM repositories in JFrog Artifactory...${NC}"
echo "JFrog URL: $JFROG_URL"

# Function to create repository
create_repo() {
    local repo_file=$1
    # Extract the key from the JSON file
    local repo_name=$(grep -o '"key"[[:space:]]*:[[:space:]]*"[^"]*"' "$repo_file" | sed 's/.*"\([^"]*\)".*/\1/')

    echo -e "${YELLOW}Creating repository: $repo_name${NC}"

    response=$(curl -s -w "\n%{http_code}" -u "${JFROG_USER}:${JFROG_TOKEN}" \
        -X PUT \
        -H "Content-Type: application/json" \
        -d @"$repo_file" \
        "${JFROG_URL}/api/repositories/${repo_name}")

    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        echo -e "${GREEN}✓ Successfully created $repo_name${NC}"
    elif [ "$http_code" -eq 400 ] && echo "$body" | grep -q "already exists"; then
        echo -e "${YELLOW}⚠ Repository $repo_name already exists${NC}"
    else
        echo -e "${RED}✗ Failed to create $repo_name (HTTP $http_code)${NC}"
        echo "$body"
        return 1
    fi
}

# Create repositories in order
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "Step 1: Creating local repository..."
create_repo "$SCRIPT_DIR/repositories/npm-dev-local.json"

echo ""
echo "Step 2: Creating remote repository..."
create_repo "$SCRIPT_DIR/repositories/npmjs-remote.json"

echo ""
echo "Step 3: Creating virtual repository..."
create_repo "$SCRIPT_DIR/repositories/npm-virtual.json"

echo ""
echo -e "${GREEN}✓ NPM repository setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Configure your .npmrc file:"
echo "   npm config set registry ${JFROG_URL}/api/npm/npm/"
echo "   npm config set //your-instance.jfrog.io/artifactory/api/npm/npm/:_auth=\$(echo -n 'username:token' | base64)"
echo ""
echo "2. Or use the provided .npmrc template in jfrog/.npmrc.template"
echo ""
echo "3. Test the setup:"
echo "   npm install --registry ${JFROG_URL}/api/npm/npm/"
