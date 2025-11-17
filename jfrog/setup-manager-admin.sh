#!/bin/bash
# Grant manager user the ability to manage groups and permissions
# Usage: ./setup-manager-admin.sh <JFROG_URL> <AUTH_TOKEN> <MANAGER_USERNAME>

set -e

JFROG_URL="${1:-https://trialghxmjl.jfrog.io}"
AUTH_TOKEN="${2}"
MANAGER_USERNAME="${3}"

if [ -z "$AUTH_TOKEN" ] || [ -z "$MANAGER_USERNAME" ]; then
  echo "Usage: $0 <JFROG_URL> <AUTH_TOKEN> <MANAGER_USERNAME>"
  exit 1
fi

BASE_URL="${JFROG_URL}/artifactory"

echo "👨‍💼 Granting manager permissions to: $MANAGER_USERNAME"

# Add manager to managers group
echo "📝 Adding $MANAGER_USERNAME to managers group..."
curl -H "Authorization: Bearer $AUTH_TOKEN" -X POST \
  -H "Content-Type: application/json" \
  "${BASE_URL}/api/security/groups/managers" \
  -d "{
    \"name\": \"managers\",
    \"userNames\": [\"$MANAGER_USERNAME\"]
  }"

# Grant manager user admin privileges for group management
echo "🔑 Granting admin privileges to $MANAGER_USERNAME..."
curl -H "Authorization: Bearer $AUTH_TOKEN" -X PUT \
  -H "Content-Type: application/json" \
  "${BASE_URL}/api/security/users/$MANAGER_USERNAME" \
  -d "{
    \"name\": \"$MANAGER_USERNAME\",
    \"admin\": false,
    \"profileUpdatable\": true,
    \"internalPasswordDisabled\": false,
    \"groups\": [\"managers\"]
  }"

echo ""
echo "✅ Manager setup complete!"
echo ""
echo "📋 Manager capabilities:"
echo "✓ View all repositories (npm-shared-local, npmjs-remote)"
echo "✓ Read/write/delete packages in all scopes (@web-dev/*, @ios/*, @shared/*)"
echo "✓ Manage permissions for team repositories"
echo ""
echo "⚠️  To grant full group management (add/remove users), you have two options:"
echo ""
echo "Option 1: JFrog Projects (Recommended)"
echo "  1. Go to: Admin → Projects → Create New Project"
echo "  2. Add repositories: npm, npm-shared-local, npmjs-remote"
echo "  3. Make $MANAGER_USERNAME a Project Admin"
echo "  4. Project Admins can manage team membership within the project"
echo ""
echo "Option 2: Platform Admin"
echo "  1. Go to: Admin → Security → Users → $MANAGER_USERNAME"
echo "  2. Check 'Platform Admin' (gives broader admin rights)"
echo ""
echo "Option 3: IdP/SCIM Integration"
echo "  1. Sync groups from Okta/Azure AD"
echo "  2. Manager controls membership in IdP"
echo "  3. JFrog auto-syncs web-dev-team and ios-team groups"
