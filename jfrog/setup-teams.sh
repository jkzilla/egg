#!/bin/bash
# Setup JFrog Artifactory for egg project with two teams
# Usage: ./setup-teams.sh <JFROG_URL> <AUTH_TOKEN>

set -e

JFROG_URL="${1:-https://trialghxmjl.jfrog.io}"
AUTH_TOKEN="${2}"

if [ -z "$AUTH_TOKEN" ]; then
  echo "Usage: $0 <JFROG_URL> <AUTH_TOKEN>"
  exit 1
fi

BASE_URL="${JFROG_URL}/artifactory"

echo "🚀 Setting up JFrog Artifactory for egg project with two teams..."

# 1. Create npm-shared-local repository
echo "📦 Creating npm-shared-local repository..."
curl -H "Authorization: Bearer $AUTH_TOKEN" -X PUT \
  -H "Content-Type: application/json" \
  "${BASE_URL}/api/repositories/npm-shared-local" \
  -d @repositories/npm-shared-local.json

# 2. Update npm virtual repository
echo "🔗 Updating npm virtual repository..."
curl -H "Authorization: Bearer $AUTH_TOKEN" -X POST \
  -H "Content-Type: application/json" \
  "${BASE_URL}/api/repositories/npm" \
  -d @repositories/npm-virtual.json

# 3. Create groups
echo "👥 Creating team-a group..."
curl -H "Authorization: Bearer $AUTH_TOKEN" -X PUT \
  -H "Content-Type: application/json" \
  "${BASE_URL}/api/security/groups/team-a" \
  -d @groups/team-a.json

echo "👥 Creating team-b group..."
curl -H "Authorization: Bearer $AUTH_TOKEN" -X PUT \
  -H "Content-Type: application/json" \
  "${BASE_URL}/api/security/groups/team-b" \
  -d @groups/team-b.json

echo "👥 Creating managers group..."
curl -H "Authorization: Bearer $AUTH_TOKEN" -X PUT \
  -H "Content-Type: application/json" \
  "${BASE_URL}/api/security/groups/managers" \
  -d @groups/managers.json

# 4. Create permission targets
echo "🔐 Creating team-a permission target..."
curl -H "Authorization: Bearer $AUTH_TOKEN" -X PUT \
  -H "Content-Type: application/json" \
  "${BASE_URL}/api/v2/security/permissions/perm-team-a" \
  -d @permissions/perm-team-a.json

echo "🔐 Creating team-b permission target..."
curl -H "Authorization: Bearer $AUTH_TOKEN" -X PUT \
  -H "Content-Type: application/json" \
  "${BASE_URL}/api/v2/security/permissions/perm-team-b" \
  -d @permissions/perm-team-b.json

echo "🔐 Creating manager permission target..."
curl -H "Authorization: Bearer $AUTH_TOKEN" -X PUT \
  -H "Content-Type: application/json" \
  "${BASE_URL}/api/v2/security/permissions/perm-manager" \
  -d @permissions/perm-manager.json

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Add users to egg project in JFrog UI:"
echo "   - Go to: https://trialghxmjl.jfrog.io/ui/admin/projects/members?projectKey=egg"
echo "   - Add Team A members to team-a group"
echo "   - Add Team B members to team-b group"
echo "   - Add managers to managers group"
echo "2. Grant manager admin permissions: ./setup-manager-admin.sh <JFROG_URL> <AUTH_TOKEN> <MANAGER_USERNAME>"
echo "3. Configure developer machines: npm config set registry ${BASE_URL}/api/npm/npm/"
echo "4. Publish packages with appropriate scopes:"
echo "   - Team A: @team-a/*"
echo "   - Team B: @team-b/*"
echo "   - Shared: @shared/*"
echo ""
echo "🌐 Single URL for everything: ${BASE_URL}/api/npm/npm/"
echo "👥 Two teams with isolated scopes and shared collaboration area"
